'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { Search, Filter, ChevronRight } from 'lucide-react';
import { Sidebar } from '@/components/sidebar';
import { DataTable } from '@/components/data-table';
import { StatusBadge } from '@/components/badge';
import { ridersApi, Rider } from '@/lib/api';
import { formatDate, formatPhone } from '@/lib/utils';

export default function RidersPage() {
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [page, setPage] = useState(1);
  const router = useRouter();
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['riders', statusFilter, page],
    queryFn: () => ridersApi.list({ status: statusFilter || undefined, page }),
  });

  const columns = [
    {
      key: 'rider',
      header: 'Rider',
      render: (rider: Rider) => (
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gray-100 text-sm font-medium">
            {rider.user?.name?.[0] || 'R'}
          </div>
          <div>
            <p className="font-medium">{rider.user?.name}</p>
            <p className="text-sm text-gray-500">
              {formatPhone(rider.user?.phone || '')}
            </p>
          </div>
        </div>
      ),
    },
    {
      key: 'vehicle',
      header: 'Vehicle',
      render: (rider: Rider) => (
        <div>
          <p className="font-medium">{rider.vehicle?.vehicle_number || '-'}</p>
          <p className="text-sm text-gray-500">{rider.vehicle?.color}</p>
        </div>
      ),
    },
    {
      key: 'license',
      header: 'License',
      render: (rider: Rider) => rider.license_number || '-',
    },
    {
      key: 'status',
      header: 'Status',
      render: (rider: Rider) => <StatusBadge status={rider.status} />,
    },
    {
      key: 'kyc',
      header: 'KYC',
      render: (rider: Rider) => <StatusBadge status={rider.kyc_status} />,
    },
    {
      key: 'rating',
      header: 'Rating',
      render: (rider: Rider) => (
        <div className="flex items-center gap-1">
          <span className="text-yellow-500">★</span>
          <span>{rider.rating_avg?.toFixed(1) || '-'}</span>
        </div>
      ),
    },
    {
      key: 'rides',
      header: 'Rides',
      render: (rider: Rider) => rider.total_rides || 0,
    },
    {
      key: 'created',
      header: 'Joined',
      render: (rider: Rider) => formatDate(rider.created_at),
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
        <div className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">Riders</h1>
            <p className="text-gray-500">Manage all registered riders</p>
          </div>
        </div>

        {/* Filters */}
        <div className="mb-6 flex items-center gap-4">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              placeholder="Search riders..."
              className="w-full rounded-lg border border-gray-300 py-2 pl-10 pr-4 text-sm focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent"
            />
          </div>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="rounded-lg border border-gray-300 px-4 py-2 text-sm focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent"
          >
            <option value="">All Status</option>
            <option value="pending">Pending</option>
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
            <option value="suspended">Suspended</option>
          </select>
        </div>

        {/* Table */}
        <div className="card">
          <DataTable
            columns={columns}
            data={data?.data || []}
            keyExtractor={(r) => r.id}
            isLoading={isLoading}
            onRowClick={(rider) => router.push(`/riders/${rider.id}`)}
            emptyMessage="No riders found"
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
