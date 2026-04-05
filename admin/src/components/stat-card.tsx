'use client';

import { LucideIcon } from 'lucide-react';
import { cn } from '@/lib/utils';

interface StatCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  change?: string;
  trend?: 'up' | 'down';
  className?: string;
}

export function StatCard({
  title,
  value,
  icon: Icon,
  change,
  trend,
  className,
}: StatCardProps) {
  return (
    <div className={cn('card', className)}>
      <div className="card-body">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-gray-500">{title}</p>
            <p className="mt-1 text-3xl font-bold">{value}</p>
            {change && (
              <p
                className={cn(
                  'mt-1 text-sm',
                  trend === 'up' ? 'text-green-600' : 'text-red-600'
                )}
              >
                {trend === 'up' ? '↑' : '↓'} {change}
              </p>
            )}
          </div>
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-gray-100">
            <Icon className="h-6 w-6 text-gray-600" />
          </div>
        </div>
      </div>
    </div>
  );
}
