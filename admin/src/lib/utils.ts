import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { format, formatDistanceToNow } from 'date-fns';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatDate(date: string | Date) {
  return format(new Date(date), 'MMM d, yyyy');
}

export function formatDateTime(date: string | Date) {
  return format(new Date(date), 'MMM d, yyyy h:mm a');
}

export function formatRelative(date: string | Date) {
  return formatDistanceToNow(new Date(date), { addSuffix: true });
}

export function formatPhone(phone: string) {
  if (phone.length === 10) {
    return `+91 ${phone.slice(0, 5)} ${phone.slice(5)}`;
  }
  return phone;
}

export function getStatusColor(status: string) {
  const colors: Record<string, string> = {
    // KYC/Rider statuses
    pending: 'warning',
    approved: 'success',
    rejected: 'error',
    suspended: 'error',
    submitted: 'info',
    verified: 'success',
    // User statuses
    active: 'success',
    deleted: 'error',
    // Complaint statuses
    investigating: 'info',
    resolved: 'success',
    dismissed: 'error',
  };
  return colors[status] || 'info';
}

export function getInitials(name: string) {
  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}
