'use client';

import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import dynamic from 'next/dynamic';
import {
  Users,
  Bike,
  Clock,
  AlertTriangle,
  Star,
  MapPin,
} from 'lucide-react';
import { Sidebar } from '@/components/sidebar';
import { StatCard } from '@/components/stat-card';
import { DataTable } from '@/components/data-table';
import { StatusBadge } from '@/components/badge';
import { dashboardApi, DashboardStats, Rider } from '@/lib/api';
import { formatRelative } from '@/lib/utils';

// Dynamically import map to avoid SSR issues
const LiveMap = dynamic(() => import('./live-map'), {
  ssr: false,
  loading: () => (
    <div className="flex h-96 items-center justify-center rounded-xl bg-gray-100">
      <div className="h-8 w-8 animate-spin rounded-full border-4 border-gray-200 border-t-accent" />
    </div>
  ),
});

export default function DashboardPage() {
  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: dashboardApi.getStats,
    refetchInterval: 30000,
  });

  const { data: onlineRiders, isLoading: ridersLoading } = useQuery({
    queryKey: ['online-riders'],
    queryFn: dashboardApi.getOnlineRiders,
    refetchInterval: 10000,
  });

  const riderColumns = [
    {
      key: 'name',
      header: 'Rider',
      render: (rider: Rider) => (
        <div className="flex items-center gap-3">
          <div className="flex h-8 w-8 items-center justify-center rounded-full bg-gray-100 text-sm font-medium">
            {rider.user?.name?.[0] || 'R'}
          </div>
          <div>
            <p className="font-medium">{rider.user?.name}</p>
            <p className="text-xs text-gray-500">{rider.vehicle?.vehicle_number}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'rating',
      header: 'Rating',
      render: (rider: Rider) => (
        <div className="flex items-center gap-1">
          <Star className="h-4 w-4 text-yellow-400 fill-yellow-400" />
          <span>{rider.rating_avg?.toFixed(1) || '-'}</span>
        </div>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (rider: Rider) => (
        <StatusBadge status={rider.is_online ? 'active' : 'offline'} />
      ),
    },
  ];

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />

      <main className="ml-64 flex-1 p-8">
        <div className="mb-8">
          <h1 className="text-2xl font-bold">Dashboard</h1>
          <p className="text-gray-500">Overview of your platform</p>
        </div>

        {/* Stats Grid */}
        <div className="mb-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard
            title="Total Users"
            value={stats?.total_users || 0}
            icon={Users}
          />
          <StatCard
            title="Active Riders"
            value={stats?.active_riders || 0}
            icon={Bike}
          />
          <StatCard
            title="Rides Today"
            value={stats?.rides_today || 0}
            icon={Clock}
          />
          <StatCard
            title="Pending KYC"
            value={stats?.pending_kyc || 0}
            icon={AlertTriangle}
          />
        </div>

        {/* Map and Online Riders */}
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
          {/* Live Map */}
          <div className="card lg:col-span-2">
            <div className="card-header flex items-center justify-between">
              <div className="flex items-center gap-2">
                <MapPin className="h-5 w-5 text-gray-400" />
                <h2 className="font-semibold">Live Map</h2>
              </div>
              <span className="text-sm text-gray-500">
                {onlineRiders?.length || 0} online
              </span>
            </div>
            <div className="h-96">
              <LiveMap riders={onlineRiders || []} />
            </div>
          </div>

          {/* Online Riders List */}
          <div className="card">
            <div className="card-header">
              <h2 className="font-semibold">Online Riders</h2>
            </div>
            <DataTable
              columns={riderColumns}
              data={onlineRiders?.slice(0, 10) || []}
              keyExtractor={(r) => r.id}
              isLoading={ridersLoading}
              emptyMessage="No riders online"
            />
          </div>
        </div>

        {/* Additional Stats */}
        <div className="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-3">
          <div className="card">
            <div className="card-body text-center">
              <Star className="mx-auto h-8 w-8 text-yellow-400" />
              <p className="mt-2 text-3xl font-bold">
                {stats?.average_rating?.toFixed(1) || '-'}
              </p>
              <p className="text-sm text-gray-500">Average Rating</p>
            </div>
          </div>
          <div className="card">
            <div className="card-body text-center">
              <Clock className="mx-auto h-8 w-8 text-blue-500" />
              <p className="mt-2 text-3xl font-bold">{stats?.total_rides || 0}</p>
              <p className="text-sm text-gray-500">Total Rides</p>
            </div>
          </div>
          <div className="card">
            <div className="card-body text-center">
              <AlertTriangle className="mx-auto h-8 w-8 text-orange-500" />
              <p className="mt-2 text-3xl font-bold">
                {stats?.complaints_pending || 0}
              </p>
              <p className="text-sm text-gray-500">Pending Complaints</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
