import { useQuery } from '@tanstack/react-query';
import { useState, type ChangeEvent } from 'react';

import {
  Card,
  Chip,
  Table,
  Alert,
  TableRow,
  TableBody,
  TableCell,
  TableHead,
  Typography,
  TableContainer,
  TablePagination,
  CircularProgress,
} from '@mui/material';

import { DashboardContent } from 'src/layouts/dashboard';
import { referralService } from 'src/services/referral.service';

// ----------------------------------------------------------------------

export function VipView() {
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  const { data, isLoading, isError } = useQuery({
    queryKey: ['vip-users', page, rowsPerPage],
    queryFn: () =>
      referralService.getVipUsers({
        skip: page * rowsPerPage,
        limit: rowsPerPage,
      }),
  });

  const users = data?.items ?? [];
  const totalUsers = data?.total ?? 0;

  const handleChangePage = (_event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event: ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  return (
    <DashboardContent>
      <Typography variant="h4" sx={{ mb: 3 }}>
        VIP Users
      </Typography>

      {isError && <Alert severity="error">Unable to load VIP users.</Alert>}

      <Card>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>User</TableCell>
                <TableCell>VIP Level</TableCell>
                <TableCell>Referrals</TableCell>
                <TableCell>Status</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading && (
                <TableRow>
                  <TableCell colSpan={4} align="center">
                    <CircularProgress size={24} />
                  </TableCell>
                </TableRow>
              )}

              {!isLoading && users.length === 0 && (
                <TableRow>
                  <TableCell colSpan={4} align="center">
                    No VIP users found.
                  </TableCell>
                </TableRow>
              )}

              {users.map((user) => (
                <TableRow key={user.id} hover>
                  <TableCell>{user.email}</TableCell>
                  <TableCell>
                    <Chip size="small" color="warning" label={`VIP ${user.vip_level}`} />
                  </TableCell>
                  <TableCell>{user.referrals_count}</TableCell>
                  <TableCell>
                    <Chip size="small" color="success" label="Active" />
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>

        <TablePagination
          component="div"
          page={page}
          count={totalUsers}
          rowsPerPage={rowsPerPage}
          onPageChange={handleChangePage}
          rowsPerPageOptions={[5, 10, 25]}
          onRowsPerPageChange={handleChangeRowsPerPage}
        />
      </Card>
    </DashboardContent>
  );
}
