# AutoWala - API Documentation

## Base URL
```
Production: https://api.autowala.in/api
Development: http://localhost:8000/api
```

## Authentication

All authenticated endpoints require Bearer token:
```
Authorization: Bearer {token}
```

---

## Auth Endpoints

### Request OTP (User)
```http
POST /auth/user/request-otp
```

**Body:**
```json
{
  "phone": "9876543210"
}
```

**Response:**
```json
{
  "message": "OTP sent successfully",
  "expires_in": 300
}
```

---

### Verify OTP (User)
```http
POST /auth/user/verify-otp
```

**Body:**
```json
{
  "phone": "9876543210",
  "otp": "123456"
}
```

**Response:**
```json
{
  "token": "1|abc123...",
  "user": {
    "id": "uuid",
    "name": "John Doe",
    "phone": "9876543210",
    "avatar_url": null,
    "status": "active"
  }
}
```

---

### Request OTP (Rider)
```http
POST /auth/rider/request-otp
```

**Body:**
```json
{
  "phone": "9876543210"
}
```

---

### Verify OTP (Rider)
```http
POST /auth/rider/verify-otp
```

**Response:**
```json
{
  "token": "1|abc123...",
  "user": { ... },
  "rider": {
    "id": "uuid",
    "user_id": "uuid",
    "license_number": "MH-123456",
    "status": "approved",
    "kyc_status": "verified",
    "is_online": false,
    "rating_avg": 4.5,
    "total_rides": 150
  }
}
```

---

## User Endpoints

### Update Profile
```http
PUT /user/profile
Authorization: Bearer {token}
```

**Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com"
}
```

---

### Get Nearby Riders
```http
GET /user/nearby-riders
Authorization: Bearer {token}
```

**Query Parameters:**
- `latitude` (required): User's latitude
- `longitude` (required): User's longitude
- `radius` (optional): Radius in km (default: 5)

**Response:**
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Rider Name",
      "phone": "9876543210",
      "avatar_url": null,
      "rating_avg": 4.5,
      "vehicle_number": "MH 01 AB 1234",
      "vehicle_color": "Yellow",
      "latitude": 19.0760,
      "longitude": 72.8777,
      "distance": 0.5,
      "eta": 3,
      "active_route": {
        "id": "uuid",
        "name": "Andheri to Bandra",
        "fare": 50
      }
    }
  ]
}
```

---

### Start Tracking
```http
POST /user/track/start
Authorization: Bearer {token}
```

**Body:**
```json
{
  "rider_id": "uuid"
}
```

**Response:**
```json
{
  "ride_log_id": "uuid",
  "rider": { ... },
  "firebase_path": "/rides_active/{ride_id}"
}
```

---

### End Tracking
```http
POST /user/track/end
Authorization: Bearer {token}
```

**Body:**
```json
{
  "ride_log_id": "uuid"
}
```

---

### Submit Rating
```http
POST /user/ratings
Authorization: Bearer {token}
```

**Body:**
```json
{
  "ride_log_id": "uuid",
  "rider_id": "uuid",
  "score": 5,
  "comment": "Great ride!"
}
```

---

### Get Ride History
```http
GET /user/rides
Authorization: Bearer {token}
```

**Query Parameters:**
- `page` (optional): Page number
- `per_page` (optional): Items per page (default: 20)

---

### File Complaint
```http
POST /user/complaints
Authorization: Bearer {token}
```

**Body:**
```json
{
  "ride_log_id": "uuid",
  "type": "behavior",
  "description": "Description of the issue"
}
```

---

## Rider Endpoints

### Get Profile
```http
GET /rider/profile
Authorization: Bearer {token}
```

---

### Update Profile
```http
PUT /rider/profile
Authorization: Bearer {token}
```

**Body:**
```json
{
  "name": "Rider Name",
  "license_number": "MH-123456",
  "vehicle_number": "MH 01 AB 1234",
  "vehicle_color": "Yellow"
}
```

---

### Upload Document
```http
POST /rider/documents
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Body:**
- `type`: `driving_license` | `vehicle_registration` | `permit` | `photo`
- `file`: Image file

---

### Get Documents
```http
GET /rider/documents
Authorization: Bearer {token}
```

---

### Submit KYC
```http
POST /rider/kyc/submit
Authorization: Bearer {token}
```

---

### Register Vehicle
```http
POST /rider/vehicle
Authorization: Bearer {token}
```

**Body:**
```json
{
  "vehicle_number": "MH 01 AB 1234",
  "vehicle_type": "auto",
  "color": "Yellow",
  "make": "Bajaj",
  "model": "RE",
  "year": 2020
}
```

---

### Get Routes
```http
GET /rider/routes
Authorization: Bearer {token}
```

---

### Create Route
```http
POST /rider/routes
Authorization: Bearer {token}
```

**Body:**
```json
{
  "name": "Andheri to Bandra",
  "start_address": "Andheri Station",
  "end_address": "Bandra Station",
  "start_latitude": 19.1197,
  "start_longitude": 72.8464,
  "end_latitude": 19.0544,
  "end_longitude": 72.8402,
  "fare": 50,
  "is_active": true
}
```

---

### Delete Route
```http
DELETE /rider/routes/{id}
Authorization: Bearer {token}
```

---

### Go Online
```http
POST /rider/status/online
Authorization: Bearer {token}
```

---

### Go Offline
```http
POST /rider/status/offline
Authorization: Bearer {token}
```

---

### Update Location
```http
POST /rider/location
Authorization: Bearer {token}
```

**Body:**
```json
{
  "latitude": 19.0760,
  "longitude": 72.8777,
  "heading": 90
}
```

---

### Get Stats
```http
GET /rider/stats
Authorization: Bearer {token}
```

**Response:**
```json
{
  "total_rides": 150,
  "rides_this_week": 25,
  "rides_this_month": 80,
  "rating_avg": 4.5,
  "total_ratings": 120
}
```

---

## Admin Endpoints

### Login
```http
POST /admin/login
```

**Body:**
```json
{
  "email": "admin@autowala.in",
  "password": "password"
}
```

---

### Dashboard Stats
```http
GET /admin/dashboard/stats
Authorization: Bearer {token}
```

**Response:**
```json
{
  "total_users": 5000,
  "total_riders": 500,
  "active_riders": 150,
  "pending_kyc": 25,
  "total_rides": 50000,
  "rides_today": 200,
  "average_rating": 4.3,
  "complaints_pending": 10
}
```

---

### Get Online Riders
```http
GET /admin/dashboard/online-riders
Authorization: Bearer {token}
```

---

### List Riders
```http
GET /admin/riders
Authorization: Bearer {token}
```

**Query Parameters:**
- `status`: `pending` | `approved` | `rejected` | `suspended`
- `page`: Page number

---

### Update Rider Status
```http
PATCH /admin/riders/{id}/status
Authorization: Bearer {token}
```

**Body:**
```json
{
  "status": "approved",
  "reason": "All documents verified"
}
```

---

### KYC Pending List
```http
GET /admin/kyc/pending
Authorization: Bearer {token}
```

---

### Approve KYC
```http
POST /admin/kyc/{rider_id}/approve
Authorization: Bearer {token}
```

---

### Reject KYC
```http
POST /admin/kyc/{rider_id}/reject
Authorization: Bearer {token}
```

**Body:**
```json
{
  "reason": "Blurry license photo"
}
```

---

### List Users
```http
GET /admin/users
Authorization: Bearer {token}
```

---

### List Complaints
```http
GET /admin/complaints
Authorization: Bearer {token}
```

---

### Update Complaint
```http
PATCH /admin/complaints/{id}
Authorization: Bearer {token}
```

**Body:**
```json
{
  "status": "resolved",
  "admin_notes": "Issue resolved with rider"
}
```

---

## Error Responses

All errors follow this format:

```json
{
  "message": "Error description",
  "errors": {
    "field": ["Validation error message"]
  }
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200  | Success |
| 201  | Created |
| 400  | Bad Request |
| 401  | Unauthorized |
| 403  | Forbidden |
| 404  | Not Found |
| 422  | Validation Error |
| 500  | Server Error |

---

## Rate Limiting

- **Auth endpoints**: 5 requests/minute
- **General endpoints**: 60 requests/minute
- **Location updates**: 20 requests/minute

Headers returned:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 59
```
