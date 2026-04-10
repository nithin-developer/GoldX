import { toast } from 'react-hot-toast';
import { useMemo, useState, type ChangeEvent } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import {
  Alert,
  Box,
  Button,
  Card,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TablePagination,
  TableRow,
  TextField,
  Typography,
  CircularProgress,
} from '@mui/material';

import { DashboardContent } from 'src/layouts/dashboard';
import { getApiErrorMessage } from 'src/services/auth.service';
import {
  verificationService,
  type VerificationItem,
  type VerificationStatus,
} from 'src/services/verification.service';

import { ConfirmDialog } from 'src/components/confirm-dialog';

// ----------------------------------------------------------------------

type StatusFilter = VerificationStatus | 'all';

const statusColorMap: Record<
  VerificationStatus,
  'default' | 'success' | 'error' | 'warning'
> = {
  not_submitted: 'default',
  pending: 'warning',
  approved: 'success',
  rejected: 'error',
};

function formatDate(value?: string | null) {
  if (!value) {
    return '--';
  }

  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return '--';
  }

  return parsed.toLocaleString();
}

function normalizeStatusLabel(value: VerificationStatus) {
  return value
    .split('_')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}

function isPdfUrl(url: string) {
  return url.toLowerCase().includes('.pdf');
}

function DocumentPreview({ title, url }: { title: string; url?: string | null }) {
  if (!url) {
    return (
      <Stack spacing={0.5}>
        <Typography variant="subtitle2">{title}</Typography>
        <Typography variant="body2" color="text.secondary">
          Not uploaded
        </Typography>
      </Stack>
    );
  }

  if (isPdfUrl(url)) {
    return (
      <Stack spacing={0.75}>
        <Typography variant="subtitle2">{title}</Typography>
        <Button href={url} target="_blank" rel="noreferrer" variant="outlined" size="small">
          Open PDF
        </Button>
      </Stack>
    );
  }

  return (
    <Stack spacing={0.75}>
      <Typography variant="subtitle2">{title}</Typography>
      <Box
        component="img"
        src={url}
        alt={title}
        sx={{
          width: '100%',
          maxHeight: 280,
          objectFit: 'contain',
          borderRadius: 1,
          border: (theme) => `1px solid ${theme.palette.divider}`,
          backgroundColor: 'background.paper',
        }}
      />
      <Button href={url} target="_blank" rel="noreferrer" size="small">
        Open Full Size
      </Button>
    </Stack>
  );
}

export function VerificationsView() {
  const queryClient = useQueryClient();

  const [statusFilter, setStatusFilter] = useState<StatusFilter>('pending');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [selectedVerification, setSelectedVerification] =
    useState<VerificationItem | null>(null);
  const [actionType, setActionType] = useState<'approve' | 'reject' | null>(
    null
  );
  const [rejectionReason, setRejectionReason] = useState('');

  const { data, isError, isLoading } = useQuery({
    queryKey: ['admin-verifications', statusFilter, page, rowsPerPage],
    queryFn: () =>
      verificationService.getVerifications({
        status: statusFilter,
        skip: page * rowsPerPage,
        limit: rowsPerPage,
      }),
  });

  const verifications = useMemo(() => data?.items ?? [], [data]);
  const total = data?.total ?? 0;

  const approveMutation = useMutation({
    mutationFn: (userId: number) => verificationService.approveVerification(userId),
    onSuccess: () => {
      toast.success('Verification approved successfully');
      setActionType(null);
      setSelectedVerification(null);
      setRejectionReason('');
      queryClient.invalidateQueries({ queryKey: ['admin-verifications'] });
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
    onError: (error) => {
      toast.error(getApiErrorMessage(error, 'Failed to approve verification'));
    },
  });

  const rejectMutation = useMutation({
    mutationFn: (payload: { userId: number; reason: string }) =>
      verificationService.rejectVerification(payload.userId, payload.reason),
    onSuccess: () => {
      toast.success('Verification rejected successfully');
      setActionType(null);
      setSelectedVerification(null);
      setRejectionReason('');
      queryClient.invalidateQueries({ queryKey: ['admin-verifications'] });
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
    onError: (error) => {
      toast.error(getApiErrorMessage(error, 'Failed to reject verification'));
    },
  });

  const isPendingAction = approveMutation.isPending || rejectMutation.isPending;

  const handleChangePage = (_event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event: ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const closeDetailsModal = () => {
    setSelectedVerification(null);
    setRejectionReason('');
    setActionType(null);
  };

  return (
    <DashboardContent>
      <Stack
        direction={{ xs: 'column', sm: 'row' }}
        alignItems={{ xs: 'stretch', sm: 'center' }}
        justifyContent="space-between"
        spacing={2}
        sx={{ mb: 3 }}
      >
        <Typography variant="h4">Verifications</Typography>

        <FormControl sx={{ minWidth: 200 }}>
          <InputLabel id="verification-status-filter">Status</InputLabel>
          <Select
            labelId="verification-status-filter"
            label="Status"
            value={statusFilter}
            onChange={(event) => {
              setStatusFilter(event.target.value as StatusFilter);
              setPage(0);
            }}
          >
            <MenuItem value="pending">Pending</MenuItem>
            <MenuItem value="approved">Approved</MenuItem>
            <MenuItem value="rejected">Rejected</MenuItem>
            <MenuItem value="not_submitted">Not Submitted</MenuItem>
            <MenuItem value="all">All</MenuItem>
          </Select>
        </FormControl>
      </Stack>

      {isError && <Alert severity="error">Unable to load verification requests.</Alert>}

      <Card>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>User ID</TableCell>
                <TableCell>Email</TableCell>
                <TableCell>Name</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Submitted At</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading && (
                <TableRow>
                  <TableCell colSpan={6} align="center">
                    <CircularProgress size={24} />
                  </TableCell>
                </TableRow>
              )}

              {!isLoading && verifications.length === 0 && (
                <TableRow>
                  <TableCell colSpan={6} align="center">
                    No verification requests found.
                  </TableCell>
                </TableRow>
              )}

              {verifications.map((verification) => (
                <TableRow key={verification.verification_id} hover>
                  <TableCell>{verification.user_id}</TableCell>
                  <TableCell>{verification.user_email}</TableCell>
                  <TableCell>{verification.user_full_name || '--'}</TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      label={normalizeStatusLabel(verification.status)}
                      color={statusColorMap[verification.status] ?? 'default'}
                    />
                  </TableCell>
                  <TableCell>{formatDate(verification.submitted_at)}</TableCell>
                  <TableCell align="right">
                    <Button
                      size="small"
                      variant="outlined"
                      onClick={() => setSelectedVerification(verification)}
                    >
                      View
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>

        <TablePagination
          component="div"
          page={page}
          count={total}
          rowsPerPage={rowsPerPage}
          onPageChange={handleChangePage}
          rowsPerPageOptions={[5, 10, 25]}
          onRowsPerPageChange={handleChangeRowsPerPage}
        />
      </Card>

      <Dialog
        open={Boolean(selectedVerification)}
        onClose={closeDetailsModal}
        fullWidth
        maxWidth="md"
      >
        <DialogTitle>Verification Details</DialogTitle>
        <DialogContent>
          {selectedVerification && (
            <Stack spacing={2} sx={{ mt: 1 }}>
              <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
                <Typography variant="body2">
                  <strong>User ID:</strong> {selectedVerification.user_id}
                </Typography>
                <Typography variant="body2">
                  <strong>Email:</strong> {selectedVerification.user_email}
                </Typography>
                <Typography variant="body2">
                  <strong>Status:</strong>{' '}
                  {normalizeStatusLabel(selectedVerification.status)}
                </Typography>
              </Stack>

              <Typography variant="body2">
                <strong>Submitted At:</strong>{' '}
                {formatDate(selectedVerification.submitted_at)}
              </Typography>

              {selectedVerification.rejection_reason && (
                <Alert severity="error">
                  Rejection Reason: {selectedVerification.rejection_reason}
                </Alert>
              )}

              <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
                <Box sx={{ flex: 1 }}>
                  <DocumentPreview
                    title="ID Document"
                    url={selectedVerification.id_document_url}
                  />
                </Box>
                <Box sx={{ flex: 1 }}>
                  <DocumentPreview
                    title="Selfie / User Picture"
                    url={
                      selectedVerification.selfie_document_url ??
                      selectedVerification.address_document_url
                    }
                  />
                </Box>
              </Stack>

              {selectedVerification.status === 'pending' && (
                <TextField
                  label="Rejection Reason"
                  value={rejectionReason}
                  onChange={(event) => setRejectionReason(event.target.value)}
                  multiline
                  minRows={3}
                  placeholder="Required when rejecting"
                />
              )}
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={closeDetailsModal}>Close</Button>
          {selectedVerification?.status === 'pending' && (
            <>
              <Button
                color="error"
                variant="outlined"
                disabled={isPendingAction}
                onClick={() => setActionType('reject')}
              >
                {rejectMutation.isPending ? 'Rejecting...' : 'Reject'}
              </Button>
              <Button
                color="success"
                variant="contained"
                disabled={isPendingAction}
                onClick={() => setActionType('approve')}
              >
                {approveMutation.isPending ? 'Approving...' : 'Approve'}
              </Button>
            </>
          )}
        </DialogActions>
      </Dialog>

      <ConfirmDialog
        open={actionType !== null && selectedVerification !== null}
        onClose={() => setActionType(null)}
        onConfirm={() => {
          if (!selectedVerification || !actionType) {
            return;
          }

          if (actionType === 'approve') {
            approveMutation.mutate(selectedVerification.user_id);
            return;
          }

          const normalizedReason = rejectionReason.trim();
          if (!normalizedReason) {
            toast.error('Rejection reason is required');
            return;
          }

          rejectMutation.mutate({
            userId: selectedVerification.user_id,
            reason: normalizedReason,
          });
        }}
        title={actionType === 'approve' ? 'Approve Verification' : 'Reject Verification'}
        content={
          actionType === 'approve'
            ? 'Approve this verification and unlock user dashboard access?'
            : 'Reject this verification request? User can resubmit with corrected documents.'
        }
        confirmText={actionType === 'approve' ? 'Approve' : 'Reject'}
        confirmColor={actionType === 'approve' ? 'success' : 'error'}
        isPending={isPendingAction}
      />
    </DashboardContent>
  );
}
