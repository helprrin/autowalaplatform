# AutoWala - Shared Auto Ride Discovery Platform

<p align="center">
  <img src="docs/logo.png" alt="AutoWala Logo" width="120"/>
</p>

<p align="center">
  <strong>Discover shared auto rides near you</strong><br/>
  Cash only • No commissions • Real-time tracking
</p>

---

## 🎯 Overview

AutoWala is a production-grade platform for discovering shared auto-rickshaw rides in India. The platform connects passengers with auto-rickshaw drivers without handling payments - users pay cash directly to drivers.

### Key Features

- **For Passengers**
  - Find nearby autos in real-time
  - View driver ratings and route info
  - Track rides live on map
  - Call or share ride with family
  - SOS emergency button

- **For Drivers**
  - Simple online/offline toggle
  - Create and manage routes
  - Set display fares
  - Build reputation through ratings

- **For Admins**
  - Live map of all autos
  - KYC verification workflow
  - User/rider management
  - Complaint handling

---

## 🏗 Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  Flutter User   │     │  Flutter Rider  │
│      App        │     │      App        │
└────────┬────────┘     └────────┬────────┘
         │                       │
         │    ┌──────────────────┤
         │    │                  │
         ▼    ▼                  ▼
┌─────────────────┐     ┌─────────────────┐
│   Laravel API   │     │    Firebase     │
│   (Render)      │◄────│  Realtime DB    │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│    Supabase     │     │   Next.js       │
│   PostgreSQL    │     │  Admin Panel    │
│   + PostGIS     │     │   (Vercel)      │
└─────────────────┘     └─────────────────┘
```

---

## 📁 Project Structure

```
autowalaplatform/
├── backend/                 # Laravel REST API
│   ├── app/
│   │   ├── Http/Controllers/
│   │   ├── Models/
│   │   └── Services/
│   └── routes/api.php
│
├── user_app/               # Flutter User App
│   └── lib/
│       ├── core/           # Theme, Router, Constants
│       ├── services/       # API, Firebase, Location
│       ├── providers/      # Riverpod state
│       ├── screens/        # UI screens
│       └── widgets/        # Reusable components
│
├── rider_app/              # Flutter Rider App
│   └── lib/
│       ├── core/
│       ├── services/
│       ├── providers/
│       └── screens/
│
├── admin/                  # Next.js Admin Panel
│   └── src/
│       ├── app/            # App Router pages
│       ├── components/     # UI components
│       └── lib/            # API, store, utils
│
├── database/               # SQL schemas
│   ├── 001_schema.sql      # PostgreSQL + PostGIS
│   └── firebase_rules.json # Realtime DB rules
│
├── docs/                   # Documentation
│   ├── API.md
│   └── DEPLOYMENT.md
│
└── deployment/             # Deploy configs
```

---

## 🛠 Tech Stack

| Component | Technology |
|-----------|------------|
| User App | Flutter |
| Rider App | Flutter |
| Backend API | Laravel 10 |
| Admin Panel | Next.js 14 |
| Database | Supabase PostgreSQL + PostGIS |
| Real-time | Firebase Realtime Database |
| File Storage | Supabase Storage |
| Backend Hosting | Render |
| Admin Hosting | Vercel |

---

## 🚀 Quick Start

### Prerequisites

- PHP 8.2+
- Composer
- Node.js 18+
- Flutter 3.10+
- Supabase account
- Firebase account

### Backend Setup

```bash
cd backend
composer install
cp .env.example .env
# Edit .env with your credentials
php artisan key:generate
php artisan serve
```

### User App Setup

```bash
cd user_app
flutter pub get
# Add google-services.json (Android)
# Add GoogleService-Info.plist (iOS)
flutter run
```

### Rider App Setup

```bash
cd rider_app
flutter pub get
# Add Firebase config files
flutter run
```

### Admin Panel Setup

```bash
cd admin
npm install
cp .env.example .env.local
# Edit .env.local
npm run dev
```

---

## 🎨 Design System

| Element | Value |
|---------|-------|
| Primary | `#FFFFFF` (White) |
| Secondary | `#000000` (Black) |
| Accent | `#2563EB` (Blue) |
| Success | `#10B981` (Green) |
| Warning | `#F59E0B` (Orange) |
| Error | `#EF4444` (Red) |
| Border Radius | 12-16px |
| Font | Poppins |

---

## 📱 Screenshots

### User App
| Home | Nearby Autos | Tracking |
|------|--------------|----------|
| ![Home](docs/screens/user-home.png) | ![Nearby](docs/screens/user-nearby.png) | ![Track](docs/screens/user-track.png) |

### Rider App
| Dashboard | Routes | KYC |
|-----------|--------|-----|
| ![Dashboard](docs/screens/rider-home.png) | ![Routes](docs/screens/rider-routes.png) | ![KYC](docs/screens/rider-kyc.png) |

### Admin Panel
| Dashboard | KYC Review | Riders |
|-----------|------------|--------|
| ![Dashboard](docs/screens/admin-dashboard.png) | ![KYC](docs/screens/admin-kyc.png) | ![Riders](docs/screens/admin-riders.png) |

---

## 🔐 Security

- JWT-based authentication (Laravel Sanctum)
- OTP verification for all users
- KYC verification for riders
- Firebase security rules for real-time data
- Row-level security in Supabase
- HTTPS everywhere

---

## 📊 Database Schema

Key tables:
- `users` - All users (passengers & riders)
- `riders` - Rider-specific data
- `vehicles` - Registered vehicles
- `documents` - KYC documents
- `routes` - Rider routes
- `ride_logs` - Ride history
- `ratings` - User ratings
- `complaints` - Issue reports

See `database/001_schema.sql` for full schema.

---

## 🔥 Firebase Structure

```
/riders_live/{riderId}
  - location: { lat, lng, heading, geohash }
  - is_online: boolean
  - updated_at: timestamp

/riders_by_geohash/{geohash6}/{riderId}
  - lat, lng, updated_at

/rides_active/{rideId}
  - user_id, rider_id
  - status, started_at
  - rider_location: { lat, lng }
```

---

## 📚 Documentation

- [API Documentation](docs/API.md)
- [Deployment Guide](docs/DEPLOYMENT.md)

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open Pull Request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- Built with ❤️ for India's auto-rickshaw community
- Icons by Lucide
- Maps by Google Maps Platform

---

<p align="center">
  <strong>AutoWala</strong><br/>
  <sub>Making shared rides accessible</sub>
</p>
