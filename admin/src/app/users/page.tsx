'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { Search, ChevronRight } from 'lucide-react';
import { Sidebar } from '@/components/sidebar';
import { DataTable } from '@/components/data-table';
import { StatusBadge } from '@/components/badge';
import { usersApi, User } from '@/lib/api';
import { formatDate, formatPhone } from '@/lib/utils';

export default function UsersPage() {
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const router = useRouter();

  const { data, isLoading } = useQuery({
    queryKey: ['users', statusFilter, search, page],
    queryFn: () =>
      usersApi.list({
        status: statusFilter || undefined,
        search: search || undefined,
        page,
      }),
  });

  const columns = [
    {
      key: 'user',
      header: 'User',
      render: (user: User) => (
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gray-100 text-sm font-medium">
            {user.name?.[0] || 'U'}
          </div>
          <div>
            <p className="font-medium">{user.name}</p>
            <p className="text-sm text-gray-500">{formatPhone(user.phone)}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'email',
      header: 'Email',
      render: (user: User) => user.email || '-',
    },
    {
      key: 'status',
      header: 'Status',
      render: (user: User) => <StatusBadge status={user.status} />,
    },
    {
      key: 'rides',
      header: 'Total Rides',
      render: (user: User) => user.total_rides || 0,
    },
    {
      key: 'created',
      header: 'Joined',
      render: (user: User) => formatDate(user.created_at),
    },
    {
      key: 'action',
      header: '',
      render: () => <ChevronRight className="h-5 w-5 text-gray-400" />,
    },
  ];

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />

      <main className="ml-64 flex-1 p-8">
        <div className="mb-8">
          <h1 className="text-2xl font-bold">Users</h1>
          <p className="text-gray-500">Manage all platform users</p>
        </div>

        {/* Filters */}
        <div className="mb-6 flex items-center gap-4">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search users..."
              className="w-full rounded-lg border border-gray-300 py-2 pl-10 pr-4 text-sm focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent"
            />
          </div>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="rounded-lg border border-gray-300 px-4 py-2 text-sm focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent"
          >
            <option value="">All Status</option>
            <option value="active">Active</option>
            <option value="suspended">Suspended</option>
          </select>
        </div>

        {/* Table */}
        <div className="card">
          <DataTable
            columns={columns}
            data={data?.data || []}
            keyExtractor={(u) => u.id}
            isLoading={isLoading}
            onRowClick={(user) => router.push(`/users/${user.id}`)}
            emptyMessage="No users found"
          />

          {/* Pagination */}
          {data?.meta && (
            <div className="flex items-center justify-between border-t border-gray-200 px-6 py-4">
              <p className="text-sm text-gray-500">
                Showing {data.meta.from} to {data.meta.to} of {data.meta.total}
              </p>
              <div className="flex gap-2">
                <button
                  onClick={() => setPage(page - 1)}
                  disabled={page === 1}
                  className="btn btn-secondary"
                >
                  Previous
                </button>
                <button
                  onClick={() => setPage(page + 1)}
                  disabled={page === data.meta.last_page}
                  className="btn btn-secondary"
                >
                  Next
                </button>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
