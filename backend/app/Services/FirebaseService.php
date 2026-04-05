<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Database;
use Illuminate\Support\Facades\Log;

class FirebaseService
{
    protected ?Database $database = null;

    public function __construct()
    {
        try {
            $factory = (new Factory)
                ->withServiceAccount(config('firebase.credentials'))
                ->withDatabaseUri(config('firebase.database_url'));

            $this->database = $factory->createDatabase();
        } catch (\Exception $e) {
            Log::error('Firebase initialization failed', [
                'error' => $e->getMessage(),
            ]);
        }
    }

    public function updateRiderLocation(
        string $riderId,
        float $lat,
        float $lng,
        ?float $heading = null,
        ?float $speed = null,
        ?float $accuracy = null
    ): bool {
        if (!$this->database) {
            return false;
        }

        try {
            $this->database->getReference("riders/{$riderId}/location")->set([
                'latitude' => $lat,
                'longitude' => $lng,
                'heading' => $heading ?? 0,
                'speed' => $speed ?? 0,
                'accuracy' => $accuracy ?? 0,
                'timestamp' => ['.sv' => 'timestamp'],
            ]);

            return true;
        } catch (\Exception $e) {
            Log::error('Firebase location update failed', [
                'rider_id' => $riderId,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }

    public function updateRiderStatus(string $riderId, bool $isOnline, bool $isAvailable): bool
    {
        if (!$this->database) {
            return false;
        }

        try {
            $this->database->getReference("riders/{$riderId}/status")->set([
                'isOnline' => $isOnline,
                'isAvailable' => $isAvailable,
                'lastSeen' => ['.sv' => 'timestamp'],
            ]);

            return true;
        } catch (\Exception $e) {
            Log::error('Firebase status update failed', [
                'rider_id' => $riderId,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }

    public function updateRiderProfile(string $riderId, array $profile): bool
    {
        if (!$this->database) {
            return false;
        }

        try {
            $this->database->getReference("riders/{$riderId}/profile")->set($profile);
            return true;
        } catch (\Exception $e) {
            Log::error('Firebase profile update failed', [
                'rider_id' => $riderId,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }

    public function setRiderRoute(string $riderId, ?array $route): bool
    {
        if (!$this->database) {
            return false;
        }

        try {
            if ($route) {
                $this->database->getReference("riders/{$riderId}/currentRoute")->set($route);
            } else {
                $this->database->getReference("riders/{$riderId}/currentRoute")->remove();
            }
            return true;
        } catch (\Exception $e) {
            Log::error('Firebase route update failed', [
                'rider_id' => $riderId,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }

    public function removeRider(string $riderId): bool
    {
        if (!$this->database) {
            return false;
        }

        try {
            $this->database->getReference("riders/{$riderId}")->remove();
            return true;
        } catch (\Exception $e) {
            Log::error('Firebase rider removal failed', [
                'rider_id' => $riderId,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }

    public function getRiderLocation(string $riderId): ?array
    {
        if (!$this->database) {
            return null;
        }

        try {
            $snapshot = $this->database->getReference("riders/{$riderId}/location")->getSnapshot();
            return $snapshot->exists() ? $snapshot->getValue() : null;
        } catch (\Exception $e) {
            Log::error('Firebase get location failed', [
                'rider_id' => $riderId,
                'error' => $e->getMessage(),
            ]);

            return null;
        }
    }

    public function createTrackingSession(string $sessionId, string $riderId, string $userId): bool
    {
        if (!$this->database) {
            return false;
        }

        try {
            $this->database->getReference("activeSessions/{$sessionId}")->set([
                'riderId' => $riderId,
                'userId' => $userId,
                'startedAt' => ['.sv' => 'timestamp'],
                'status' => 'tracking',
            ]);

            return true;
        } catch (\Exception $e) {
            Log::error('Firebase session creation failed', [
                'session_id' => $sessionId,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }

    public function endTrackingSession(string $sessionId): bool
    {
        if (!$this->database) {
            return false;
        }

        try {
            $this->database->getReference("activeSessions/{$sessionId}")->remove();
            return true;
        } catch (\Exception $e) {
            Log::error('Firebase session end failed', [
                'session_id' => $sessionId,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }
}
