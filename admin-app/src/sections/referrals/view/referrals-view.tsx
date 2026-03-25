import { useQuery } from '@tanstack/react-query';

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
  CircularProgress,
} from '@mui/material';

import { DashboardContent } from 'src/layouts/dashboard';
import { referralService } from 'src/services/referral.service';

// ----------------------------------------------------------------------

export function ReferralsView() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['referrals'],
    queryFn: referralService.getReferrals,
  });

  const referrals = data ?? [];

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
      </Card>
    </DashboardContent>
  );
}
