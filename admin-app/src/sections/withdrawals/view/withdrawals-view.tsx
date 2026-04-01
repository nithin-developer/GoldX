import { toast } from 'react-hot-toast';
import { useMemo, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import {
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
  CircularProgress,
} from '@mui/material';

import { DashboardContent } from 'src/layouts/dashboard';
import {
  walletAdminService,
  type AdminWithdrawal,
} from 'src/services/wallet-admin.service';

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

export function WithdrawalsView() {
  const queryClient = useQueryClient();

  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [selectedWithdrawal, setSelectedWithdrawal] = useState<AdminWithdrawal | null>(null);
  const [adminNote, setAdminNote] = useState('');

  const { data, isLoading, isError } = useQuery({
    queryKey: ['admin-withdrawals', statusFilter],
    queryFn: () => walletAdminService.getWithdrawals(statusFilter),
  });

  const withdrawals = useMemo(() => data ?? [], [data]);

  const approveMutation = useMutation({
    mutationFn: (payload: { id: string; note?: string }) =>
      walletAdminService.approveWithdrawal(payload.id, payload.note),
    onSuccess: () => {
      toast.success('Withdrawal approved');
      setAdminNote('');
      queryClient.invalidateQueries({ queryKey: ['admin-withdrawals'] });
      setSelectedWithdrawal(null);
    },
    onError: () => toast.error('Failed to approve withdrawal'),
  });

  const rejectMutation = useMutation({
    mutationFn: (payload: { id: string; note?: string }) =>
      walletAdminService.rejectWithdrawal(payload.id, payload.note),
    onSuccess: () => {
      toast.success('Withdrawal rejected');
      setAdminNote('');
      queryClient.invalidateQueries({ queryKey: ['admin-withdrawals'] });
      setSelectedWithdrawal(null);
    },
    onError: () => toast.error('Failed to reject withdrawal'),
  });

  const onCloseModal = () => {
    setSelectedWithdrawal(null);
    setAdminNote('');
  };

  const isPendingAction = approveMutation.isPending || rejectMutation.isPending;
  const canTakeAction = selectedWithdrawal?.status?.toLowerCase() === 'pending';

  return (
    <DashboardContent>
      <Stack
        direction={{ xs: 'column', sm: 'row' }}
        alignItems={{ xs: 'stretch', sm: 'center' }}
        justifyContent="space-between"
        spacing={2}
        sx={{ mb: 3 }}
      >
        <Typography variant="h4">Withdrawals</Typography>

        <FormControl sx={{ minWidth: 180 }}>
          <InputLabel id="withdrawal-status-filter">Status</InputLabel>
          <Select
            labelId="withdrawal-status-filter"
            label="Status"
            value={statusFilter}
            onChange={(event) => setStatusFilter(event.target.value as StatusFilter)}
          >
            <MenuItem value="all">All</MenuItem>
            <MenuItem value="pending">Pending</MenuItem>
            <MenuItem value="approved">Approved</MenuItem>
            <MenuItem value="rejected">Rejected</MenuItem>
          </Select>
        </FormControl>
      </Stack>

      {isError && <Alert severity="error">Unable to load withdrawal requests.</Alert>}

      <Card>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>ID</TableCell>
                <TableCell>User ID</TableCell>
                <TableCell>Amount</TableCell>
                <TableCell>Wallet Address</TableCell>
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

              {!isLoading && withdrawals.length === 0 && (
                <TableRow>
                  <TableCell colSpan={7} align="center">
                    No withdrawal requests found.
                  </TableCell>
                </TableRow>
              )}

              {withdrawals.map((withdrawal) => {
                const status = withdrawal.status?.toLowerCase();
                return (
                  <TableRow key={withdrawal.id} hover>
                    <TableCell>{withdrawal.id}</TableCell>
                    <TableCell>{withdrawal.user_id}</TableCell>
                    <TableCell>${formatAmount(withdrawal.amount)}</TableCell>
                    <TableCell>{withdrawal.wallet_address || '--'}</TableCell>
                    <TableCell>
                      <Chip
                        size="small"
                        label={withdrawal.status}
                        color={statusColorMap[status] ?? 'default'}
                      />
                    </TableCell>
                    <TableCell>{formatDate(withdrawal.created_at)}</TableCell>
                    <TableCell align="right">
                      <Button
                        size="small"
                        variant="outlined"
                        onClick={() => setSelectedWithdrawal(withdrawal)}
                      >
                        View
                      </Button>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </TableContainer>
      </Card>

      <Dialog open={Boolean(selectedWithdrawal)} onClose={onCloseModal} fullWidth maxWidth="sm">
        <DialogTitle>Withdrawal Request Details</DialogTitle>
        <DialogContent>
          {selectedWithdrawal && (
            <Stack spacing={1.5} sx={{ mt: 1 }}>
              <Typography variant="body2">Request ID: {selectedWithdrawal.id}</Typography>
              <Typography variant="body2">User ID: {selectedWithdrawal.user_id}</Typography>
              <Typography variant="body2">Amount: ${formatAmount(selectedWithdrawal.amount)}</Typography>
              <Typography variant="body2">
                Wallet Address: {selectedWithdrawal.wallet_address || '--'}
              </Typography>
              <Typography variant="body2">Status: {selectedWithdrawal.status}</Typography>
              <Typography variant="body2">
                Created At: {formatDate(selectedWithdrawal.created_at)}
              </Typography>
              <Typography variant="body2">
                Previous Admin Note: {selectedWithdrawal.admin_note || '--'}
              </Typography>

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
          {canTakeAction && selectedWithdrawal && (
            <>
              <Button
                color="error"
                variant="outlined"
                disabled={isPendingAction}
                onClick={() =>
                  rejectMutation.mutate({
                    id: selectedWithdrawal.id,
                    note: adminNote.trim() || undefined,
                  })
                }
              >
                {rejectMutation.isPending ? 'Rejecting...' : 'Reject'}
              </Button>
              <Button
                color="success"
                variant="contained"
                disabled={isPendingAction}
                onClick={() =>
                  approveMutation.mutate({
                    id: selectedWithdrawal.id,
                    note: adminNote.trim() || undefined,
                  })
                }
              >
                {approveMutation.isPending ? 'Approving...' : 'Approve'}
              </Button>
            </>
          )}
        </DialogActions>
      </Dialog>
    </DashboardContent>
  );
}
