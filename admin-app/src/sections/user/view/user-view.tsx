import { useState } from 'react';
import { toast } from 'react-hot-toast';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import {
  Card,
  Chip,
  Stack,
  Table,
  Alert,
  Button,
  TableRow,
  TableBody,
  TableCell,
  TableHead,
  Typography,
  TableContainer,
  CircularProgress,
} from '@mui/material';

import { DashboardContent } from 'src/layouts/dashboard';
import { getApiErrorMessage } from 'src/services/auth.service';
import { userService, type UserData } from 'src/services/user.service';

import { ConfirmDialog } from 'src/components/confirm-dialog';

// ----------------------------------------------------------------------

function getUserStatus(user: UserData) {
  if (typeof user.status === 'string' && user.status.trim()) {
    return user.status;
  }

  if (typeof user.is_active === 'boolean') {
    return user.is_active ? 'active' : 'blocked';
  }

  return 'unknown';
}

function isBlocked(status: string) {
  return status.toLowerCase().includes('block') || status.toLowerCase() === 'inactive';
}

function formatBalance(value: number | string | null | undefined) {
  const amount = Number(value ?? 0);
  if (Number.isNaN(amount)) {
    return '0.00';
  }
  return amount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

export function UserView() {
  const queryClient = useQueryClient();
  const [deleteUserId, setDeleteUserId] = useState<number | null>(null);
  const [resetPasswordUserId, setResetPasswordUserId] = useState<number | null>(null);
  const [blockUserId, setBlockUserId] = useState<number | null>(null);
  const [blockUserStatus, setBlockUserStatus] = useState<string>('');

  const { data, isLoading, isError } = useQuery({
    queryKey: ['users'],
    queryFn: userService.getUsers,
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }: { id: number; payload: Partial<UserData> }) =>
      userService.updateUser(id, payload),
    onSuccess: () => {
      toast.success('User updated');
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
    onError: (error) => toast.error(getApiErrorMessage(error, 'Failed to update user')),
  });

  const resetPasswordMutation = useMutation({
    mutationFn: (id: number) => userService.resetWithdrawalPassword(id),
    onSuccess: () => {
      toast.success('Withdrawal password reset to GoldX@1234');
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
    onError: (error) => toast.error(getApiErrorMessage(error, 'Failed to reset withdrawal password')),
  });

  const deleteUserMutation = useMutation({
    mutationFn: (id: number) => userService.deleteUser(id),
    onSuccess: () => {
      toast.success('User deleted successfully');
      queryClient.invalidateQueries({ queryKey: ['users'] });
      setDeleteUserId(null);
    },
    onError: (error) => toast.error(getApiErrorMessage(error, 'Failed to delete user')),
  });

  const users = (data ?? []).filter((user) => user.email !== 'admin@tradingsignals.com');

  return (
    <DashboardContent>
      <Typography variant="h4" sx={{ mb: 3 }}>
        Users
      </Typography>

      {isError && <Alert severity="error">Unable to load users.</Alert>}

      <Card>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Email</TableCell>
                <TableCell>Balance</TableCell>
                <TableCell>VIP Level</TableCell>
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

              {users.map((user) => {
                const status = getUserStatus(user);
                const blocked = isBlocked(status);
                const nextStatus = blocked ? 'active' : 'blocked';

                return (
                  <TableRow key={user.id} hover>
                    <TableCell>{user.email ?? '-'}</TableCell>
                    <TableCell>${formatBalance(user.wallet_balance)}</TableCell>
                    <TableCell>{user.vip_level ?? 0}</TableCell>
                    <TableCell>
                      <Chip
                        size="small"
                        label={status}
                        color={blocked ? 'error' : 'success'}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Stack direction="row" spacing={1} justifyContent="flex-end">
                        <Button
                          size="small"
                          variant="outlined"
                          color="warning"
                          onClick={() => setResetPasswordUserId(user.id)}
                        >
                          Reset WD Password
                        </Button>
                        <Button
                          size="small"
                          variant="outlined"
                          color={blocked ? 'success' : 'error'}
                          onClick={() => {
                            setBlockUserId(user.id);
                            setBlockUserStatus(nextStatus);
                          }}
                        >
                          {blocked ? 'Unblock' : 'Block'}
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

      <ConfirmDialog
        open={resetPasswordUserId !== null}
        onClose={() => setResetPasswordUserId(null)}
        onConfirm={() => {
          if (resetPasswordUserId) {
            resetPasswordMutation.mutate(resetPasswordUserId);
            setResetPasswordUserId(null);
          }
        }}
        title="Reset Withdrawal Password"
        content="Are you sure you want to reset this user's withdrawal password to GoldX@1234?"
        confirmText="Reset Password"
        confirmColor="warning"
        isPending={resetPasswordMutation.isPending}
      />

      <ConfirmDialog
        open={blockUserId !== null}
        onClose={() => setBlockUserId(null)}
        onConfirm={() => {
          if (blockUserId) {
            updateMutation.mutate({
              id: blockUserId,
              payload: { status: blockUserStatus },
            });
            setBlockUserId(null);
          }
        }}
        title={blockUserStatus === 'blocked' ? 'Block User' : 'Unblock User'}
        content={
          blockUserStatus === 'blocked'
            ? 'Are you sure you want to block this user? They will lose access to their account.'
            : 'Are you sure you want to unblock this user? They will regain access to their account.'
        }
        confirmText={blockUserStatus === 'blocked' ? 'Block User' : 'Unblock User'}
        confirmColor={blockUserStatus === 'blocked' ? 'error' : 'success'}
        isPending={updateMutation.isPending}
      />

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
