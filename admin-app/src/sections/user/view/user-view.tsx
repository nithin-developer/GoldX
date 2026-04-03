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

  const users = data ?? [];

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
                if (user.email !== 'admin@tradingsignals.com') {
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
                          color={blocked ? 'success' : 'error'}
                          onClick={() =>
                            updateMutation.mutate({
                              id: user.id,
                              payload: { status: nextStatus },
                            })
                          }
                          disabled={updateMutation.isPending}
                        >
                          {blocked ? 'Unblock' : 'Block'}
                        </Button>
                      </Stack>
                    </TableCell>
                  </TableRow>
                );
              }
              })}
            </TableBody>
          </Table>
        </TableContainer>
      </Card>
    </DashboardContent>
  );
}
