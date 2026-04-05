import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import Cookies from 'js-cookie';
import { authApi, AdminUser } from './api';

interface AuthState {
  admin: AdminUser | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  checkAuth: () => Promise<void>;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      admin: null,
      isAuthenticated: false,
      isLoading: true,

      login: async (email: string, password: string) => {
        const { token, admin } = await authApi.login(email, password);
        Cookies.set('admin_token', token, { expires: 7 });
        set({ admin, isAuthenticated: true });
      },

      logout: async () => {
        try {
          await authApi.logout();
        } finally {
          Cookies.remove('admin_token');
          set({ admin: null, isAuthenticated: false });
        }
      },

      checkAuth: async () => {
        const token = Cookies.get('admin_token');
        if (!token) {
          set({ isLoading: false, isAuthenticated: false });
          return;
        }

        try {
          const admin = await authApi.me();
          set({ admin, isAuthenticated: true, isLoading: false });
        } catch {
          Cookies.remove('admin_token');
          set({ admin: null, isAuthenticated: false, isLoading: false });
        }
      },
    }),
    {
      name: 'admin-auth',
      partialize: (state) => ({ admin: state.admin }),
    }
  )
);
