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

export function VipView() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['vip-users'],
    queryFn: referralService.getVipUsers,
  });

  const users = data ?? [];

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
      </Card>
    </DashboardContent>
  );
}
