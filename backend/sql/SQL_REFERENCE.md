# FamCARE Database Setup Guide

Complete SQL reference for setting up and testing the FamCARE database.

## Quick Start

### PostgreSQL
```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE famcare_db;

# Connect to new database
\c famcare_db

# Run schema file
\i backend/sql/schema_postgresql.sql

# Verify
\dt  # List tables
```

**Update `.env`**:
```
DATABASE_URL=postgresql://user:password@localhost/famcare_db
```

### SQLite (Local Development)
```bash
# Create database and run schema
sqlite3 famcare.db < backend/sql/schema_sqlite.sql

# Verify
sqlite3 famcare.db ".tables"
sqlite3 famcare.db ".schema"
```

**Update `.env`**:
```
DATABASE_URL=sqlite:///./famcare.db
```

---

## Table Definitions

### 1. patients
Stores patient information.

```sql
CREATE TABLE patients (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);
```

| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER | Primary key, auto-increment |
| name | STRING | Patient name |

**Sample Query**:
```sql
SELECT * FROM patients;
INSERT INTO patients (name) VALUES ('Jane Smith');
```

### 2. caregivers
Stores caregiver information.

```sql
CREATE TABLE caregivers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);
```

| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER | Primary key, auto-increment |
| name | STRING | Caregiver name |

**Sample Query**:
```sql
SELECT * FROM caregivers;
INSERT INTO caregivers (name) VALUES ('Alice');
```

### 3. services
Stores available services with duration and pricing.

```sql
CREATE TABLE services (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    duration_minutes INTEGER NOT NULL,
    price NUMERIC(10, 2) NOT NULL
);
```

| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER | Primary key |
| name | STRING | Service name (e.g., "Cleaning") |
| duration_minutes | INTEGER | Service duration (30, 60, 90) |
| price | DECIMAL | Service price (e.g., 50.00) |

**Sample Query**:
```sql
SELECT * FROM services;
INSERT INTO services (name, duration_minutes, price) VALUES ('Cleaning', 30, 50.00);
```

### 4. bookings
Stores patient-caregiver-service bookings with time ranges.

```sql
CREATE TABLE bookings (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    caregiver_id INTEGER NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    booking_group_id VARCHAR(36),
    FOREIGN KEY (patient_id) REFERENCES patients(id),
    FOREIGN KEY (service_id) REFERENCES services(id),
    FOREIGN KEY (caregiver_id) REFERENCES caregivers(id)
);
```

| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER | Primary key |
| patient_id | FK | References patients.id |
| service_id | FK | References services.id |
| caregiver_id | FK | References caregivers.id |
| start_time | DATETIME | Booking start (e.g., 2024-05-27 09:00:00) |
| end_time | DATETIME | Booking end (calculated from service duration) |
| booking_group_id | STRING(36) | UUID grouping multi-service bookings |

**Sample Query**:
```sql
INSERT INTO bookings (patient_id, service_id, caregiver_id, start_time, end_time, booking_group_id)
VALUES (1, 1, 1, '2024-05-27 09:00:00', '2024-05-27 09:30:00', 'uuid-1234');

SELECT * FROM bookings;
```

---

## Indexes

Indexes are automatically created for performance optimization:

```sql
CREATE INDEX idx_booking_patient_id ON bookings(patient_id);
CREATE INDEX idx_booking_service_id ON bookings(service_id);
CREATE INDEX idx_booking_caregiver_id ON bookings(caregiver_id);
CREATE INDEX idx_booking_caregiver_time ON bookings(caregiver_id, start_time, end_time);
CREATE INDEX idx_booking_patient_time ON bookings(patient_id, start_time, end_time);
CREATE INDEX idx_booking_group_id ON bookings(booking_group_id);
CREATE INDEX idx_booking_start_time ON bookings(start_time);
```

**Why These Indexes?**
- `idx_booking_caregiver_time`: Fast conflict detection (caregiver already booked?)
- `idx_booking_patient_time`: Fast patient conflict check
- `idx_booking_group_id`: Fast group operations (cancel all bookings in group)

---

## Foreign Key Relationships

```
patients (1) ──────── (N) bookings
caregivers (1) ──────── (N) bookings
services (1) ──────── (N) bookings
```

**Rules**:
- Deleting a patient cascades to delete all their bookings
- Deleting a caregiver cascades to delete all their bookings
- Deleting a service cascades to delete all related bookings

---

## Sample Data

### Default Data Inserted
The schema script auto-inserts sample data:

**Patients** (5):
- John Doe
- Jane Smith
- Robert Johnson
- Emily Williams
- Michael Brown

**Caregivers** (5):
- Alice
- Bob
- Charlie
- Diana
- Eve

**Services** (5):
- Cleaning (30 min, $50)
- Health Check (60 min, $100)
- Cooking (45 min, $75)
- Grocery Shopping (60 min, $60)
- Medical Care (90 min, $150)

---

## Useful SQL Queries for Testing

### 1. Check All Bookings for a Patient
```sql
SELECT 
    b.id,
    p.name AS patient_name,
    c.name AS caregiver_name,
    s.name AS service_name,
    b.start_time,
    b.end_time
FROM bookings b
JOIN patients p ON b.patient_id = p.id
JOIN caregivers c ON b.caregiver_id = c.id
JOIN services s ON b.service_id = s.id
WHERE p.id = 1
ORDER BY b.start_time;
```

### 2. Find Caregiver's Schedule for a Date
```sql
SELECT 
    b.id,
    p.name AS patient_name,
    s.name AS service_name,
    b.start_time,
    b.end_time
FROM bookings b
JOIN patients p ON b.patient_id = p.id
JOIN services s ON b.service_id = s.id
WHERE b.caregiver_id = 1
    AND DATE(b.start_time) = '2024-05-27'
ORDER BY b.start_time;
```

### 3. Check for Caregiver Conflicts (Is caregiver free?)
```sql
SELECT COUNT(*) as conflicting_bookings
FROM bookings
WHERE caregiver_id = 1
    AND start_time < '2024-05-27 09:30:00'
    AND end_time > '2024-05-27 09:00:00';
-- Result: 0 = available, >0 = conflict
```

### 4. Check for Patient Conflicts
```sql
SELECT COUNT(*) as conflicting_bookings
FROM bookings
WHERE patient_id = 1
    AND start_time < '2024-05-27 09:30:00'
    AND end_time > '2024-05-27 09:00:00';
-- Result: 0 = available, >0 = conflict
```

### 5. View All Bookings in a Group
```sql
SELECT 
    b.id,
    p.name AS patient_name,
    c.name AS caregiver_name,
    s.name AS service_name,
    b.start_time,
    b.end_time,
    b.booking_group_id
FROM bookings b
JOIN patients p ON b.patient_id = p.id
JOIN caregivers c ON b.caregiver_id = c.id
JOIN services s ON b.service_id = s.id
WHERE b.booking_group_id = 'uuid-value'
ORDER BY b.start_time;
```

### 6. Revenue by Service (If payment integrated)
```sql
SELECT 
    s.name,
    COUNT(*) as total_bookings,
    SUM(s.price) as total_revenue
FROM bookings b
JOIN services s ON b.service_id = s.id
GROUP BY s.id, s.name
ORDER BY total_revenue DESC;
```

### 7. Caregiver Utilization (Bookings per caregiver)
```sql
SELECT 
    c.name,
    COUNT(*) as total_bookings,
    COUNT(DISTINCT CAST(b.start_time AS DATE)) as days_worked
FROM bookings b
JOIN caregivers c ON b.caregiver_id = c.id
GROUP BY c.id, c.name
ORDER BY total_bookings DESC;
```

### 8. Available Caregivers for a Time Slot
```sql
-- Find caregivers NOT booked for given time
SELECT c.id, c.name
FROM caregivers c
WHERE c.id NOT IN (
    SELECT DISTINCT caregiver_id
    FROM bookings
    WHERE start_time < '2024-05-27 09:30:00'
        AND end_time > '2024-05-27 09:00:00'
)
ORDER BY c.id;
```

### 9. Upcoming Bookings (Next 7 Days)
```sql
SELECT 
    b.id,
    p.name AS patient_name,
    c.name AS caregiver_name,
    s.name AS service_name,
    b.start_time,
    b.end_time
FROM bookings b
JOIN patients p ON b.patient_id = p.id
JOIN caregivers c ON b.caregiver_id = c.id
JOIN services s ON b.service_id = s.id
WHERE b.start_time >= NOW()
    AND b.start_time < NOW() + INTERVAL 7 DAY
ORDER BY b.start_time;
```

### 10. Delete Test Data (Clean database)
```sql
-- Delete all bookings
DELETE FROM bookings;

-- Reset auto-increment (PostgreSQL)
ALTER SEQUENCE bookings_id_seq RESTART WITH 1;

-- Reset auto-increment (SQLite)
DELETE FROM sqlite_sequence WHERE name='bookings';
```

---

## Data Consistency Checks

### Verify All Foreign Keys
```sql
-- Check for orphaned bookings (patient deleted but booking remains)
SELECT * FROM bookings WHERE patient_id NOT IN (SELECT id FROM patients);

-- Check for orphaned caregiver references
SELECT * FROM bookings WHERE caregiver_id NOT IN (SELECT id FROM caregivers);

-- Check for orphaned service references
SELECT * FROM bookings WHERE service_id NOT IN (SELECT id FROM services);
```

### Verify Time Logic
```sql
-- Check for invalid bookings (end_time before start_time)
SELECT * FROM bookings WHERE end_time <= start_time;

-- Check for bookings outside working hours (9 AM - 6 PM)
SELECT * FROM bookings
WHERE EXTRACT(HOUR FROM start_time) < 9
   OR EXTRACT(HOUR FROM end_time) > 18;
```

---

## Troubleshooting

### Issue: "Could not connect to database"
**Solution**:
```bash
# PostgreSQL: Verify service is running
sudo systemctl status postgresql

# SQLite: Check file permissions
ls -la famcare.db

# Update DATABASE_URL in .env
```

### Issue: "Foreign key constraint failed"
**Solution**:
```sql
-- Verify parent record exists before inserting booking
SELECT id FROM patients WHERE id = 1;  -- Should return 1 row

-- Check if cascade delete is preventing operations
PRAGMA foreign_keys = ON;  -- Enable (SQLite)
```

### Issue: "Table already exists"
**Solution**:
```sql
-- Drop and recreate
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS services CASCADE;
-- Then re-run schema file
```

### Issue: Performance is slow on large tables
**Solution**:
```sql
-- Analyze table statistics (PostgreSQL)
ANALYZE bookings;

-- Or recreate indexes (both)
DROP INDEX idx_booking_caregiver_time;
CREATE INDEX idx_booking_caregiver_time ON bookings(caregiver_id, start_time, end_time);
```

---

## Backup & Restore

### PostgreSQL Backup
```bash
pg_dump famcare_db > famcare_backup.sql
```

### PostgreSQL Restore
```bash
psql famcare_db < famcare_backup.sql
```

### SQLite Backup
```bash
cp famcare.db famcare_backup.db
```

### SQLite Restore
```bash
cp famcare_backup.db famcare.db
```

---

## Production Considerations

### Before Going Live

- [ ] Add database user with minimal permissions (not superuser)
- [ ] Enable SSL/TLS for PostgreSQL connections
- [ ] Set up automated backups (daily)
- [ ] Add monitoring/alerting on table growth
- [ ] Test disaster recovery procedures
- [ ] Add audit logging (who created/deleted bookings)
- [ ] Add soft delete column (`deleted_at` TIMESTAMP)
- [ ] Archive old bookings to separate table (performance)
- [ ] Set up replication for high availability
- [ ] Add table partitioning by date (for huge datasets)

### Example: Soft Delete for Bookings
```sql
-- Add column
ALTER TABLE bookings ADD COLUMN deleted_at TIMESTAMP;

-- Create view for active bookings only
CREATE VIEW active_bookings AS
SELECT * FROM bookings WHERE deleted_at IS NULL;

-- Soft delete
UPDATE bookings SET deleted_at = NOW() WHERE id = 123;
```

---

## Questions During Interview

**Q: How would you handle concurrent bookings?**  
A: The database indexes on (caregiver_id, start_time, end_time) allow quick conflict detection. With proper transaction isolation, two concurrent bookings for same caregiver+time will fail on one of them.

**Q: What if a service duration changes?**  
A: Existing bookings keep their end_time. Only new bookings use updated duration. Could add migration to recalculate end_time for future bookings.

**Q: How do you prevent a caregiver from working >8 hours?**  
A: Add application-level validation. Query total hours for caregiver on a date before creating booking.

**Q: What if you need to cancel a booking?**  
A: Add soft delete with `deleted_at` column. Or harddelete if payment is refundable within 24h.

---

**Last Updated**: 2026-05-27
