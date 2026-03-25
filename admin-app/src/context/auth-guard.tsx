import type { ReactNode } from 'react';

import { Navigate } from 'react-router-dom';

import { useAuth } from './auth-context';

// ----------------------------------------------------------------------

type AuthGuardProps = {
  children: ReactNode;
};

export function AuthGuard({ children }: AuthGuardProps) {
  const { isAuthenticated } = useAuth();

  if (!isAuthenticated) {
    return <Navigate to="/sign-in" replace />;
  }

  return <>{children}</>;
}
