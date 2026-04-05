# AutoWala - Deployment Guide

## Overview

This guide covers deploying AutoWala to production:
- **Backend (Laravel)** → Render
- **Admin Panel (Next.js)** → Vercel
- **Database (PostgreSQL)** → Supabase
- **Real-time** → Firebase

---

## 1. Supabase Setup

### Create Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note your:
   - Project URL: `https://xxxxx.supabase.co`
   - API Key (anon): `eyJhbGciOiJIUzI1NiIs...`
   - Database Password

### Enable PostGIS

1. Go to **Database** → **Extensions**
2. Search for `postgis` and enable it

### Run Schema

1. Go to **SQL Editor**
2. Copy contents of `database/001_schema.sql`
3. Run the migration

### Configure Storage

1. Go to **Storage**
2. Create buckets:
   - `avatars` (public)
   - `documents` (private - requires auth)
   - `vehicles` (private)

3. Set policies for each bucket:

```sql
-- Public read for avatars
CREATE POLICY "Public read avatars" ON storage.objects
FOR SELECT USING (bucket_id = 'avatars');

-- Authenticated upload for avatars
CREATE POLICY "Auth upload avatars" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- Private documents (owner only)
CREATE POLICY "Owner access documents" ON storage.objects
FOR ALL USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);
```

### Get Connection String

1. Go to **Settings** → **Database**
2. Copy the **Connection String** (URI format)
3. Format: `postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres`

---

## 2. Firebase Setup

### Create Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project: `autowala`
3. Enable **Realtime Database**

### Configure Rules

1. Go to **Realtime Database** → **Rules**
2. Paste contents of `database/firebase_rules.json`

### Get Config

1. Go to **Project Settings** → **General**
2. Add apps:
   - Android: `com.autowala.user`, `com.autowala.rider`
   - iOS: `com.autowala.user`, `com.autowala.rider`
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

### Service Account (for backend)

1. Go to **Project Settings** → **Service Accounts**
2. Generate new private key
3. Save as `firebase-credentials.json`

---

## 3. Laravel Backend on Render

### Prepare Repository

1. Push backend to Git repository
2. Ensure `Procfile` exists:

```
web: php artisan serve --host=0.0.0.0 --port=$PORT
release: php artisan migrate --force
```

### Create Render Service

1. Go to [render.com](https://render.com)
2. Create **Web Service**
3. Connect your repository
4. Select branch: `main`
5. Set root directory: `backend`

### Build Settings

- **Runtime**: PHP
- **Build Command**: 
  ```
  composer install --no-dev --optimize-autoloader
  ```
- **Start Command**:
  ```
  php artisan config:cache && php artisan route:cache && php artisan serve --host=0.0.0.0 --port=$PORT
  ```

### Environment Variables

```env
APP_NAME=AutoWala
APP_ENV=production
APP_KEY=base64:GENERATE_NEW_KEY
APP_DEBUG=false
APP_URL=https://api.autowala.in

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=pgsql
DB_HOST=db.xxxxx.supabase.co
DB_PORT=5432
DB_DATABASE=postgres
DB_USERNAME=postgres
DB_PASSWORD=your_supabase_password

CACHE_DRIVER=file
QUEUE_CONNECTION=database
SESSION_DRIVER=file

SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=your_supabase_anon_key
SUPABASE_SERVICE_KEY=your_supabase_service_key

FIREBASE_CREDENTIALS=firebase-credentials.json
FIREBASE_DATABASE_URL=https://autowala-default-rtdb.firebaseio.com

OTP_PROVIDER=twilio
TWILIO_SID=your_twilio_sid
TWILIO_TOKEN=your_twilio_token
TWILIO_FROM=+1234567890
```

### Custom Domain

1. Add custom domain: `api.autowala.in`
2. Update DNS records as instructed

### Cron Jobs (Render Cron)

Create cron job for Laravel scheduler:
- **Schedule**: `* * * * *`
- **Command**: `cd /opt/render/project/src/backend && php artisan schedule:run`

---

## 4. Admin Panel on Vercel

### Prepare Repository

1. Push admin code to Git repository
2. Ensure `vercel.json` exists (optional)

### Deploy to Vercel

1. Go to [vercel.com](https://vercel.com)
2. Import repository
3. Set root directory: `admin`
4. Framework: Next.js (auto-detected)

### Environment Variables

```env
NEXT_PUBLIC_API_URL=https://api.autowala.in/api
```

### Custom Domain

1. Add domain: `admin.autowala.in`
2. Update DNS records

### Build Settings

- **Build Command**: `npm run build`
- **Output Directory**: `.next`
- **Install Command**: `npm install`

---

## 5. Mobile App Configuration

### User App (`user_app`)

1. Update `lib/core/constants.dart`:
```dart
static const String baseUrl = 'https://api.autowala.in/api';
```

2. Add Firebase config files:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

3. Update `android/app/build.gradle`:
```gradle
defaultConfig {
    applicationId "com.autowala.user"
    // ...
}
```

4. Build APK:
```bash
flutter build apk --release
```

### Rider App (`rider_app`)

1. Update `lib/core/constants.dart`:
```dart
static const String baseUrl = 'https://api.autowala.in/api';
```

2. Add Firebase config files

3. Update `android/app/build.gradle`:
```gradle
defaultConfig {
    applicationId "com.autowala.rider"
    // ...
}
```

4. Build APK:
```bash
flutter build apk --release
```

---

## 6. DNS Configuration

Add these DNS records:

| Type  | Name  | Value                          |
|-------|-------|--------------------------------|
| CNAME | api   | your-app.onrender.com         |
| CNAME | admin | cname.vercel-dns.com          |
| CNAME | @     | your-landing-page.vercel.app  |

---

## 7. SSL/HTTPS

- **Render**: Auto-provisioned Let's Encrypt certificates
- **Vercel**: Auto-provisioned certificates
- **Supabase**: Built-in SSL

---

## 8. Monitoring

### Render
- Built-in logging and metrics
- Set up alerts for errors and downtime

### Vercel
- Analytics dashboard
- Error tracking in logs

### Firebase
- Usage monitoring
- Performance monitoring

### Recommended Additions
- **Sentry**: Error tracking for both apps
- **LogRocket**: Session replay (admin panel)
- **Google Analytics**: User analytics

---

## 9. Backup Strategy

### Database (Supabase)
- Automatic daily backups (Pro plan)
- Manual backups via pg_dump:
```bash
pg_dump -h db.xxxxx.supabase.co -U postgres -d postgres > backup.sql
```

### Firebase
- Export data periodically
- Use Firebase Admin SDK for backups

---

## 10. Scaling

### Render
- Upgrade to Team/Pro for auto-scaling
- Add more instances as needed

### Supabase
- Upgrade plan for more connections
- Enable connection pooling

### Firebase
- Upgrade to Blaze plan for higher limits
- Enable caching strategies

---

## Quick Start Checklist

- [ ] Create Supabase project
- [ ] Enable PostGIS extension
- [ ] Run database migrations
- [ ] Create storage buckets
- [ ] Create Firebase project
- [ ] Configure Realtime Database rules
- [ ] Deploy Laravel to Render
- [ ] Set environment variables
- [ ] Deploy Admin to Vercel
- [ ] Configure custom domains
- [ ] Update mobile app configs
- [ ] Build and test mobile apps
- [ ] Set up monitoring
- [ ] Configure backups
