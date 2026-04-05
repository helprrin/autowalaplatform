-- =====================================================
-- AutoWala Database Schema
-- PostgreSQL with PostGIS Extension
-- =====================================================

-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =====================================================
-- ENUMS
-- =====================================================

CREATE TYPE user_status AS ENUM ('active', 'inactive', 'blocked', 'deleted');
CREATE TYPE rider_status AS ENUM ('pending', 'approved', 'rejected', 'suspended', 'deleted');
CREATE TYPE document_type AS ENUM ('aadhar_front', 'aadhar_back', 'license_front', 'license_back', 'vehicle_rc', 'vehicle_permit', 'vehicle_insurance', 'selfie');
CREATE TYPE document_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE complaint_status AS ENUM ('open', 'in_progress', 'resolved', 'closed');
CREATE TYPE complaint_type AS ENUM ('safety', 'behavior', 'pricing', 'vehicle', 'other');

-- =====================================================
-- USERS TABLE
-- =====================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(15) NOT NULL UNIQUE,
    name VARCHAR(100),
    email VARCHAR(255),
    avatar_url TEXT,
    status user_status DEFAULT 'active',
    last_location GEOGRAPHY(POINT, 4326),
    last_location_updated_at TIMESTAMP WITH TIME ZONE,
    device_token TEXT,
    device_type VARCHAR(20),
    app_version VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_location ON users USING GIST(last_location);

-- =====================================================
-- RIDERS TABLE
-- =====================================================

CREATE TABLE riders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(15) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    avatar_url TEXT,
    status rider_status DEFAULT 'pending',
    is_online BOOLEAN DEFAULT false,
    is_available BOOLEAN DEFAULT true,
    current_location GEOGRAPHY(POINT, 4326),
    current_heading DECIMAL(5, 2),
    location_updated_at TIMESTAMP WITH TIME ZONE,
    rating_avg DECIMAL(2, 1) DEFAULT 5.0,
    rating_count INTEGER DEFAULT 0,
    total_rides INTEGER DEFAULT 0,
    device_token TEXT,
    device_type VARCHAR(20),
    app_version VARCHAR(20),
    kyc_submitted_at TIMESTAMP WITH TIME ZONE,
    kyc_approved_at TIMESTAMP WITH TIME ZONE,
    kyc_rejected_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_riders_phone ON riders(phone);
CREATE INDEX idx_riders_status ON riders(status);
CREATE INDEX idx_riders_online ON riders(is_online, is_available);
CREATE INDEX idx_riders_location ON riders USING GIST(current_location);
CREATE INDEX idx_riders_rating ON riders(rating_avg DESC);

-- =====================================================
-- VEHICLES TABLE
-- =====================================================

CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID NOT NULL REFERENCES riders(id) ON DELETE CASCADE,
    registration_number VARCHAR(20) NOT NULL UNIQUE,
    vehicle_type VARCHAR(50) DEFAULT 'auto_rickshaw',
    make VARCHAR(50),
    model VARCHAR(50),
    year INTEGER,
    color VARCHAR(30),
    seating_capacity INTEGER DEFAULT 3,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_vehicles_rider ON vehicles(rider_id);
CREATE INDEX idx_vehicles_registration ON vehicles(registration_number);

-- =====================================================
-- DOCUMENTS TABLE (KYC)
-- =====================================================

CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID NOT NULL REFERENCES riders(id) ON DELETE CASCADE,
    document_type document_type NOT NULL,
    file_url TEXT NOT NULL,
    file_name VARCHAR(255),
    file_size INTEGER,
    status document_status DEFAULT 'pending',
    rejection_reason TEXT,
    verified_by UUID,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(rider_id, document_type)
);

CREATE INDEX idx_documents_rider ON documents(rider_id);
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_documents_type ON documents(document_type);

-- =====================================================
-- ROUTES TABLE
-- =====================================================

CREATE TABLE routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID NOT NULL REFERENCES riders(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    start_point GEOGRAPHY(POINT, 4326) NOT NULL,
    end_point GEOGRAPHY(POINT, 4326) NOT NULL,
    start_address TEXT,
    end_address TEXT,
    route_line GEOGRAPHY(LINESTRING, 4326),
    distance_meters INTEGER,
    duration_minutes INTEGER,
    base_fare DECIMAL(10, 2) NOT NULL,
    per_km_fare DECIMAL(10, 2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    operating_days VARCHAR(20)[] DEFAULT ARRAY['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
    start_time TIME,
    end_time TIME,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_routes_rider ON routes(rider_id);
CREATE INDEX idx_routes_active ON routes(is_active);
CREATE INDEX idx_routes_start ON routes USING GIST(start_point);
CREATE INDEX idx_routes_end ON routes USING GIST(end_point);
CREATE INDEX idx_routes_line ON routes USING GIST(route_line);

-- =====================================================
-- ROUTE POINTS TABLE (Waypoints)
-- =====================================================

CREATE TABLE route_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    point_order INTEGER NOT NULL,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    address TEXT,
    landmark VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_route_points_route ON route_points(route_id);
CREATE INDEX idx_route_points_order ON route_points(route_id, point_order);
CREATE INDEX idx_route_points_location ON route_points USING GIST(location);

-- =====================================================
-- RIDE LOGS TABLE
-- =====================================================

CREATE TABLE ride_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    rider_id UUID NOT NULL REFERENCES riders(id) ON DELETE SET NULL,
    route_id UUID REFERENCES routes(id) ON DELETE SET NULL,
    vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
    pickup_location GEOGRAPHY(POINT, 4326),
    dropoff_location GEOGRAPHY(POINT, 4326),
    pickup_address TEXT,
    dropoff_address TEXT,
    fare_shown DECIMAL(10, 2),
    distance_meters INTEGER,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_ride_logs_user ON ride_logs(user_id);
CREATE INDEX idx_ride_logs_rider ON ride_logs(rider_id);
CREATE INDEX idx_ride_logs_date ON ride_logs(created_at DESC);
CREATE INDEX idx_ride_logs_completed ON ride_logs(is_completed);

-- =====================================================
-- RATINGS TABLE
-- =====================================================

CREATE TABLE ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_log_id UUID REFERENCES ride_logs(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rider_id UUID NOT NULL REFERENCES riders(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    tags VARCHAR(50)[],
    is_anonymous BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(ride_log_id, user_id)
);

CREATE INDEX idx_ratings_rider ON ratings(rider_id);
CREATE INDEX idx_ratings_user ON ratings(user_id);
CREATE INDEX idx_ratings_rating ON ratings(rating);
CREATE INDEX idx_ratings_date ON ratings(created_at DESC);

-- =====================================================
-- COMPLAINTS TABLE
-- =====================================================

CREATE TABLE complaints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_log_id UUID REFERENCES ride_logs(id) ON DELETE SET NULL,
    complainant_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    complainant_rider_id UUID REFERENCES riders(id) ON DELETE SET NULL,
    against_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    against_rider_id UUID REFERENCES riders(id) ON DELETE SET NULL,
    complaint_type complaint_type NOT NULL,
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    attachments TEXT[],
    status complaint_status DEFAULT 'open',
    priority INTEGER DEFAULT 3,
    assigned_to UUID,
    resolution_notes TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_complaints_user ON complaints(complainant_user_id);
CREATE INDEX idx_complaints_rider ON complaints(complainant_rider_id);
CREATE INDEX idx_complaints_against_rider ON complaints(against_rider_id);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_type ON complaints(complaint_type);
CREATE INDEX idx_complaints_date ON complaints(created_at DESC);

-- =====================================================
-- OTP VERIFICATIONS TABLE
-- =====================================================

CREATE TABLE otp_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(15) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    purpose VARCHAR(20) DEFAULT 'login',
    is_verified BOOLEAN DEFAULT false,
    attempts INTEGER DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_otp_phone ON otp_verifications(phone);
CREATE INDEX idx_otp_expires ON otp_verifications(expires_at);

-- =====================================================
-- ADMIN USERS TABLE
-- =====================================================

CREATE TABLE admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50) DEFAULT 'admin',
    permissions JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_admin_email ON admin_users(email);

-- =====================================================
-- NOTIFICATIONS TABLE
-- =====================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rider_id UUID REFERENCES riders(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_rider ON notifications(rider_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_date ON notifications(created_at DESC);

-- =====================================================
-- APP SETTINGS TABLE
-- =====================================================

CREATE TABLE app_settings (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default settings
INSERT INTO app_settings (key, value, description) VALUES
    ('min_app_version_user', '"1.0.0"', 'Minimum app version for user app'),
    ('min_app_version_rider', '"1.0.0"', 'Minimum app version for rider app'),
    ('location_update_interval', '5', 'Location update interval in seconds'),
    ('nearby_radius_meters', '5000', 'Default radius for nearby search in meters'),
    ('otp_expiry_minutes', '5', 'OTP expiry time in minutes'),
    ('max_otp_attempts', '3', 'Maximum OTP verification attempts'),
    ('sos_numbers', '["112", "100"]', 'Emergency SOS numbers'),
    ('support_phone', '"+919999999999"', 'Support phone number'),
    ('support_email', '"support@autowala.in"', 'Support email');

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to update rider rating
CREATE OR REPLACE FUNCTION update_rider_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE riders
    SET 
        rating_avg = (
            SELECT COALESCE(AVG(rating)::DECIMAL(2,1), 5.0)
            FROM ratings
            WHERE rider_id = NEW.rider_id
        ),
        rating_count = (
            SELECT COUNT(*)
            FROM ratings
            WHERE rider_id = NEW.rider_id
        ),
        updated_at = NOW()
    WHERE id = NEW.rider_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_rider_rating
    AFTER INSERT OR UPDATE ON ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_rider_rating();

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update_updated_at trigger to all relevant tables
CREATE TRIGGER trigger_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trigger_riders_updated_at BEFORE UPDATE ON riders FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trigger_vehicles_updated_at BEFORE UPDATE ON vehicles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trigger_documents_updated_at BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trigger_routes_updated_at BEFORE UPDATE ON routes FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trigger_complaints_updated_at BEFORE UPDATE ON complaints FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trigger_admin_users_updated_at BEFORE UPDATE ON admin_users FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =====================================================
-- HELPER FUNCTIONS FOR GEO QUERIES
-- =====================================================

-- Function to find nearby riders
CREATE OR REPLACE FUNCTION find_nearby_riders(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_meters INTEGER DEFAULT 5000
)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    phone VARCHAR,
    avatar_url TEXT,
    rating_avg DECIMAL,
    rating_count INTEGER,
    distance_meters DOUBLE PRECISION,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    heading DECIMAL,
    vehicle_number VARCHAR,
    vehicle_color VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        r.name,
        r.phone,
        r.avatar_url,
        r.rating_avg,
        r.rating_count,
        ST_Distance(
            r.current_location,
            ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
        ) as distance_meters,
        ST_Y(r.current_location::geometry) as latitude,
        ST_X(r.current_location::geometry) as longitude,
        r.current_heading as heading,
        v.registration_number as vehicle_number,
        v.color as vehicle_color
    FROM riders r
    LEFT JOIN vehicles v ON v.rider_id = r.id AND v.is_active = true
    WHERE r.status = 'approved'
        AND r.is_online = true
        AND r.is_available = true
        AND r.current_location IS NOT NULL
        AND ST_DWithin(
            r.current_location,
            ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
            radius_meters
        )
    ORDER BY distance_meters ASC;
END;
$$ LANGUAGE plpgsql;

-- Function to find routes near a point
CREATE OR REPLACE FUNCTION find_routes_near_point(
    search_lat DOUBLE PRECISION,
    search_lng DOUBLE PRECISION,
    radius_meters INTEGER DEFAULT 2000
)
RETURNS TABLE (
    route_id UUID,
    rider_id UUID,
    rider_name VARCHAR,
    route_name VARCHAR,
    start_address TEXT,
    end_address TEXT,
    base_fare DECIMAL,
    distance_to_start DOUBLE PRECISION,
    rider_rating DECIMAL,
    is_rider_online BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ro.id as route_id,
        r.id as rider_id,
        r.name as rider_name,
        ro.name as route_name,
        ro.start_address,
        ro.end_address,
        ro.base_fare,
        ST_Distance(
            ro.start_point,
            ST_SetSRID(ST_MakePoint(search_lng, search_lat), 4326)::geography
        ) as distance_to_start,
        r.rating_avg as rider_rating,
        r.is_online as is_rider_online
    FROM routes ro
    JOIN riders r ON r.id = ro.rider_id
    WHERE ro.is_active = true
        AND r.status = 'approved'
        AND ST_DWithin(
            ro.start_point,
            ST_SetSRID(ST_MakePoint(search_lng, search_lat), 4326)::geography,
            radius_meters
        )
    ORDER BY distance_to_start ASC, r.rating_avg DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ROW LEVEL SECURITY (RLS) Policies
-- =====================================================

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE riders ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Note: RLS policies should be configured based on your auth setup
-- These are examples - adjust based on Supabase auth

-- =====================================================
-- SEED DATA (for development)
-- =====================================================

-- Insert a default admin user (password: Admin@123)
INSERT INTO admin_users (email, password_hash, name, role) VALUES
    ('admin@autowala.in', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Super Admin', 'super_admin');

COMMENT ON TABLE users IS 'App users who book rides';
COMMENT ON TABLE riders IS 'Auto rickshaw drivers/owners';
COMMENT ON TABLE vehicles IS 'Auto rickshaws registered by riders';
COMMENT ON TABLE documents IS 'KYC documents uploaded by riders';
COMMENT ON TABLE routes IS 'Routes created by riders with fare information';
COMMENT ON TABLE route_points IS 'Waypoints/stops along a route';
COMMENT ON TABLE ride_logs IS 'Log of all rides for analytics';
COMMENT ON TABLE ratings IS 'User ratings for riders';
COMMENT ON TABLE complaints IS 'Complaints filed by users or riders';
