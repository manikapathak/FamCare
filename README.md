# FamCARE - Healthcare Service Booking Platform

A full-stack healthcare booking system where patients can reserve multiple services from caregivers with real-time availability, atomic checkout, and automatic caregiver allocation.

**Status**: ✅ MVP Complete | ⚠️ No Authentication | 🔧 Production-Ready Features Missing

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FamCARE Frontend (Flutter)               │
│  ServicePickerScreen → CartScreen → CheckoutResultScreen   │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTP (Dio)
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                 FamCARE Backend (FastAPI)                   │
│  /services  /slots/available  /cart/checkout                │
└──────────────────────────┬──────────────────────────────────┘
                           │ SQLAlchemy ORM
                           ↓
┌─────────────────────────────────────────────────────────────┐
│         PostgreSQL Database (or SQLite for dev)             │
│  patients | caregivers | services | bookings                │
└─────────────────────────────────────────────────────────────┘
```

## Key Features

✅ **Multi-Service Bookings** - Add multiple services to cart, checkout atomically  
✅ **Real-Time Availability** - See available time slots for services by date  
✅ **Automatic Caregiver Allocation** - Backend assigns first available caregiver  
✅ **Atomic Checkout** - All bookings succeed or fail together (no partial bookings)  
✅ **Conflict Prevention** - No double-booking of patients or caregivers  
✅ **Clear Error Messages** - User sees specific reason for booking failures  
⚠️ **No Authentication** - Placeholder for future auth implementation  
⚠️ **No Payment Processing** - Not integrated yet

## Quick Start (Full Stack)

### Prerequisites
- Python 3.12+
- Flutter 3.0+
- PostgreSQL (or SQLite for local dev)
- Git

### Local Development Setup

**Backend**:
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env

# Adjust DATABASE_URL in .env if needed
# SQLite: sqlite:///./famcare.db
# PostgreSQL: postgresql://user:pass@localhost/famcare

uvicorn app.main:app --reload --port 8000
# Backend runs at http://localhost:8000
```

**Frontend**:
```bash
cd frontend
flutter pub get

# Update baseUrl in lib/services/api_service.dart if needed
# (change 192.168.1.6:8000 to localhost:8000 for local testing)

flutter run
```

**Populate Sample Data**:
```bash
# In Python REPL or script
from app.database import SessionLocal
from app.models.service import Service
from app.models.caregiver import Caregiver
from app.models.patient import Patient

db = SessionLocal()

# Add caregivers
db.add(Caregiver(name="Alice"))
db.add(Caregiver(name="Bob"))
db.add(Caregiver(name="Charlie"))

# Add services
db.add(Service(name="Cleaning", duration_minutes=30, price=50.00))
db.add(Service(name="Health Check", duration_minutes=60, price=100.00))

# Add patient
db.add(Patient(name="John Doe"))

db.commit()
```

Then:
1. Open Flutter app
2. Select "Cleaning" service
3. Pick today's date
4. Click "Get Slots" → see available time slots
5. Select a slot → Add to Cart
6. Go to Cart → Checkout
7. See success or error message

## Project Structure

```
FamCare/
├── backend/                      # FastAPI backend
│   ├── app/
│   │   ├── main.py              # App entry, route registration
│   │   ├── database.py          # SQLAlchemy config
│   │   ├── models/              # ORM models
│   │   ├── routers/             # API endpoints
│   │   ├── services/            # Business logic
│   │   └── utils/               # Helper functions
│   ├── requirements.txt
│   ├── .env
│   └── README.md                # Backend-specific docs
│
├── frontend/                     # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/             # UI screens
│   │   ├── models/              # Data classes
│   │   ├── providers/           # Riverpod state
│   │   └── services/            # API client
│   ├── pubspec.yaml
│   └── README.md                # Frontend-specific docs
│
└── README.md                    # This file
```

## Database Schema

```
patients
├── id (PK)
└── name

caregivers
├── id (PK)
└── name

services
├── id (PK)
├── name
├── duration_minutes
└── price

bookings
├── id (PK)
├── patient_id (FK)
├── service_id (FK)
├── caregiver_id (FK)
├── start_time
├── end_time
└── booking_group_id (UUID for multi-service atomicity)
```

## API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/services/` | List all services |
| GET | `/slots/available?service_id=1&date=2024-05-27` | Available time slots |
| POST | `/cart/checkout` | Create bookings (atomic) |

See `backend/README.md` for full API documentation.

## Core Design Decisions

### 1. Atomic Two-Phase Checkout
- **Phase 1**: Validate all services can be booked
- **Phase 2**: Create all bookings or rollback on any error
- **Benefit**: No partial bookings; ensures data consistency

### 2. Backend Caregiver Allocation
- Frontend sends only: service_id, date, start_time (no caregiver_id)
- Backend finds first available caregiver using query
- **Benefit**: Real-time availability, simpler frontend, single source of truth

### 3. Fixed Time Slots
- Pre-generated 15-minute slots from 9 AM - 6 PM
- **Benefit**: Predictable, supports multiple service durations
- **Limitation**: Can't book arbitrary times

### 4. Riverpod State Management
- CartProvider stores items in memory
- **Benefit**: Simple, reactive updates
- **Limitation**: Cart lost on app restart (future: add persistence)

### 5. No Authentication (For Now)
- Hardcoded patient_id = 1
- **Reason**: Scope; focus on booking logic
- **BLOCKING FOR PRODUCTION**: Must add JWT/OTP auth before launch

## What Breaks Under Load

| Component | Issue | Symptom | Fix |
|-----------|-------|---------|-----|
| **DB Connection Pool** | Default 5 connections | Timeout errors at 50+ concurrent requests | Increase `pool_size` to 20+ |
| **Concurrent Checkouts** | Row-level locking | Slow checkout with multiple users | Implement optimistic locking or queue |
| **Slot Availability Query** | No caching | Same slot list fetched 100x/day | Add Redis cache (5-min TTL) |
| **Caregiver Search** | Full table scan | Scales O(n) with caregiver count | Add database index on `caregiver_id` |
| **Flutter ListView** | No virtualization | Frame drops with 100+ slots | Already using `ListView.builder` |

See backend/README.md and frontend/README.md for detailed performance recommendations.

## Known Limitations

| Feature | Status | Why | Impact |
|---------|--------|-----|--------|
| Authentication | ❌ Not implemented | Out of scope for MVP | Security risk; all users are patient_id=1 |
| Payment | ❌ Not implemented | Out of scope | No revenue tracking |
| Caregiver Schedules | ❌ Not modeled | Any caregiver always available | Can't enforce shifts/off-days |
| Cart Persistence | ❌ In-memory only | Simplicity | Cart lost on app restart |
| Notifications | ❌ Not implemented | Out of scope | No booking confirmations |
| Cancellations | ❌ Not implemented | Out of scope | No way to cancel after booking |

## Testing

### Backend
```bash
cd backend
pytest
pytest --cov=app
```

### Frontend
```bash
cd frontend
flutter test
```

### Manual Testing Checklist
- [ ] Load app → see services list
- [ ] Select service → load slots on date picker
- [ ] Add 2+ services to cart
- [ ] Checkout → success page
- [ ] Try booking same caregiver+time twice → error message
- [ ] Check database for bookings created

## Deployment Checklist

- [ ] Add authentication (JWT or OTP)
- [ ] Enable CORS on backend (if separate domain)
- [ ] Switch DATABASE_URL to production PostgreSQL
- [ ] Set environment to `production`
- [ ] Enable SSL/HTTPS on API
- [ ] Add rate limiting on `/cart/checkout`
- [ ] Implement error logging (Sentry or similar)
- [ ] Add payment processing (Stripe/Razorpay)
- [ ] Set up database backups
- [ ] Load test with k6 or similar
- [ ] Add email notifications (SendGrid)
- [ ] Review security checklist:
  - [ ] No hardcoded credentials
  - [ ] All inputs validated
  - [ ] SQL injection prevention (using ORM)
  - [ ] CSRF protection
  - [ ] Rate limiting enabled

## Common Interview Questions & Answers

**Q: How do you prevent double-booking?**  
A: Two mechanisms:
1. Patient conflict check: Query existing bookings for time overlap before creating new one
2. Caregiver conflict check: In `find_available_caregiver()`, exclude caregivers with overlapping bookings
3. Database unique constraint (optional): `UNIQUE(caregiver_id, start_time, end_time)` prevents race conditions

**Q: What happens if checkout fails halfway?**  
A: All bookings are rolled back via database transaction. If Phase 1 (validation) passes but Phase 2 (creation) fails, entire transaction is rolled back. Zero bookings created.

**Q: How do you handle timezone issues?**  
A: Currently, backend assumes UTC; frontend sends local date+time strings. For production, add explicit timezone parameter to API.

**Q: Can caregivers work different shifts?**  
A: Currently no. All caregivers always available 9-6pm. To add shifts:
1. Create `caregiver_shifts` table
2. Modify `find_available_caregiver()` to check shift + no bookings
3. Add caregiver unavailability dates

**Q: How would you scale this to 10k concurrent users?**  
A:
1. **Database**: Add read replicas for `/slots/available`, master for writes
2. **Caching**: Redis for service list (rarely changes), slot list (changes hourly)
3. **API**: Use async workers (Gunicorn with 8+ workers), connection pooling
4. **Frontend**: Pagination, lazy loading, offline queue
5. **Architecture**: Message queue (Celery) for async booking confirmation

**Q: What would you do differently with more time?**  
A:
1. **Authentication** (blocking): JWT + refresh tokens + role-based access
2. **Booking History**: Show past/upcoming bookings in app
3. **Cancellations**: Implement cancel with refund/rescheduling logic
4. **Ratings**: Post-booking caregiver reviews
5. **Notifications**: Email confirmation + SMS reminders
6. **Payment**: Integrate Stripe with invoice generation
7. **Caregiver Portal**: App for caregivers to accept/decline/mark complete
8. **Analytics**: Track popular services, caregiver utilization, revenue
9. **Admin Dashboard**: Manage caregivers, services, view bookings
10. **Testing**: Add 80%+ test coverage, integration tests

## Resources

- [Backend README](./backend/README.md) - Detailed API, design decisions, schema
- [Frontend README](./frontend/README.md) - Flutter architecture, state management, screens
- [FastAPI Docs](https://fastapi.tiangolo.com)
- [Flutter Docs](https://flutter.dev)
- [Riverpod Guide](https://riverpod.dev)

## Support & Contribution

For issues, questions, or improvements:
1. Check relevant README (backend/frontend)
2. Check "Known Issues & TODOs"
3. Consult "What Breaks Under Load" section
4. Ask during interview if behavior is unclear

---

**Project Status**: ✅ MVP (core functionality complete)  
**Last Updated**: 2026-05-27  
**Author**: [Your Name]  
**Ready for Interview**: Yes (with caveats: no auth, no payment)
