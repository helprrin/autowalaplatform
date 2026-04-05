# Supabase Setup Script
# Run these in Supabase SQL Editor

-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pg_trgm for text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Create storage buckets (do this in Supabase dashboard)
-- 1. avatars (public)
-- 2. documents (private)
-- 3. vehicles (private)

-- Storage policies
-- Run after creating buckets

-- Avatars bucket - public read
CREATE POLICY "Public read avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Avatars bucket - authenticated upload
CREATE POLICY "Auth upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars'
  AND auth.role() = 'authenticated'
);

-- Documents bucket - owner only
CREATE POLICY "Owner access documents"
ON storage.objects FOR ALL
USING (
  bucket_id = 'documents'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Vehicles bucket - owner only
CREATE POLICY "Owner access vehicles"
ON storage.objects FOR ALL
USING (
  bucket_id = 'vehicles'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Then run the main schema from database/001_schema.sql
