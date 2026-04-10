import { Icon } from '@iconify/react/dist/iconify.js';

// ----------------------------------------------------------------------

export type NavItem = {
  title: string;
  path: string;
  icon: React.ReactNode;
  info?: React.ReactNode;
};

export const navData: NavItem[] = [
  {
    title: 'Dashboard',
    path: '/',
    icon: <Icon icon="solar:home-angle-bold-duotone" width={24} />,
  },
  {
    title: 'Users',
    path: '/users',
    icon: <Icon icon="solar:users-group-rounded-bold-duotone" width={24} />,
  },
  {
    title: 'Signals',
    path: '/signals',
    icon: <Icon icon="solar:pulse-bold" width={24} />,
  },
  {
    title: 'Deposits',
    path: '/deposits',
    icon: <Icon icon="solar:wallet-money-bold-duotone" width={24} />,
  },
  {
    title: 'Withdrawals',
    path: '/withdrawals',
    icon: <Icon icon="solar:hand-money-outline" width={24} />,
  },
  {
    title: 'Verifications',
    path: '/verifications',
    icon: <Icon icon="solar:shield-check-bold-duotone" width={24} />,
  },
  {
    title: 'Referrals',
    path: '/referrals',
    icon: <Icon icon="solar:users-group-two-rounded-bold-duotone" width={24} />,
  },
  {
    title: 'VIP Users',
    path: '/vip-users',
    icon: <Icon icon="solar:shield-user-bold-duotone" width={24} />,
  },
  {
    title: 'Notifications',
    path: '/notifications',
    icon: <Icon icon="solar:bell-bing-bold-duotone" width={24} />,
  },
  {
    title: 'Announcements',
    path: '/announcements',
    icon: <Icon icon="solar:user-speak-bold-duotone" width={24} />,
  },
  // {
  //   title: 'Reports',
  //   path: '/reports',
  //   icon: <Icon icon="solar:pie-chart-2-bold-duotone" width={24} />,
  // },
  {
    title: 'Settings',
    path: '/settings',
    icon: <Icon icon="solar:settings-bold-duotone" width={24} />,
  },
];
