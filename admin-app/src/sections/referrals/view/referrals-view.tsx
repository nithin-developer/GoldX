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

export function ReferralsView() {
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  const { data, isLoading, isError } = useQuery({
    queryKey: ['referrals', page, rowsPerPage],
    queryFn: () =>
      referralService.getReferrals({
        skip: page * rowsPerPage,
        limit: rowsPerPage,
      }),
  });

  const referrals = data?.items ?? [];
  const totalReferrals = data?.total ?? 0;

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
        Referrals
      </Typography>

      {isError && <Alert severity="error">Unable to load referral data.</Alert>}

      <Card>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Referrer</TableCell>
                <TableCell>Referred User</TableCell>
                <TableCell>Deposit</TableCell>
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

              {!isLoading && referrals.length === 0 && (
                <TableRow>
                  <TableCell colSpan={4} align="center">
                    No referral records found.
                  </TableCell>
                </TableRow>
              )}

              {referrals.map((referral) => (
                <TableRow key={referral.id} hover>
                  <TableCell>{referral.referrer}</TableCell>
                  <TableCell>{referral.referred_user}</TableCell>
                  <TableCell>${referral.deposit.toLocaleString()}</TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      label={referral.status}
                      color={referral.status.toLowerCase() === 'active' ? 'success' : 'default'}
                    />
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>

        <TablePagination
          component="div"
          page={page}
          count={totalReferrals}
          rowsPerPage={rowsPerPage}
          onPageChange={handleChangePage}
          rowsPerPageOptions={[5, 10, 25]}
          onRowsPerPageChange={handleChangeRowsPerPage}
        />
      </Card>
    </DashboardContent>
  );
}
