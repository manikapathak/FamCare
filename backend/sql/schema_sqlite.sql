-- FamCARE Database Schema (SQLite)
-- For local development and testing
-- Run: sqlite3 famcare.db < schema_sqlite.sql

-- Drop existing tables (for fresh start)
-- DROP TABLE IF EXISTS bookings;
-- DROP TABLE IF EXISTS services;
-- DROP TABLE IF EXISTS caregivers;
-- DROP TABLE IF EXISTS patients;

-- Create patients table
CREATE TABLE IF NOT EXISTS patients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

-- Create caregivers table
CREATE TABLE IF NOT EXISTS caregivers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

-- Create services table
CREATE TABLE IF NOT EXISTS services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    duration_minutes INTEGER NOT NULL,
    price REAL NOT NULL
);

-- Create bookings table
CREATE TABLE IF NOT EXISTS bookings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    caregiver_id INTEGER NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    booking_group_id TEXT,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE,
    FOREIGN KEY (caregiver_id) REFERENCES caregivers(id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_booking_patient_id ON bookings(patient_id);
CREATE INDEX IF NOT EXISTS idx_booking_service_id ON bookings(service_id);
CREATE INDEX IF NOT EXISTS idx_booking_caregiver_id ON bookings(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_booking_caregiver_time ON bookings(caregiver_id, start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_booking_patient_time ON bookings(patient_id, start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_booking_group_id ON bookings(booking_group_id);
CREATE INDEX IF NOT EXISTS idx_booking_start_time ON bookings(start_time);

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
.tables
.schema
