<?php

namespace App\Services;

use App\Models\Rider;
use App\Models\Route;
use Illuminate\Support\Facades\DB;

class GeoService
{
    public function findNearbyRiders(float $lat, float $lng, int $radiusMeters = 5000): array
    {
        $result = DB::select("SELECT * FROM find_nearby_riders(?, ?, ?)", [
            $lat,
            $lng,
            $radiusMeters,
        ]);

        return array_map(fn($row) => (array) $row, $result);
    }

    public function findRoutesNearPoint(float $lat, float $lng, int $radiusMeters = 2000): array
    {
        $result = DB::select("SELECT * FROM find_routes_near_point(?, ?, ?)", [
            $lat,
            $lng,
            $radiusMeters,
        ]);

        return array_map(fn($row) => (array) $row, $result);
    }

    public function calculateDistance(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $result = DB::selectOne("
            SELECT ST_Distance(
                ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
                ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography
            ) as distance
        ", [$lng1, $lat1, $lng2, $lat2]);

        return $result->distance ?? 0;
    }

    public function calculateETA(float $distanceMeters, float $avgSpeedKmh = 20): int
    {
        // Average auto speed in city: 20 km/h
        $distanceKm = $distanceMeters / 1000;
        $timeHours = $distanceKm / $avgSpeedKmh;
        return (int) ceil($timeHours * 60); // Return minutes
    }

    public function encodeGeohash(float $lat, float $lng, int $precision = 6): string
    {
        $base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
        $latRange = [-90.0, 90.0];
        $lngRange = [-180.0, 180.0];
        $hash = '';
        $bit = 0;
        $ch = 0;
        $even = true;

        while (strlen($hash) < $precision) {
            if ($even) {
                $mid = ($lngRange[0] + $lngRange[1]) / 2;
                if ($lng >= $mid) {
                    $ch |= (1 << (4 - $bit));
                    $lngRange[0] = $mid;
                } else {
                    $lngRange[1] = $mid;
                }
            } else {
                $mid = ($latRange[0] + $latRange[1]) / 2;
                if ($lat >= $mid) {
                    $ch |= (1 << (4 - $bit));
                    $latRange[0] = $mid;
                } else {
                    $latRange[1] = $mid;
                }
            }

            $even = !$even;

            if ($bit < 4) {
                $bit++;
            } else {
                $hash .= $base32[$ch];
                $bit = 0;
                $ch = 0;
            }
        }

        return $hash;
    }

    public function getNeighborGeohashes(string $geohash): array
    {
        // Simplified neighbor calculation
        // In production, use a proper geohash library
        $neighbors = [$geohash];
        
        // This is a simplified version - real implementation should calculate actual neighbors
        $precision = strlen($geohash);
        if ($precision > 1) {
            $prefix = substr($geohash, 0, -1);
            $base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
            $lastChar = substr($geohash, -1);
            $idx = strpos($base32, $lastChar);
            
            if ($idx > 0) {
                $neighbors[] = $prefix . $base32[$idx - 1];
            }
            if ($idx < 31) {
                $neighbors[] = $prefix . $base32[$idx + 1];
            }
        }

        return $neighbors;
    }

    public function isPointNearRoute(float $lat, float $lng, string $routeId, int $radiusMeters = 500): bool
    {
        $result = DB::selectOne("
            SELECT ST_DWithin(
                route_line,
                ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
                ?
            ) as is_near
            FROM routes WHERE id = ?
        ", [$lng, $lat, $radiusMeters, $routeId]);

        return $result?->is_near ?? false;
    }
}
