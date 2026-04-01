import { Iconify } from 'src/components/iconify';

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
    icon: <Iconify icon="solar:home-angle-bold-duotone" width={24} />,
  },
  {
    title: 'Users',
    path: '/users',
    icon: <Iconify icon="solar:eye-bold" width={24} />,
  },
  {
    title: 'Signals',
    path: '/signals',
    icon: <Iconify icon="solar:pen-bold" width={24} />,
  },
  {
    title: 'Deposits',
    path: '/deposits',
    icon: <Iconify icon="solar:cart-3-bold" width={24} />,
  },
  {
    title: 'Withdrawals',
    path: '/withdrawals',
    icon: <Iconify icon="eva:trending-down-fill" width={24} />,
  },
  {
    title: 'Referrals',
    path: '/referrals',
    icon: <Iconify icon="solar:share-bold" width={24} />,
  },
  {
    title: 'VIP Users',
    path: '/vip-users',
    icon: <Iconify icon="solar:shield-keyhole-bold-duotone" width={24} />,
  },
  {
    title: 'Notifications',
    path: '/notifications',
    icon: <Iconify icon="solar:bell-bing-bold-duotone" width={24} />,
  },
  {
    title: 'Announcements',
    path: '/announcements',
    icon: <Iconify icon="solar:restart-bold" width={24} />,
  },
  {
    title: 'Support',
    path: '/support',
    icon: <Iconify icon="solar:chat-round-dots-bold" width={24} />,
  },
  {
    title: 'Reports',
    path: '/reports',
    icon: <Iconify icon="solar:settings-bold-duotone" width={24} />,
  },
  {
    title: 'Settings',
    path: '/settings',
    icon: <Iconify icon="solar:settings-bold-duotone" width={24} />,
  },
];
