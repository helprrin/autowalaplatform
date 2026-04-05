'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { MessageSquare, ChevronRight } from 'lucide-react';
import { Sidebar } from '@/components/sidebar';
import { DataTable } from '@/components/data-table';
import { StatusBadge } from '@/components/badge';
import { complaintsApi, Complaint } from '@/lib/api';
import { formatDate, formatRelative } from '@/lib/utils';

export default function ComplaintsPage() {
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [selectedComplaint, setSelectedComplaint] = useState<Complaint | null>(
    null
  );
  const [adminNotes, setAdminNotes] = useState('');
  const [newStatus, setNewStatus] = useState('');
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['complaints', statusFilter],
    queryFn: () => complaintsApi.list({ status: statusFilter || undefined }),
  });

  const updateMutation = useMutation({
    mutationFn: ({
      id,
      status,
      notes,
    }: {
      id: string;
      status: string;
      notes?: string;
    }) => complaintsApi.updateStatus(id, status, notes),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['complaints'] });
      setSelectedComplaint(null);
      setAdminNotes('');
      setNewStatus('');
    },
  });

  const columns = [
    {
      key: 'id',
      header: 'ID',
      render: (c: Complaint) => (
        <span className="font-mono text-sm text-gray-500">
          #{c.id.slice(0, 8)}
        </span>
      ),
    },
    {
      key: 'type',
      header: 'Type',
      render: (c: Complaint) => (
        <span className="capitalize">{c.type.replace('_', ' ')}</span>
      ),
    },
    {
      key: 'description',
      header: 'Description',
      render: (c: Complaint) => (
        <p className="max-w-xs truncate">{c.description}</p>
      ),
    },
    {
      key: 'from',
      header: 'From',
      render: (c: Complaint) => (
        <div>
          <p className="font-medium">
            {c.user?.name || c.rider?.user?.name || '-'}
          </p>
          <p className="text-xs text-gray-500">
            {c.user ? 'User' : c.rider ? 'Rider' : '-'}
          </p>
        </div>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      render: (c: Complaint) => <StatusBadge status={c.status} />,
    },
    {
      key: 'created',
      header: 'Created',
      render: (c: Complaint) => formatRelative(c.created_at),
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
          <h1 className="text-2xl font-bold">Complaints</h1>
          <p className="text-gray-500">Manage user and rider complaints</p>
        </div>

        {/* Filters */}
        <div className="mb-6 flex items-center gap-4">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="rounded-lg border border-gray-300 px-4 py-2 text-sm focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent"
          >
            <option value="">All Status</option>
            <option value="pending">Pending</option>
            <option value="investigating">Investigating</option>
            <option value="resolved">Resolved</option>
            <option value="dismissed">Dismissed</option>
          </select>
        </div>

        {/* Table */}
        <div className="card">
          <DataTable
            columns={columns}
            data={data?.data || []}
            keyExtractor={(c) => c.id}
            isLoading={isLoading}
            onRowClick={(c) => {
              setSelectedComplaint(c);
              setNewStatus(c.status);
              setAdminNotes(c.admin_notes || '');
            }}
            emptyMessage="No complaints found"
          />
        </div>

        {/* Detail Modal */}
        {selectedComplaint && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
            <div className="w-full max-w-lg rounded-xl bg-white p-6">
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-semibold">Complaint Details</h3>
                <button
                  onClick={() => setSelectedComplaint(null)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ×
                </button>
              </div>

              <div className="mb-4 space-y-4">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-500">Type</span>
                  <span className="capitalize">
                    {selectedComplaint.type.replace('_', ' ')}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-500">Status</span>
                  <StatusBadge status={selectedComplaint.status} />
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-500">Created</span>
                  <span>{formatDate(selectedComplaint.created_at)}</span>
                </div>
                <div>
                  <span className="text-sm text-gray-500">Description</span>
                  <p className="mt-1 rounded-lg bg-gray-50 p-3 text-sm">
                    {selectedComplaint.description}
                  </p>
                </div>
              </div>

              <div className="mb-4">
                <label className="mb-1 block text-sm font-medium">
                  Update Status
                </label>
                <select
                  value={newStatus}
                  onChange={(e) => setNewStatus(e.target.value)}
                  className="w-full rounded-lg border border-gray-300 px-4 py-2 text-sm focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent"
                >
                  <option value="pending">Pending</option>
                  <option value="investigating">Investigating</option>
                  <option value="resolved">Resolved</option>
                  <option value="dismissed">Dismissed</option>
                </select>
              </div>

              <div className="mb-4">
                <label className="mb-1 block text-sm font-medium">
                  Admin Notes
                </label>
                <textarea
                  value={adminNotes}
                  onChange={(e) => setAdminNotes(e.target.value)}
                  placeholder="Add notes about this complaint..."
                  className="w-full rounded-lg border border-gray-300 p-3 text-sm focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent"
                  rows={3}
                />
              </div>

              <div className="flex gap-4">
                <button
                  onClick={() => setSelectedComplaint(null)}
                  className="btn btn-secondary flex-1"
                >
                  Cancel
                </button>
                <button
                  onClick={() =>
                    updateMutation.mutate({
                      id: selectedComplaint.id,
                      status: newStatus,
                      notes: adminNotes,
                    })
                  }
                  disabled={updateMutation.isPending}
                  className="btn btn-primary flex-1"
                >
                  Update
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
