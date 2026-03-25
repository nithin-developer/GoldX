import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';

import {
  Card,
  Grid,
  Stack,
  Alert,
  TextField,
  Typography,
  CircularProgress,
} from '@mui/material';

import { DashboardContent } from 'src/layouts/dashboard';
import { reportService } from 'src/services/report.service';

import { AnalyticsWebsiteVisits } from 'src/sections/overview/analytics-website-visits';
import { AnalyticsWidgetSummary } from 'src/sections/overview/analytics-widget-summary';

// ----------------------------------------------------------------------

export function ReportsView() {
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');

  const { data, isLoading, isError } = useQuery({
    queryKey: ['reports'],
    queryFn: reportService.getReports,
  });

  return (
    <DashboardContent maxWidth="xl">
      <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} alignItems={{ xs: 'stretch', sm: 'center' }} sx={{ mb: 3 }}>
        <Typography variant="h4" sx={{ flexGrow: 1 }}>
          Reports
        </Typography>
        <TextField
          type="date"
          label="From"
          InputLabelProps={{ shrink: true }}
          value={fromDate}
          onChange={(event) => setFromDate(event.target.value)}
        />
        <TextField
          type="date"
          label="To"
          InputLabelProps={{ shrink: true }}
          value={toDate}
          onChange={(event) => setToDate(event.target.value)}
        />
      </Stack>

      {isError && <Alert severity="error">Unable to load reports.</Alert>}

      {isLoading && (
        <Stack alignItems="center" sx={{ py: 4 }}>
          <CircularProgress size={24} />
        </Stack>
      )}

      {!isLoading && data && (
        <Grid container spacing={3}>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <AnalyticsWidgetSummary
              title="Revenue"
              percent={2.1}
              total={data.revenue ?? data.daily_profit}
              icon={<img alt="Revenue" src="/assets/icons/glass/ic-glass-buy.svg" />}
              chart={{
                categories: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                series: [30, 45, 25, 40, 35, 50, 42],
              }}
            />
          </Grid>

          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <AnalyticsWidgetSummary
              title="Deposits"
              percent={1.8}
              total={data.total_deposits}
              color="success"
              icon={<img alt="Deposits" src="/assets/icons/glass/ic-glass-wallet.svg" />}
              chart={{
                categories: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                series: [12, 24, 18, 30, 28, 35, 32],
              }}
            />
          </Grid>

          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <AnalyticsWidgetSummary
              title="Withdrawals"
              percent={-0.8}
              total={data.withdrawals ?? 0}
              color="warning"
              icon={<img alt="Withdrawals" src="/assets/icons/glass/ic-glass-message.svg" />}
              chart={{
                categories: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                series: [9, 12, 7, 13, 10, 16, 14],
              }}
            />
          </Grid>

          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <AnalyticsWidgetSummary
              title="Daily Profit"
              percent={3.2}
              total={data.daily_profit}
              color="secondary"
              icon={<img alt="Daily profit" src="/assets/icons/glass/ic-glass-users.svg" />}
              chart={{
                categories: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                series: [15, 22, 27, 23, 36, 42, 38],
              }}
            />
          </Grid>

          <Grid size={{ xs: 12 }}>
            <Card>
              <AnalyticsWebsiteVisits
                title="Performance Snapshot"
                subheader={
                  fromDate && toDate
                    ? `${fromDate} to ${toDate}`
                    : 'Current trend based on backend aggregate report'
                }
                chart={{
                  categories: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                  series: [
                    { name: 'Deposits', data: [45, 52, 61, 59, 67, 72] },
                    { name: 'Profit', data: [22, 28, 35, 33, 41, 48] },
                  ],
                }}
              />
            </Card>
          </Grid>
        </Grid>
      )}
    </DashboardContent>
  );
}
