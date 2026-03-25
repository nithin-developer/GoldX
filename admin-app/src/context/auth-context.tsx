import type { ReactNode } from 'react';

import { useMemo, useState, useContext, useCallback, createContext } from 'react';

import { authService } from 'src/services/auth.service';

// ----------------------------------------------------------------------

type AuthUser = {
  email: string;
  role: string;
};

type AuthContextType = {
  user: AuthUser | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
};

const AuthContext = createContext<AuthContextType | null>(null);

// ----------------------------------------------------------------------

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(() => localStorage.getItem('access_token'));
  const [user, setUser] = useState<AuthUser | null>(() => {
    const stored = localStorage.getItem('admin_user');
    return stored ? JSON.parse(stored) : null;
  });

  const login = useCallback(async (email: string, password: string) => {
    const response = await authService.login({ email, password });

    if (response.role !== 'admin') {
      throw new Error('Access denied. Admin role required.');
    }

    localStorage.setItem('access_token', response.access_token);
    localStorage.setItem('admin_user', JSON.stringify({ email, role: response.role }));

    setToken(response.access_token);
    setUser({ email, role: response.role });
  }, []);

  const logout = useCallback(() => {
    authService.logout();
    setToken(null);
    setUser(null);
  }, []);

  const value = useMemo(
    () => ({
      user,
      token,
      isAuthenticated: !!token,
      login,
      logout,
    }),
    [user, token, login, logout]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

// ----------------------------------------------------------------------

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
