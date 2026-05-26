# FamCARE Backend

A FastAPI-based healthcare booking system backend that manages patient-caregiver service bookings with atomic checkout and real-time caregiver availability.

## Project Overview

FamCARE Backend handles:
- **Service Catalog**: Management of bookable healthcare services with duration and pricing
- **Availability Management**: Time-slot availability with caregiver capacity planning
- **Atomic Checkout**: Multi-service bookings with transaction rollback on any failure (all-or-nothing)
- **Conflict Detection**: Prevents double-booking of patients and caregivers
- **Caregiver Allocation**: Automatic assignment of first available caregiver per booking

## Quick Start

### Prerequisites
- Python 3.12+
- PostgreSQL (or SQLite for development)
- pip/venv

### Installation

```bash
# Clone and navigate
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Update DATABASE_URL, other settings in .env

# Run migrations (if using Alembic)
# alembic upgrade head

# Start server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Server runs at `http://localhost:8000`
API docs at `http://localhost:8000/docs`

## Database Schema

### Tables

**patients**
```
id (PK)
name (String)
```

**caregivers**
```
id (PK)
name (String)
```

**services**
```
id (PK)
name (String)
duration_minutes (Integer) - e.g., 30 or 60
price (Numeric)
```

**bookings**
```
id (PK)
patient_id (FK → patients)
service_id (FK → services)
caregiver_id (FK → caregivers)
start_time (DateTime)
end_time (DateTime)
booking_group_id (String) - UUID grouping multi-service bookings
```

### Relationships
- One patient can have many bookings
- One caregiver can have many bookings
- One service can have many bookings
- Bookings are grouped by `booking_group_id` for multi-service transactions

## API Endpoints

### Services
- `GET /services/` - List all services

### Slots
- `GET /slots/available?service_id=1&date=2024-05-27` - Get available time slots for a service on a date
  - Returns time slots as strings: `["09:00", "09:15", "09:30", ...]`
  - Filters out past slots for today
  - Blocks all same-day bookings after 6 PM

### Checkout
- `POST /cart/checkout` - Complete multi-service booking
  ```json
  {
    "patient_id": 1,
    "items": [
      {
        "service_id": 1,
        "date": "2024-05-27",
        "start_time": "09:00"
      }
    ]
  }
  ```
  Response (success):
  ```json
  {
    "success": true,
    "booking_group_id": "uuid-string"
  }
  ```
  Response (failure):
  ```json
  {
    "detail": "No caregiver available for Cleaning on 2024-05-27 at 09:00"
  }
  ```

## Design Decisions

### 1. **Atomic Two-Phase Checkout**
- **Decision**: Validate all bookings first, then create all at once
- **Why**: Ensures atomicity—if ANY service lacks availability, NO bookings are created
- **Implementation**: 
  - Phase 1: Iterate items, find available caregiver for each, store assignments
  - Phase 2: Create all bookings in single transaction with rollback on error
- **Benefit**: No orphaned bookings if checkout partially fails

### 2. **Automatic Caregiver Allocation**
- **Decision**: Backend assigns first available caregiver; frontend sends no caregiver_id
- **Why**: 
  - Scalability: No UI complexity with caregiver selection
  - Real-time: Minimizes race conditions (single source of truth)
  - UX: Simpler frontend flow
- **Implementation**: `find_available_caregiver()` queries booked caregivers, returns first unbooked

### 3. **Fixed Time Slots (15-min intervals)**
- **Decision**: Pre-generated slots from 9 AM - 6 PM in 15-minute intervals
- **Why**: 
  - Predictable availability
  - Fixed slot duration supports service durations (30min, 60min, etc.)
  - Reduces complex time arithmetic in bookings
- **Trade-off**: Less flexible than arbitrary time selection; hardcoded working hours

### 4. **Caregiver Model Without Unavailability**
- **Decision**: No `is_available` field, `unavailable_dates`, or `shift_schedules`
- **Why**: Any caregiver can perform any service; availability determined by bookings only
- **Trade-off**: Can't model vacations, sickness, or preferred shifts
- **Future**: Add `caregiver_unavailability` table with date ranges

### 5. **Patient Conflict Checking**
- **Decision**: Prevent overlapping bookings for same patient
- **Why**: Assumption: One patient can't receive multiple services simultaneously
- **Implementation**: Query existing bookings with time overlap check

### 6. **booking_group_id for Multi-Service Atomicity**
- **Decision**: UUID string grouping related bookings
- **Why**: Enables canceling entire multi-service checkout by group
- **Benefit**: Maintains referential integrity for grouped operations

## Trade-offs & Limitations

| Feature | Decision | Why | Cost |
|---------|----------|-----|------|
| Authentication | None (hardcoded patient_id) | Fast prototyping | Security risk; no multi-user support |
| Caregiver shifts | Not modeled | Simple schema | Can't enforce working hours per caregiver |
| Payment | Not integrated | Out of scope | No revenue tracking |
| Notifications | No email/SMS | Out of scope | Poor UX on cancellations |
| Concurrency | Pessimistic locking via DB | Simple | Slower under high load |
| Caching | None | Simplicity | APIs hit DB on every request |

## Performance & Scalability

### What Breaks Under Load

1. **Database Connection Pool Exhaustion**
   - Current: Default SQLAlchemy pool (5 connections)
   - Issue: Under 50+ concurrent bookings, connections max out
   - Fix: Increase `pool_size` and `max_overflow` in `create_engine()`

2. **Lock Contention on Concurrent Checkouts**
   - Issue: Multiple simultaneous checkouts for same caregiver lock same rows
   - Symptom: Timeout errors on high-frequency bookings
   - Fix: Implement optimistic locking or queue-based booking

3. **N+1 Query in Slot Availability**
   - Current: `filter_available_slots()` doesn't batch check caregiver bookings
   - Issue: Repeated DB queries per slot
   - Fix: Pre-fetch all bookings for date, filter in-memory

4. **No Caching on Services/Slots**
   - Current: Every `/slots/available` query hits DB
   - Issue: Same slot list requested hundreds of times
   - Fix: Cache with 5-minute TTL (services rarely change)

5. **Sequential Caregiver Search**
   - Current: `find_available_caregiver()` queries ALL caregivers, filters in-app
   - Issue: Scales O(n) with caregiver count
   - Fix: Use SQL `WHERE NOT IN` more efficiently or add caregiver availability index

### Performance Recommendations

```python
# 1. Increase connection pool
engine = create_engine(
    DATABASE_URL,
    pool_size=20,
    max_overflow=40,
    pool_pre_ping=True  # Recycle stale connections
)

# 2. Add indices
CREATE INDEX idx_booking_caregiver_time ON bookings(caregiver_id, start_time, end_time);
CREATE INDEX idx_booking_patient_time ON bookings(patient_id, start_time, end_time);

# 3. Cache slots (30-sec TTL)
from functools import lru_cache
@lru_cache(maxsize=1000)
def get_slots_cached(date, duration):
    # ...

# 4. Use read replicas for /slots/available (read-only)
```

## Testing

```bash
# Run tests
pytest

# With coverage
pytest --cov=app

# Specific test
pytest tests/test_checkout.py::test_atomic_rollback -v
```

## Environment Variables

```
DATABASE_URL=postgresql://user:pass@localhost/famcare_db
# or SQLite: sqlite:///./famcare.db

ENVIRONMENT=development  # development, staging, production
LOG_LEVEL=INFO
```

## Project Structure

```
backend/
├── app/
│   ├── main.py                 # FastAPI app & routes
│   ├── database.py             # SQLAlchemy setup
│   ├── config.py               # Configuration (placeholder)
│   ├── models/                 # Database models
│   │   ├── booking.py
│   │   ├── caregiver.py
│   │   ├── patient.py
│   │   └── service.py
│   ├── routers/                # API endpoints
│   │   ├── checkout.py
│   │   ├── services.py
│   │   └── slots.py
│   ├── services/               # Business logic
│   │   ├── booking_service.py  # Atomic checkout, caregiver allocation
│   │   ├── conflict_service.py # Availability checking
│   │   └── slot_service.py     # Slot filtering
│   └── utils/
│       └── slot_generator.py   # Generate 9-6pm slots
├── tests/
├── requirements.txt
├── .env
└── README.md
```

## Known Issues & TODOs

- [ ] No authentication (security risk for production)
- [ ] Hardcoded 15-min slots; user specifies 30-min intervals (see `slot_generator.py:26`)
- [ ] No rate limiting on checkout endpoint (DoS risk)
- [ ] No logging for audit trail
- [ ] Working hours (9-6pm) hardcoded; should be configurable
- [ ] No payment processing integration
- [ ] No email notifications on booking confirmation/cancellation
- [ ] Caregiver unavailability not modeled

## Future Enhancements (Priority Order)

1. **Authentication & Authorization** (blocking)
   - JWT-based auth, role-based access (admin, patient, caregiver)
   
2. **Booking Cancellation** (high)
   - Cancel by `booking_group_id`, refund logic
   
3. **Caregiver Schedules** (high)
   - `caregiver_schedules` table for shifts, off-days
   
4. **Caching Layer** (medium)
   - Redis for slots, services (reduces DB load 80%)
   
5. **Async Processing** (medium)
   - Celery for email notifications, invoice generation
   
6. **Pagination** (low)
   - Add limit/offset to service/booking lists
   
7. **Payment Integration** (critical for production)
   - Stripe/Razorpay webhook handling

## Questions for Interviewers

1. Should caregivers have assigned shifts/days-off?
2. Can patients book multiple services on same day but different times?
3. Should overbooking be allowed (queue system)?
4. Is sub-hour slot granularity (5-min intervals) needed?

---

**Last Updated**: 2026-05-27  
**Maintainer**: [Your Name]
