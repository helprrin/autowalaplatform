'use client';

import { useEffect, useRef } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Rider } from '@/lib/api';

interface LiveMapProps {
  riders: Rider[];
}

export default function LiveMap({ riders }: LiveMapProps) {
  const mapRef = useRef<L.Map | null>(null);
  const markersRef = useRef<Map<string, L.Marker>>(new Map());

  useEffect(() => {
    // Initialize map centered on India
    if (!mapRef.current) {
      mapRef.current = L.map('live-map', {
        center: [20.5937, 78.9629],
        zoom: 5,
        zoomControl: false,
      });

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
      }).addTo(mapRef.current);

      L.control.zoom({ position: 'bottomright' }).addTo(mapRef.current);
    }

    return () => {
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }
    };
  }, []);

  useEffect(() => {
    if (!mapRef.current) return;

    // Custom auto-rickshaw icon
    const autoIcon = L.divIcon({
      className: 'auto-marker',
      html: `
        <div style="
          background: #10B981;
          width: 32px;
          height: 32px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          border: 3px solid white;
          box-shadow: 0 2px 8px rgba(0,0,0,0.3);
        ">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="white">
            <path d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.21.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z"/>
          </svg>
        </div>
      `,
      iconSize: [32, 32],
      iconAnchor: [16, 16],
    });

    // Update markers
    const currentIds = new Set<string>();

    riders.forEach((rider: any) => {
      if (rider.latitude && rider.longitude) {
        currentIds.add(rider.id);

        if (markersRef.current.has(rider.id)) {
          // Update existing marker position
          markersRef.current.get(rider.id)!.setLatLng([
            rider.latitude,
            rider.longitude,
          ]);
        } else {
          // Create new marker
          const marker = L.marker([rider.latitude, rider.longitude], {
            icon: autoIcon,
          }).addTo(mapRef.current!);

          marker.bindPopup(`
            <div style="text-align: center; min-width: 120px;">
              <strong>${rider.user?.name || 'Rider'}</strong><br/>
              <small>${rider.vehicle?.vehicle_number || ''}</small><br/>
              <span style="color: #10B981;">● Online</span>
            </div>
          `);

          markersRef.current.set(rider.id, marker);
        }
      }
    });

    // Remove old markers
    markersRef.current.forEach((marker, id) => {
      if (!currentIds.has(id)) {
        marker.remove();
        markersRef.current.delete(id);
      }
    });

    // Fit bounds if riders exist
    if (riders.length > 0 && mapRef.current) {
      const validRiders = riders.filter((r: any) => r.latitude && r.longitude);
      if (validRiders.length > 0) {
        const bounds = L.latLngBounds(
          validRiders.map((r: any) => [r.latitude, r.longitude])
        );
        mapRef.current.fitBounds(bounds, { padding: [50, 50] });
      }
    }
  }, [riders]);

  return <div id="live-map" className="h-full w-full rounded-b-xl" />;
}
