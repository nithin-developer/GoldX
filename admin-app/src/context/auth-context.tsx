import type { ReactNode } from 'react';

import { useMemo, useState, useContext, useCallback, createContext } from 'react';

import { authService } from 'src/services/auth.service';

// ----------------------------------------------------------------------

type AuthUser = {
  email: string;
  role: string;
  full_name?: string | null;
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
    if (!stored) {
      return null;
    }

    try {
      const parsed = JSON.parse(stored) as Partial<AuthUser>;
      if (!parsed?.email || !parsed?.role) {
        return null;
      }

      return {
        email: parsed.email,
        role: parsed.role,
        full_name: parsed.full_name ?? null,
      };
    } catch {
      return null;
    }
  });

  const login = useCallback(async (email: string, password: string) => {
    const response = await authService.login({ email, password });

    if (response.role !== 'admin') {
      throw new Error('Access denied. Admin role required.');
    }

    const authUser: AuthUser = {
      email: response.email,
      role: response.role,
      full_name: response.full_name ?? null,
    };

    localStorage.setItem('access_token', response.access_token);
    localStorage.setItem('admin_user', JSON.stringify(authUser));

    setToken(response.access_token);
    setUser(authUser);
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
