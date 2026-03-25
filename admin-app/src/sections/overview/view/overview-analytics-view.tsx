import { useQuery } from '@tanstack/react-query';

import Grid from '@mui/material/Grid';
import Alert from '@mui/material/Alert';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import CircularProgress from '@mui/material/CircularProgress';

import { DashboardContent } from 'src/layouts/dashboard';
import { reportService } from 'src/services/report.service';

import { AnalyticsWidgetSummary } from '../analytics-widget-summary';
import { AnalyticsWebsiteVisits } from '../analytics-website-visits';

// ----------------------------------------------------------------------

export function OverviewAnalyticsView() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['dashboard-overview'],
    queryFn: reportService.getReports,
  });

  return (
    <DashboardContent maxWidth="xl">
      <Typography variant="h4" sx={{ mb: { xs: 3, md: 5 } }}>
        Dashboard Overview
      </Typography>

      {isError && <Alert severity="error">Unable to load dashboard metrics.</Alert>}

      {isLoading && (
        <Stack alignItems="center" sx={{ py: 5 }}>
          <CircularProgress size={28} />
        </Stack>
      )}

      {!isLoading && data && (
        <Grid container spacing={3}>
          <Grid size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
            <AnalyticsWidgetSummary
              title="Total Users"
              percent={1.9}
              total={data.total_users}
              icon={<img alt="Total users" src="/assets/icons/glass/ic-glass-users.svg" />}
              chart={{
                categories: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                series: [18, 24, 28, 23, 30, 35, 33],
              }}
            />
          </Grid>

          <Grid size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
            <AnalyticsWidgetSummary
              title="Total Deposits"
              percent={2.7}
              total={data.total_deposits}
              color="success"
              icon={<img alt="Deposits" src="/assets/icons/glass/ic-glass-wallet.svg" />}
              chart={{
                categories: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                series: [40, 56, 51, 62, 74, 70, 76],
              }}
            />
          </Grid>

          <Grid size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
            <AnalyticsWidgetSummary
              title="Active Signals"
              percent={0.9}
              total={data.active_signals}
              color="warning"
              icon={<img alt="Signals" src="/assets/icons/glass/ic-glass-buy.svg" />}
              chart={{
                categories: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                series: [9, 11, 8, 10, 14, 12, 13],
              }}
            />
          </Grid>

          <Grid size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
            <AnalyticsWidgetSummary
              title="VIP Users"
              percent={1.2}
              total={data.vip_users}
              color="secondary"
              icon={<img alt="VIP users" src="/assets/icons/glass/ic-glass-message.svg" />}
              chart={{
                categories: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                series: [5, 7, 8, 8, 9, 11, 12],
              }}
            />
          </Grid>

          <Grid size={{ xs: 12 }}>
            <AnalyticsWebsiteVisits
              title="Platform Activity"
              subheader="Users vs signals over the latest period"
              chart={{
                categories: ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5', 'Week 6'],
                series: [
                  {
                    name: 'Users',
                    data: [120, 155, 184, 210, 238, 260],
                  },
                  {
                    name: 'Signals',
                    data: [35, 41, 48, 54, 58, 63],
                  },
                ],
              }}
            />
          </Grid>
        </Grid>
      )}
    </DashboardContent>
  );
}
