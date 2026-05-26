-- FamCARE Database Schema (PostgreSQL)
-- Run this script to set up the database manually if needed

-- Drop existing tables (for fresh start)
-- DROP TABLE IF EXISTS bookings CASCADE;
-- DROP TABLE IF EXISTS services CASCADE;
-- DROP TABLE IF EXISTS caregivers CASCADE;
-- DROP TABLE IF EXISTS patients CASCADE;

-- Create patients table
CREATE TABLE IF NOT EXISTS patients (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Create caregivers table
CREATE TABLE IF NOT EXISTS caregivers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Create services table
CREATE TABLE IF NOT EXISTS services (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    duration_minutes INTEGER NOT NULL,
    price NUMERIC(10, 2) NOT NULL
);

-- Create bookings table
CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    caregiver_id INTEGER NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    booking_group_id VARCHAR(36),
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
    FOREIGN KEY (caregiver_id) REFERENCES caregivers(id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX idx_booking_patient_id ON bookings(patient_id);
CREATE INDEX idx_booking_service_id ON bookings(service_id);
CREATE INDEX idx_booking_caregiver_id ON bookings(caregiver_id);
CREATE INDEX idx_booking_caregiver_time ON bookings(caregiver_id, start_time, end_time);
CREATE INDEX idx_booking_patient_time ON bookings(patient_id, start_time, end_time);
CREATE INDEX idx_booking_group_id ON bookings(booking_group_id);
CREATE INDEX idx_booking_start_time ON bookings(start_time);

-- Insert sample data

-- Insert sample patients
INSERT INTO patients (name) VALUES
    ('John Doe'),
    ('Jane Smith'),
    ('Robert Johnson'),
    ('Emily Williams'),
    ('Michael Brown');

-- Insert sample caregivers
INSERT INTO caregivers (name) VALUES
    ('Alice'),
    ('Bob'),
    ('Charlie'),
    ('Diana'),
    ('Eve');

-- Insert sample services
INSERT INTO services (name, duration_minutes, price) VALUES
    ('Cleaning', 30, 50.00),
    ('Health Check', 60, 100.00),
    ('Cooking', 45, 75.00),
    ('Grocery Shopping', 60, 60.00),
    ('Medical Care', 90, 150.00);

-- Verify tables created
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
