import { toast } from 'react-hot-toast';
import { useMemo, useState, type ChangeEvent } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import {
  Box,
  Card,
  Chip,
  Stack,
  Table,
  Alert,
  Button,
  Dialog,
  Select,
  TableRow,
  MenuItem,
  TableBody,
  TableCell,
  TableHead,
  TextField,
  Typography,
  InputLabel,
  FormControl,
  DialogTitle,
  DialogContent,
  DialogActions,
  TableContainer,
  TablePagination,
  CircularProgress,
} from '@mui/material';

import { DashboardContent } from 'src/layouts/dashboard';
import {
  type AdminDeposit,
  walletAdminService,
} from 'src/services/wallet-admin.service';

import { ConfirmDialog } from 'src/components/confirm-dialog';

// ----------------------------------------------------------------------

type StatusFilter = 'all' | 'pending' | 'approved' | 'rejected';

const statusColorMap: Record<string, 'default' | 'success' | 'error' | 'warning'> = {
  pending: 'warning',
  approved: 'success',
  rejected: 'error',
};

function formatAmount(value: number | string) {
  const numeric = Number(value);
  if (Number.isNaN(numeric)) {
    return String(value);
  }

  return numeric.toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}

function formatDate(value: string) {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return '--';
  }

  return parsed.toLocaleString();
}

export function DepositsView() {
  const queryClient = useQueryClient();

  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [selectedDeposit, setSelectedDeposit] = useState<AdminDeposit | null>(null);
  const [adminNote, setAdminNote] = useState('');
  const [actionType, setActionType] = useState<'approve' | 'reject' | null>(null);

  const { data, isLoading, isError } = useQuery({
    queryKey: ['admin-deposits', statusFilter, page, rowsPerPage],
    queryFn: () =>
      walletAdminService.getDeposits({
        status: statusFilter,
        skip: page * rowsPerPage,
        limit: rowsPerPage,
      }),
  });

  const deposits = useMemo(() => data?.items ?? [], [data]);
  const totalDeposits = data?.total ?? 0;

  const approveMutation = useMutation({
    mutationFn: (payload: { id: string; note?: string }) =>
      walletAdminService.approveDeposit(payload.id, payload.note),
    onSuccess: () => {
      toast.success('Deposit approved');
      setAdminNote('');
      queryClient.invalidateQueries({ queryKey: ['admin-deposits'] });
      setSelectedDeposit(null);
    },
    onError: () => toast.error('Failed to approve deposit'),
  });

  const rejectMutation = useMutation({
    mutationFn: (payload: { id: string; note?: string }) =>
      walletAdminService.rejectDeposit(payload.id, payload.note),
    onSuccess: () => {
      toast.success('Deposit rejected');
      setAdminNote('');
      queryClient.invalidateQueries({ queryKey: ['admin-deposits'] });
      setSelectedDeposit(null);
    },
    onError: () => toast.error('Failed to reject deposit'),
  });

  const onCloseModal = () => {
    setSelectedDeposit(null);
    setAdminNote('');
  };

  const isPendingAction = approveMutation.isPending || rejectMutation.isPending;
  const canTakeAction = selectedDeposit?.status?.toLowerCase() === 'pending';

  const handleChangePage = (_event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event: ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
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
        <Typography variant="h4">Deposits</Typography>

        <FormControl sx={{ minWidth: 180 }}>
          <InputLabel id="deposit-status-filter">Status</InputLabel>
          <Select
            labelId="deposit-status-filter"
            label="Status"
            value={statusFilter}
            onChange={(event) => {
              setStatusFilter(event.target.value as StatusFilter);
              setPage(0);
            }}
          >
            <MenuItem value="all">All</MenuItem>
            <MenuItem value="pending">Pending</MenuItem>
            <MenuItem value="approved">Approved</MenuItem>
            <MenuItem value="rejected">Rejected</MenuItem>
          </Select>
        </FormControl>
      </Stack>

      {isError && <Alert severity="error">Unable to load deposit requests.</Alert>}

      <Card>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>ID</TableCell>
                <TableCell>User ID</TableCell>
                <TableCell>Amount</TableCell>
                <TableCell>Transaction Ref</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Created At</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading && (
                <TableRow>
                  <TableCell colSpan={7} align="center">
                    <CircularProgress size={24} />
                  </TableCell>
                </TableRow>
              )}

              {!isLoading && deposits.length === 0 && (
                <TableRow>
                  <TableCell colSpan={7} align="center">
                    No deposit requests found.
                  </TableCell>
                </TableRow>
              )}

              {deposits.map((deposit) => {
                const status = deposit.status?.toLowerCase();
                return (
                  <TableRow key={deposit.id} hover>
                    <TableCell>{deposit.id}</TableCell>
                    <TableCell>{deposit.user_id}</TableCell>
                    <TableCell>${formatAmount(deposit.amount)}</TableCell>
                    <TableCell>{deposit.transaction_ref || '--'}</TableCell>
                    <TableCell>
                      <Chip
                        size="small"
                        label={deposit.status}
                        color={statusColorMap[status] ?? 'default'}
                      />
                    </TableCell>
                    <TableCell>{formatDate(deposit.created_at)}</TableCell>
                    <TableCell align="right">
                      <Button size="small" variant="outlined" onClick={() => setSelectedDeposit(deposit)}>
                        View
                      </Button>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </TableContainer>

        <TablePagination
          component="div"
          page={page}
          count={totalDeposits}
          rowsPerPage={rowsPerPage}
          onPageChange={handleChangePage}
          rowsPerPageOptions={[5, 10, 25]}
          onRowsPerPageChange={handleChangeRowsPerPage}
        />
      </Card>

      <Dialog open={Boolean(selectedDeposit)} onClose={onCloseModal} fullWidth maxWidth="sm">
        <DialogTitle>Deposit Request Details</DialogTitle>
        <DialogContent>
          {selectedDeposit && (
            <Stack spacing={1.5} sx={{ mt: 1 }}>
              <Typography variant="body2">Request ID: {selectedDeposit.id}</Typography>
              <Typography variant="body2">User ID: {selectedDeposit.user_id}</Typography>
              <Typography variant="body2">Amount: ${formatAmount(selectedDeposit.amount)}</Typography>
              <Typography variant="body2">
                Transaction Ref: {selectedDeposit.transaction_ref || '--'}
              </Typography>
              <Typography variant="body2">Status: {selectedDeposit.status}</Typography>
              <Typography variant="body2">Created At: {formatDate(selectedDeposit.created_at)}</Typography>
              <Typography variant="body2">
                Previous Admin Note: {selectedDeposit.admin_note || '--'}
              </Typography>

              {selectedDeposit.payment_proof_url ? (
                <Box
                  component="img"
                  src={selectedDeposit.payment_proof_url}
                  alt="Payment proof"
                  sx={{
                    width: '100%',
                    maxHeight: 280,
                    objectFit: 'contain',
                    borderRadius: 1,
                    border: (theme) => `1px solid ${theme.palette.divider}`,
                    backgroundColor: 'background.paper',
                  }}
                />
              ) : (
                <Typography variant="body2" color="text.secondary">
                  Payment proof: not uploaded
                </Typography>
              )}

              <TextField
                label="Admin Note"
                multiline
                minRows={3}
                value={adminNote}
                onChange={(event) => setAdminNote(event.target.value)}
                placeholder="Optional note for approve/reject"
                disabled={!canTakeAction}
              />
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={onCloseModal}>Close</Button>
          {canTakeAction && selectedDeposit && (
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
        open={actionType !== null && selectedDeposit !== null}
        onClose={() => setActionType(null)}
        onConfirm={() => {
          if (selectedDeposit && actionType) {
            if (actionType === 'approve') {
              approveMutation.mutate({
                id: selectedDeposit.id,
                note: adminNote.trim() || undefined,
              });
            } else {
              rejectMutation.mutate({
                id: selectedDeposit.id,
                note: adminNote.trim() || undefined,
              });
            }
            setActionType(null);
          }
        }}
        title={actionType === 'approve' ? 'Approve Deposit' : 'Reject Deposit'}
        content={
          actionType === 'approve'
            ? 'Are you sure you want to approve this deposit? The funds will be added to the user\'s account.'
            : 'Are you sure you want to reject this deposit? The user will be notified of the rejection.'
        }
        confirmText={actionType === 'approve' ? 'Approve Deposit' : 'Reject Deposit'}
        confirmColor={actionType === 'approve' ? 'success' : 'error'}
        isPending={isPendingAction}
      />
    </DashboardContent>
  );
}
