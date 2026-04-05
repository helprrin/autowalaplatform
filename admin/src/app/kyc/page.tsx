'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import Image from 'next/image';
import {
  CheckCircle,
  XCircle,
  FileText,
  User,
  Car,
  CreditCard,
} from 'lucide-react';
import { Sidebar } from '@/components/sidebar';
import { StatusBadge } from '@/components/badge';
import { kycApi, ridersApi, Rider, Document } from '@/lib/api';
import { formatDate, formatPhone } from '@/lib/utils';

export default function KYCPage() {
  const [selectedRider, setSelectedRider] = useState<Rider | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [showRejectModal, setShowRejectModal] = useState(false);
  const queryClient = useQueryClient();

  const { data: pendingRiders, isLoading } = useQuery({
    queryKey: ['kyc-pending'],
    queryFn: kycApi.getPending,
  });

  const approveMutation = useMutation({
    mutationFn: kycApi.approve,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['kyc-pending'] });
      setSelectedRider(null);
    },
  });

  const rejectMutation = useMutation({
    mutationFn: ({ riderId, reason }: { riderId: string; reason: string }) =>
      kycApi.reject(riderId, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['kyc-pending'] });
      setSelectedRider(null);
      setShowRejectModal(false);
      setRejectReason('');
    },
  });

  const { data: documents } = useQuery({
    queryKey: ['rider-documents', selectedRider?.id],
    queryFn: () =>
      selectedRider ? ridersApi.getDocuments(selectedRider.id) : null,
    enabled: !!selectedRider,
  });

  const getDocIcon = (type: string) => {
    switch (type) {
      case 'license':
        return CreditCard;
      case 'registration':
        return Car;
      case 'photo':
        return User;
      default:
        return FileText;
    }
  };

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />

      <main className="ml-64 flex-1 p-8">
        <div className="mb-8">
          <h1 className="text-2xl font-bold">KYC Approvals</h1>
          <p className="text-gray-500">Review and approve rider verifications</p>
        </div>

        <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
          {/* Pending List */}
          <div className="lg:col-span-1">
            <div className="card">
              <div className="card-header">
                <h2 className="font-semibold">Pending Reviews</h2>
                <span className="text-sm text-gray-500">
                  {pendingRiders?.length || 0} pending
                </span>
              </div>

              {isLoading ? (
                <div className="flex items-center justify-center py-12">
                  <div className="h-8 w-8 animate-spin rounded-full border-4 border-gray-200 border-t-accent" />
                </div>
              ) : pendingRiders?.length === 0 ? (
                <div className="py-12 text-center text-gray-500">
                  No pending KYC reviews
                </div>
              ) : (
                <div className="divide-y">
                  {pendingRiders?.map((rider) => (
                    <button
                      key={rider.id}
                      onClick={() => setSelectedRider(rider)}
                      className={`w-full p-4 text-left hover:bg-gray-50 ${
                        selectedRider?.id === rider.id ? 'bg-blue-50' : ''
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gray-100 text-sm font-medium">
                          {rider.user?.name?.[0] || 'R'}
                        </div>
                        <div className="flex-1">
                          <p className="font-medium">{rider.user?.name}</p>
                          <p className="text-sm text-gray-500">
                            {formatDate(rider.created_at)}
                          </p>
                        </div>
                        <StatusBadge status={rider.kyc_status} />
                      </div>
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Detail Panel */}
          <div className="lg:col-span-2">
            {selectedRider ? (
              <div className="space-y-6">
                {/* Rider Info */}
                <div className="card">
                  <div className="card-header">
                    <h2 className="font-semibold">Rider Information</h2>
                  </div>
                  <div className="card-body">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <p className="text-sm text-gray-500">Name</p>
                        <p className="font-medium">{selectedRider.user?.name}</p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-500">Phone</p>
                        <p className="font-medium">
                          {formatPhone(selectedRider.user?.phone || '')}
                        </p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-500">License Number</p>
                        <p className="font-medium">
                          {selectedRider.license_number || '-'}
                        </p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-500">Vehicle Number</p>
                        <p className="font-medium">
                          {selectedRider.vehicle?.vehicle_number || '-'}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Documents */}
                <div className="card">
                  <div className="card-header">
                    <h2 className="font-semibold">Documents</h2>
                  </div>
                  <div className="card-body">
                    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                      {documents?.map((doc) => {
                        const Icon = getDocIcon(doc.type);
                        return (
                          <div
                            key={doc.id}
                            className="rounded-lg border border-gray-200 p-4"
                          >
                            <div className="mb-3 flex items-center justify-between">
                              <div className="flex items-center gap-2">
                                <Icon className="h-5 w-5 text-gray-400" />
                                <span className="font-medium capitalize">
                                  {doc.type.replace('_', ' ')}
                                </span>
                              </div>
                              <StatusBadge status={doc.status} />
                            </div>
                            <a
                              href={doc.file_url}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="block aspect-video overflow-hidden rounded-lg bg-gray-100"
                            >
                              <img
                                src={doc.file_url}
                                alt={doc.type}
                                className="h-full w-full object-cover"
                              />
                            </a>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex gap-4">
                  <button
                    onClick={() => approveMutation.mutate(selectedRider.id)}
                    disabled={approveMutation.isPending}
                    className="btn btn-success flex-1"
                  >
                    <CheckCircle className="mr-2 h-5 w-5" />
                    Approve KYC
                  </button>
                  <button
                    onClick={() => setShowRejectModal(true)}
                    className="btn btn-danger flex-1"
                  >
                    <XCircle className="mr-2 h-5 w-5" />
                    Reject
                  </button>
                </div>
              </div>
            ) : (
              <div className="card">
                <div className="flex flex-col items-center justify-center py-24 text-gray-500">
                  <FileText className="mb-4 h-12 w-12" />
                  <p>Select a rider to review their KYC documents</p>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Reject Modal */}
        {showRejectModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
            <div className="w-full max-w-md rounded-xl bg-white p-6">
              <h3 className="mb-4 text-lg font-semibold">Reject KYC</h3>
              <textarea
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                placeholder="Enter reason for rejection..."
                className="mb-4 w-full rounded-lg border border-gray-300 p-3 text-sm focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent"
                rows={4}
              />
              <div className="flex gap-4">
                <button
                  onClick={() => setShowRejectModal(false)}
                  className="btn btn-secondary flex-1"
                >
                  Cancel
                </button>
                <button
                  onClick={() =>
                    selectedRider &&
                    rejectMutation.mutate({
                      riderId: selectedRider.id,
                      reason: rejectReason,
                    })
                  }
                  disabled={!rejectReason || rejectMutation.isPending}
                  className="btn btn-danger flex-1"
                >
                  Reject
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
