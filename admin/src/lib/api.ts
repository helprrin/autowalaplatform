import axios, { AxiosError } from 'axios';
import Cookies from 'js-cookie';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use((config) => {
  const token = Cookies.get('admin_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      Cookies.remove('admin_token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Types
export interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: string;
}

export interface DashboardStats {
  total_users: number;
  total_riders: number;
  active_riders: number;
  pending_kyc: number;
  total_rides: number;
  rides_today: number;
  average_rating: number;
  complaints_pending: number;
}

export interface Rider {
  id: string;
  user_id: string;
  license_number: string;
  status: 'pending' | 'approved' | 'rejected' | 'suspended';
  kyc_status: 'pending' | 'submitted' | 'verified' | 'rejected';
  is_online: boolean;
  rating_avg: number;
  total_rides: number;
  created_at: string;
  user: {
    id: string;
    name: string;
    phone: string;
    avatar_url?: string;
  };
  vehicle?: {
    id: string;
    vehicle_number: string;
    vehicle_type: string;
    color: string;
  };
}

export interface User {
  id: string;
  name: string;
  phone: string;
  email?: string;
  avatar_url?: string;
  status: 'active' | 'suspended' | 'deleted';
  total_rides: number;
  created_at: string;
}

export interface Document {
  id: string;
  rider_id: string;
  type: string;
  file_url: string;
  status: 'pending' | 'approved' | 'rejected';
  rejection_reason?: string;
  created_at: string;
}

export interface Complaint {
  id: string;
  user_id?: string;
  rider_id?: string;
  ride_log_id?: string;
  type: string;
  description: string;
  status: 'pending' | 'investigating' | 'resolved' | 'dismissed';
  admin_notes?: string;
  created_at: string;
  user?: User;
  rider?: Rider;
}

// Auth API
export const authApi = {
  login: async (email: string, password: string) => {
    const response = await api.post<{ token: string; admin: AdminUser }>(
      '/admin/login',
      { email, password }
    );
    return response.data;
  },

  logout: async () => {
    await api.post('/admin/logout');
    Cookies.remove('admin_token');
  },

  me: async () => {
    const response = await api.get<AdminUser>('/admin/me');
    return response.data;
  },
};

// Dashboard API
export const dashboardApi = {
  getStats: async () => {
    const response = await api.get<DashboardStats>('/admin/dashboard/stats');
    return response.data;
  },

  getOnlineRiders: async () => {
    const response = await api.get<Rider[]>('/admin/dashboard/online-riders');
    return response.data;
  },

  getRecentActivity: async () => {
    const response = await api.get('/admin/dashboard/activity');
    return response.data;
  },
};

// Riders API
export const ridersApi = {
  list: async (params?: { status?: string; page?: number }) => {
    const response = await api.get<{ data: Rider[]; meta: any }>(
      '/admin/riders',
      { params }
    );
    return response.data;
  },

  get: async (id: string) => {
    const response = await api.get<Rider>(`/admin/riders/${id}`);
    return response.data;
  },

  updateStatus: async (id: string, status: string, reason?: string) => {
    const response = await api.patch(`/admin/riders/${id}/status`, {
      status,
      reason,
    });
    return response.data;
  },

  getDocuments: async (id: string) => {
    const response = await api.get<Document[]>(`/admin/riders/${id}/documents`);
    return response.data;
  },
};

// KYC API
export const kycApi = {
  getPending: async () => {
    const response = await api.get<Rider[]>('/admin/kyc/pending');
    return response.data;
  },

  approve: async (riderId: string) => {
    const response = await api.post(`/admin/kyc/${riderId}/approve`);
    return response.data;
  },

  reject: async (riderId: string, reason: string) => {
    const response = await api.post(`/admin/kyc/${riderId}/reject`, { reason });
    return response.data;
  },

  approveDocument: async (documentId: string) => {
    const response = await api.post(`/admin/documents/${documentId}/approve`);
    return response.data;
  },

  rejectDocument: async (documentId: string, reason: string) => {
    const response = await api.post(`/admin/documents/${documentId}/reject`, {
      reason,
    });
    return response.data;
  },
};

// Users API
export const usersApi = {
  list: async (params?: { status?: string; page?: number; search?: string }) => {
    const response = await api.get<{ data: User[]; meta: any }>(
      '/admin/users',
      { params }
    );
    return response.data;
  },

  get: async (id: string) => {
    const response = await api.get<User>(`/admin/users/${id}`);
    return response.data;
  },

  updateStatus: async (id: string, status: string) => {
    const response = await api.patch(`/admin/users/${id}/status`, { status });
    return response.data;
  },
};

// Complaints API
export const complaintsApi = {
  list: async (params?: { status?: string; page?: number }) => {
    const response = await api.get<{ data: Complaint[]; meta: any }>(
      '/admin/complaints',
      { params }
    );
    return response.data;
  },

  get: async (id: string) => {
    const response = await api.get<Complaint>(`/admin/complaints/${id}`);
    return response.data;
  },

  updateStatus: async (id: string, status: string, notes?: string) => {
    const response = await api.patch(`/admin/complaints/${id}`, {
      status,
      admin_notes: notes,
    });
    return response.data;
  },
};

export default api;
