import type { RouteObject } from 'react-router';

import { lazy, Suspense } from 'react';
import { Outlet } from 'react-router-dom';
import { varAlpha } from 'minimal-shared/utils';

import Box from '@mui/material/Box';
import LinearProgress, { linearProgressClasses } from '@mui/material/LinearProgress';

import { AuthLayout } from 'src/layouts/auth';
import { AuthGuard } from 'src/context/auth-guard';
import { DashboardLayout } from 'src/layouts/dashboard';

// ----------------------------------------------------------------------

export const DashboardPage = lazy(() => import('src/pages/dashboard'));
export const UserPage = lazy(() => import('src/pages/user'));
export const SignalsPage = lazy(() => import('src/pages/signals'));
export const ReferralsPage = lazy(() => import('src/pages/referrals'));
export const VipUsersPage = lazy(() => import('src/pages/vip-users'));
export const NotificationsPage = lazy(() => import('src/pages/notifications'));
export const AnnouncementsPage = lazy(() => import('src/pages/announcements'));
export const SupportPage = lazy(() => import('src/pages/support'));
export const ReportsPage = lazy(() => import('src/pages/reports'));
export const SignInPage = lazy(() => import('src/pages/sign-in'));
export const Page404 = lazy(() => import('src/pages/page-not-found'));

const renderFallback = () => (
  <Box
    sx={{
      display: 'flex',
      flex: '1 1 auto',
      alignItems: 'center',
      justifyContent: 'center',
    }}
  >
    <LinearProgress
      sx={{
        width: 1,
        maxWidth: 320,
        bgcolor: (theme) => varAlpha(theme.vars.palette.text.primaryChannel, 0.16),
        [`& .${linearProgressClasses.bar}`]: { bgcolor: 'text.primary' },
      }}
    />
  </Box>
);

export const routesSection: RouteObject[] = [
  {
    element: (
      <AuthGuard>
        <DashboardLayout>
          <Suspense fallback={renderFallback()}>
            <Outlet />
          </Suspense>
        </DashboardLayout>
      </AuthGuard>
    ),
    children: [
      { index: true, element: <DashboardPage /> },
      { path: 'users', element: <UserPage /> },
      { path: 'signals', element: <SignalsPage /> },
      { path: 'referrals', element: <ReferralsPage /> },
      { path: 'vip-users', element: <VipUsersPage /> },
      { path: 'notifications', element: <NotificationsPage /> },
      { path: 'announcements', element: <AnnouncementsPage /> },
      { path: 'support', element: <SupportPage /> },
      { path: 'reports', element: <ReportsPage /> },
    ],
  },
  {
    path: 'sign-in',
    element: (
      <AuthLayout>
        <SignInPage />
      </AuthLayout>
    ),
  },
  {
    path: '404',
    element: <Page404 />,
  },
  { path: '*', element: <Page404 /> },
];
