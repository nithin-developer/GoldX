import { useState, type ReactNode } from 'react';
import { toast } from 'react-hot-toast';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { alpha } from '@mui/material/styles';

import {
  Box,
  Card,
  Chip,
  Alert,
  Avatar,
  Stack,
  Table,
  Button,
  Dialog,
  Divider,
  TableRow,
  TableBody,
  TableCell,
  TableHead,
  TextField,
  Typography,
  DialogTitle,
  DialogContent,
  InputAdornment,
  TableContainer,
  CircularProgress,
} from '@mui/material';

import { DashboardContent } from 'src/layouts/dashboard';
import { getApiErrorMessage } from 'src/services/auth.service';
import { userService, type UserData } from 'src/services/user.service';

import { Iconify } from 'src/components/iconify';
import { ConfirmDialog } from 'src/components/confirm-dialog';

// ----------------------------------------------------------------------

function isActiveUser(user: UserData) {
  return Boolean(user.is_active);
}

function formatBalance(value: number | string | null | undefined) {
  const amount = Number(value ?? 0);
  if (Number.isNaN(amount)) {
    return '0.00';
  }
  return amount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function formatDateTime(value: string | undefined) {
  if (!value) {
    return '--';
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return '--';
  }

  return date.toLocaleString();
}

function getDisplayName(user: UserData) {
  return user.full_name?.trim() || '--';
}

function getAvatarInitial(user: UserData) {
  const source = user.full_name?.trim() || user.email || 'U';
  return source.charAt(0).toUpperCase();
}

export function UserView() {
  const queryClient = useQueryClient();

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedUser, setSelectedUser] = useState<UserData | null>(null);
  const [deleteUserId, setDeleteUserId] = useState<number | null>(null);

  const normalizedSearch = searchQuery.trim();

  const { data, isLoading, isError } = useQuery({
    queryKey: ['users', normalizedSearch],
    queryFn: () =>
      userService.getUsers({
        search: normalizedSearch || undefined,
        limit: 100,
      }),
  });

  const deleteUserMutation = useMutation({
    mutationFn: (id: number) => userService.deleteUser(id),
    onSuccess: (_data, deletedUserId) => {
      toast.success('User deleted successfully');
      queryClient.invalidateQueries({ queryKey: ['users'] });

      if (selectedUser?.id === deletedUserId) {
        setSelectedUser(null);
      }

      setDeleteUserId(null);
    },
    onError: (error) => {
      toast.error(getApiErrorMessage(error, 'Failed to delete user'));
    },
  });

  const users = (data ?? []).filter((user) => user.email !== 'admin@tradingsignals.com');

  return (
    <DashboardContent>
      <Stack direction="row" alignItems="center" justifyContent="space-between" sx={{ mb: 3 }}>
        <Typography variant="h4">Users</Typography>
        <TextField
          value={searchQuery}
          onChange={(event) => setSearchQuery(event.target.value)}
          placeholder="Search by User ID, username, email, or wallet address"
          size="small"
          sx={{ width: { xs: '100%', sm: 420 } }}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <Iconify width={20} icon="eva:search-fill" sx={{ color: 'text.disabled' }} />
              </InputAdornment>
            ),
          }}
        />
      </Stack>

      {isError && <Alert severity="error">Unable to load users.</Alert>}

      <Card>
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>SL No</TableCell>
                <TableCell>Email</TableCell>
                <TableCell>Name</TableCell>
                <TableCell>Status</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading && (
                <TableRow>
                  <TableCell colSpan={5} align="center">
                    <CircularProgress size={24} />
                  </TableCell>
                </TableRow>
              )}

              {!isLoading && users.length === 0 && (
                <TableRow>
                  <TableCell colSpan={5} align="center">
                    No users found.
                  </TableCell>
                </TableRow>
              )}

              {users.map((user, index) => {
                const active = isActiveUser(user);
                const statusLabel = active ? 'Active' : 'Blocked';

                return (
                  <TableRow key={user.id} hover>
                    <TableCell>{index + 1}</TableCell>
                    <TableCell>{user.email ?? '-'}</TableCell>
                    <TableCell>{getDisplayName(user)}</TableCell>
                    <TableCell>
                      <Chip size="small" label={statusLabel} color={active ? 'success' : 'error'} />
                    </TableCell>
                    <TableCell align="right">
                      <Stack direction="row" spacing={1} justifyContent="flex-end">
                        <Button
                          size="small"
                          variant="contained"
                          onClick={() => setSelectedUser(user)}
                          startIcon={<Iconify width={16} icon="solar:eye-bold" />}
                        >
                          View Details
                        </Button>
                        <Button
                          size="small"
                          variant="outlined"
                          color="error"
                          onClick={() => setDeleteUserId(user.id)}
                        >
                          Delete
                        </Button>
                      </Stack>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </TableContainer>
      </Card>

      <Dialog
        open={selectedUser !== null}
        onClose={() => setSelectedUser(null)}
        fullWidth
        maxWidth="md"
      >
        {selectedUser && (
          <>
            <DialogTitle sx={{ pb: 1.5 }}>
              <Stack direction="row" alignItems="center" justifyContent="space-between" spacing={2}>
                <Stack direction="row" alignItems="center" spacing={1.5}>
                  <Avatar
                    sx={(theme) => ({
                      width: 42,
                      height: 42,
                      fontWeight: 700,
                      background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.dark} 100%)`,
                    })}
                  >
                    {getAvatarInitial(selectedUser)}
                  </Avatar>
                  <Box>
                    <Typography variant="h6">User Details</Typography>
                    <Typography variant="body2" color="text.secondary">
                      {selectedUser.email || '--'}
                    </Typography>
                  </Box>
                </Stack>
                <Button
                  size="small"
                  color="inherit"
                  onClick={() => setSelectedUser(null)}
                >
                  Close
                </Button>
              </Stack>
            </DialogTitle>

            <DialogContent sx={{ pb: 3 }}>
              <Stack spacing={2.5}>
                <Box
                  sx={(theme) => ({
                    p: 2,
                    borderRadius: 2,
                    border: `1px solid ${theme.palette.divider}`,
                    background: `linear-gradient(180deg, ${alpha(theme.palette.primary.light, 0.12)} 0%, transparent 100%)`,
                  })}
                >
                  <Typography variant="overline" sx={{ color: 'text.secondary' }}>
                    Account Overview
                  </Typography>
                  <Divider sx={{ my: 1.25 }} />
                  <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2.5}>
                    <Stack spacing={1.25} sx={{ flex: 1 }}>
                      <DetailRow label="User ID" value={selectedUser.id} />
                      <DetailRow label="Name" value={getDisplayName(selectedUser)} />
                      <DetailRow label="Email" value={selectedUser.email || '--'} />
                    </Stack>
                    <Stack spacing={1.25} sx={{ flex: 1 }}>
                      <DetailRow
                        label="Status"
                        value={
                          <Chip
                            size="small"
                            label={isActiveUser(selectedUser) ? 'Active' : 'Blocked'}
                            color={isActiveUser(selectedUser) ? 'success' : 'error'}
                          />
                        }
                      />
                      <DetailRow
                        label="Joined At"
                        value={formatDateTime(selectedUser.created_at)}
                      />
                      <DetailRow
                        label="Wallet Address"
                        value={selectedUser.wallet_address?.trim() || '--'}
                      />
                    </Stack>
                  </Stack>
                </Box>

                <Box
                  sx={(theme) => ({
                    p: 2,
                    borderRadius: 2,
                    border: `1px solid ${theme.palette.divider}`,
                  })}
                >
                  <Typography variant="overline" sx={{ color: 'text.secondary' }}>
                    Wallet Breakdown
                  </Typography>
                  <Divider sx={{ my: 1.25 }} />
                  <Stack direction={{ xs: 'column', md: 'row' }} spacing={1.25}>
                    <SummaryCard
                      label="Capital Balance"
                      value={`$${formatBalance(selectedUser.capital_balance)}`}
                      tone="primary"
                    />
                    <SummaryCard
                      label="Signal Profits"
                      value={`$${formatBalance(selectedUser.signal_profit_balance)}`}
                      tone="success"
                    />
                    <SummaryCard
                      label="Team Rewards"
                      value={`$${formatBalance(selectedUser.reward_balance)}`}
                      tone="warning"
                    />
                  </Stack>
                </Box>

                <Box
                  sx={(theme) => ({
                    p: 2,
                    borderRadius: 2,
                    border: `1px solid ${theme.palette.divider}`,
                  })}
                >
                  <Typography variant="overline" sx={{ color: 'text.secondary' }}>
                    Activity Snapshot
                  </Typography>
                  <Divider sx={{ my: 1.25 }} />
                  <Stack direction="row" flexWrap="wrap" gap={1}>
                    <Chip label={`Wallet: $${formatBalance(selectedUser.wallet_balance)}`} />
                    <Chip
                      color="info"
                      label={`Withdrawable: $${formatBalance(selectedUser.withdrawable_balance)}`}
                    />
                    <Chip
                      color="warning"
                      label={`Locked Capital: $${formatBalance(selectedUser.locked_capital_balance)}`}
                    />
                    <Chip color="secondary" label={`VIP Level: ${selectedUser.vip_level ?? 0}`} />
                    <Chip label={`Referrals: ${selectedUser.referral_count ?? 0}`} />
                    <Chip
                      color="success"
                      label={`Referral Deposits: $${formatBalance(selectedUser.referral_total_deposits)}`}
                    />
                  </Stack>
                </Box>
              </Stack>
            </DialogContent>
          </>
        )}
      </Dialog>

      <ConfirmDialog
        open={deleteUserId !== null}
        onClose={() => setDeleteUserId(null)}
        onConfirm={() => {
          if (deleteUserId) {
            deleteUserMutation.mutate(deleteUserId);
          }
        }}
        title="Delete User"
        content="Are you sure you want to delete this user? This action cannot be undone and will permanently remove all user data."
        confirmText="Delete User"
        confirmColor="error"
        isPending={deleteUserMutation.isPending}
      />
    </DashboardContent>
  );
}

type DetailRowProps = {
  label: string;
  value: ReactNode;
};

function DetailRow({ label, value }: DetailRowProps) {
  const isSimpleText = typeof value === 'string' || typeof value === 'number';

  return (
    <Stack direction="row" alignItems="center" justifyContent="space-between" spacing={2}>
      <Typography variant="body2" color="text.secondary">
        {label}
      </Typography>
      {isSimpleText ? (
        <Typography variant="body2" sx={{ fontWeight: 600, textAlign: 'right' }}>
          {value}
        </Typography>
      ) : (
        <Box sx={{ ml: 'auto' }}>{value}</Box>
      )}
    </Stack>
  );
}

type SummaryCardProps = {
  label: string;
  value: string;
  tone: 'primary' | 'success' | 'warning';
};

function SummaryCard({ label, value, tone }: SummaryCardProps) {
  return (
    <Box
      sx={(theme) => {
        const accent =
          tone === 'success'
            ? theme.palette.success.main
            : tone === 'warning'
              ? theme.palette.warning.main
              : theme.palette.primary.main;

        return {
          flex: 1,
          minWidth: 0,
          p: 1.5,
          borderRadius: 1.5,
          border: `1px solid ${alpha(accent, 0.26)}`,
          background: `linear-gradient(135deg, ${alpha(accent, 0.14)} 0%, ${alpha(accent, 0.04)} 100%)`,
        };
      }}
    >
      <Typography variant="caption" color="text.secondary">
        {label}
      </Typography>
      <Typography variant="h6" sx={{ mt: 0.5, fontWeight: 700 }}>
        {value}
      </Typography>
    </Box>
  );
}
