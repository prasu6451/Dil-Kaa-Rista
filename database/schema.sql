-- ==============================================================================
-- DIL KAA RISTA - PostgreSQL Database Schema
-- Database: dil_kaa_rista_db
-- Description: Matrimonial matchmaking platform schema with users, profiles,
--              match requests, and real-time chat messages.
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. Custom Enums
-- -----------------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE gender_enum AS ENUM ('male', 'female', 'other');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE marital_status_enum AS ENUM ('Never Married', 'Divorced', 'Widowed', 'Awaiting Divorce');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE request_status_enum AS ENUM ('pending', 'accepted', 'rejected', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- -----------------------------------------------------------------------------
-- 2. Trigger Function for Updated_at
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- 3. Users Table (Core Authentication)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(120) NOT NULL,
    gender VARCHAR(20) NOT NULL DEFAULT 'male',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_staff BOOLEAN NOT NULL DEFAULT FALSE,
    is_superuser BOOLEAN NOT NULL DEFAULT FALSE,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trigger for users updated_at
DROP TRIGGER IF EXISTS set_timestamp_users ON users;
CREATE TRIGGER set_timestamp_users
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

-- -----------------------------------------------------------------------------
-- 4. Profiles Table (Matrimonial Profile Details)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(120) NOT NULL,
    gender VARCHAR(20),
    date_of_birth DATE,
    marital_status VARCHAR(50) DEFAULT 'Never Married',
    height_cm INTEGER,
    religion VARCHAR(60),
    mother_tongue VARCHAR(60),
    caste VARCHAR(60),
    gotra VARCHAR(60),
    city VARCHAR(80),
    state VARCHAR(80),
    country VARCHAR(80) DEFAULT 'India',
    education VARCHAR(120),
    occupation VARCHAR(120),
    annual_income VARCHAR(80),
    about_me TEXT,
    avatar_url TEXT,
    photos TEXT[] DEFAULT '{}',
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_photo_locked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trigger for profiles updated_at
DROP TRIGGER IF EXISTS set_timestamp_profiles ON profiles;
CREATE TRIGGER set_timestamp_profiles
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

-- -----------------------------------------------------------------------------
-- 5. Match Requests Table (Interests / Connects)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS match_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_sender_receiver UNIQUE (sender_id, receiver_id),
    CONSTRAINT no_self_request CHECK (sender_id <> receiver_id)
);

-- Trigger for match_requests updated_at
DROP TRIGGER IF EXISTS set_timestamp_match_requests ON match_requests;
CREATE TRIGGER set_timestamp_match_requests
BEFORE UPDATE ON match_requests
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

-- -----------------------------------------------------------------------------
-- 6. Chat Messages Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT no_self_message CHECK (sender_id <> receiver_id)
);

-- -----------------------------------------------------------------------------
-- 7. High-Performance Indexes for Matrimonial Search & Queries
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_profiles_gender ON profiles(gender);
CREATE INDEX IF NOT EXISTS idx_profiles_religion ON profiles(religion);
CREATE INDEX IF NOT EXISTS idx_profiles_mother_tongue ON profiles(mother_tongue);
CREATE INDEX IF NOT EXISTS idx_profiles_marital_status ON profiles(marital_status);
CREATE INDEX IF NOT EXISTS idx_profiles_location ON profiles(state, city);
CREATE INDEX IF NOT EXISTS idx_profiles_dob ON profiles(date_of_birth);
CREATE INDEX IF NOT EXISTS idx_profiles_created ON profiles(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_match_req_sender ON match_requests(sender_id, status);
CREATE INDEX IF NOT EXISTS idx_match_req_receiver ON match_requests(receiver_id, status);

CREATE INDEX IF NOT EXISTS idx_messages_pair ON messages(sender_id, receiver_id, created_at);
CREATE INDEX IF NOT EXISTS idx_messages_unread ON messages(receiver_id, is_read);
