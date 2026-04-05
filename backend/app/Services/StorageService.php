<?php

namespace App\Services;

use GuzzleHttp\Client;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class StorageService
{
    protected Client $client;
    protected string $baseUrl;
    protected string $bucket;

    public function __construct()
    {
        $this->baseUrl = config('services.supabase.url') . '/storage/v1';
        $this->bucket = config('autowala.storage.documents_bucket');
        
        $this->client = new Client([
            'headers' => [
                'Authorization' => 'Bearer ' . config('services.supabase.service_key'),
                'apikey' => config('services.supabase.key'),
            ],
        ]);
    }

    public function upload(UploadedFile $file, string $folder, ?string $filename = null): array
    {
        $filename = $filename ?? Str::uuid() . '.' . $file->getClientOriginalExtension();
        $path = trim($folder, '/') . '/' . $filename;

        try {
            $response = $this->client->post(
                "{$this->baseUrl}/object/{$this->bucket}/{$path}",
                [
                    'headers' => [
                        'Content-Type' => $file->getMimeType(),
                    ],
                    'body' => file_get_contents($file->getRealPath()),
                ]
            );

            if ($response->getStatusCode() === 200) {
                return [
                    'success' => true,
                    'path' => $path,
                    'url' => $this->getPublicUrl($path),
                    'filename' => $filename,
                    'size' => $file->getSize(),
                ];
            }

            return [
                'success' => false,
                'message' => 'Upload failed',
            ];
        } catch (\Exception $e) {
            Log::error('Storage upload failed', [
                'path' => $path,
                'error' => $e->getMessage(),
            ]);

            return [
                'success' => false,
                'message' => 'Upload failed: ' . $e->getMessage(),
            ];
        }
    }

    public function delete(string $path): bool
    {
        try {
            $response = $this->client->delete(
                "{$this->baseUrl}/object/{$this->bucket}/{$path}"
            );

            return $response->getStatusCode() === 200;
        } catch (\Exception $e) {
            Log::error('Storage delete failed', [
                'path' => $path,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }

    public function getPublicUrl(string $path): string
    {
        return config('services.supabase.url') . 
               "/storage/v1/object/public/{$this->bucket}/{$path}";
    }

    public function getSignedUrl(string $path, int $expiresIn = 3600): ?string
    {
        try {
            $response = $this->client->post(
                "{$this->baseUrl}/object/sign/{$this->bucket}/{$path}",
                [
                    'json' => ['expiresIn' => $expiresIn],
                ]
            );

            $data = json_decode($response->getBody()->getContents(), true);
            
            return config('services.supabase.url') . 
                   "/storage/v1" . ($data['signedURL'] ?? '');
        } catch (\Exception $e) {
            Log::error('Signed URL generation failed', [
                'path' => $path,
                'error' => $e->getMessage(),
            ]);

            return null;
        }
    }
}
