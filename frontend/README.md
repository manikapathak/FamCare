# FamCARE Frontend

A Flutter mobile application for patients to book healthcare services from caregivers with real-time availability and multi-service cart checkout.

## Project Overview

FamCARE Frontend provides:
- **Service Discovery**: Browse available healthcare services with pricing
- **Date & Time Selection**: Pick preferred dates and time slots (15-min intervals)
- **Multi-Service Cart**: Add multiple services, proceed to checkout
- **Atomic Checkout**: All bookings succeed or fail together; clear error messaging
- **Error Feedback**: Display specific booking failure reasons (e.g., "No caregiver available for X at Y")

## Quick Start

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / Xcode (for emulator)
- Backend server running at `http://192.168.1.6:8000` (or update in `api_service.dart`)

### Installation

```bash
# Clone and navigate
cd frontend

# Install dependencies
flutter pub get

# Run on emulator/device
flutter run

# Build APK (Android)
flutter build apk

# Build iOS
flutter build ios
```

App launches at `ServicePickerScreen` (home screen).

## Architecture

### State Management: Riverpod
- **cartProvider**: Manages shopping cart state (list of `Map<String, dynamic>`)
- **Pattern**: Notifier-based state (not hooks-based) for clarity
- **Benefit**: Reactive UI updates, no manual setState needed

### Models

**ServiceModel**
```dart
class ServiceModel {
  final int id;
  final String name;
  final int durationMinutes;    // 30 or 60 minutes
  final double price;
}
```

**SlotModel**
```dart
class SlotModel {
  final String time;  // Format: "HH:MM" (e.g., "09:00")
}
```

**CartItemModel**
```dart
class CartItemModel {
  final ServiceModel service;
  final SlotModel slot;
  final DateTime date;
  
  // Serialized as: { service_id, date, start_time }
  Map<String, dynamic> toJson()
}
```

### Screen Flow

```
ServicePickerScreen
  ↓ (select service, date, slot → add to cart)
CartScreen
  ↓ (review items → checkout)
CheckoutResultScreen (success or failure with error message)
```

## Screens & Functionality

### 1. ServicePickerScreen
**Purpose**: Browse services, select date/time, add to cart

**Features**:
- Dropdown to select service
- Date picker (min: today, max: 2030)
- "Get Slots" button → loads available time slots for service on selected date
- ListView of available slots (tap to select, check mark appears)
- "Add To Cart" button → creates `CartItemModel`, adds to cart, navigates to `CartScreen`

**API Calls**:
- `GET /services/` → List all services
- `GET /slots/available?service_id=X&date=YYYY-MM-DD` → List time slots

**Key Logic**:
```dart
// Format date as "yyyy-MM-dd" before API call
final formattedDate = DateFormat("yyyy-MM-dd").format(selectedDate);

// Create CartItem with service, slot, date
final cartItem = CartItemModel(
  service: selectedService!,
  slot: SlotModel(time: selectedSlot!),  // time is "HH:MM"
  date: selectedDate,
);

// Serialize & add to cart
ref.read(cartProvider.notifier).addItem(cartItem.toJson());
```

### 2. CartScreen
**Purpose**: Review cart items, proceed to checkout

**Features**:
- ListView showing cart items (service name, date, time)
- "Checkout" button → calls backend, handles success/failure
- Clears cart on success, navigates to result screen
- Displays error reason on failure

**API Calls**:
- `POST /cart/checkout` with payload:
  ```json
  {
    "patient_id": 1,  // TODO: Replace with authenticated user ID
    "items": [
      { "service_id": 1, "date": "2024-05-27", "start_time": "09:00" }
    ]
  }
  ```

**Error Handling**:
```dart
try {
  final response = await ApiService().checkoutCart(1, cart);
  // Success: clear cart, navigate with isSuccess=true
} on DioException catch(e) {
  // Extract error message from backend response
  String errorMessage = e.response?.data['detail'] ?? "Booking failed";
  // Navigate with error message
}
```

### 3. CheckoutResultScreen
**Purpose**: Display checkout result with success/failure details

**Features**:
- Icon: ✓ (success) or ✗ (failure)
- Title: "Booking Successful" or "Booking Failed"
- Error message: Displays detailed reason if booking failed
  - Example: "No caregiver available for Cleaning on 2024-05-27 at 09:00"

**Props**:
```dart
CheckoutResultScreen(
  isSuccess: bool,
  errorMessage: String? = null,  // Shown only if isSuccess=false
)
```

## Design Decisions

### 1. **No Frontend Caregiver Selection**
- **Decision**: Backend auto-assigns first available caregiver
- **Why**: 
  - Simpler UX (no need to show caregiver list)
  - Reduces data transferred to frontend
  - Backend has real-time availability info
- **Trade-off**: Patient can't pick preferred caregiver
- **Future**: Add caregiver profiles/ratings, let backend score & rank

### 2. **Atomic Cart Checkout**
- **Decision**: Send all cart items in single POST; backend validates all or none
- **Why**: 
  - Prevents partial bookings (e.g., 2 of 3 services succeed)
  - Matches real-world scenario (patient books multiple services atomically)
- **Implementation**: Backend validates all items first, then creates all in transaction
- **Benefit**: No orphaned bookings

### 3. **CartProvider Instead of Persistent Storage**
- **Decision**: Cart stored in Riverpod state (lost on app restart)
- **Why**: Prototyping speed; prevents stale data issues
- **Trade-off**: User loses cart if app crashes/closes
- **Future**: Add SharedPreferences or local SQLite for persistence

### 4. **Hard-coded patient_id = 1**
- **Decision**: No authentication; all users checkout as patient ID 1
- **Why**: Scope limitation; focuses on booking logic
- **Security Risk**: Production blocker
- **Future**: Implement auth (JWT, phone OTP, etc.)

### 5. **DateTime API Integration**
- **Decision**: 
  - Date selected via `showDatePicker` (native Flutter widget)
  - Time selected from `/slots/available` response (strings like "09:00")
  - Both sent to backend as: `date: "YYYY-MM-DD"`, `start_time: "HH:MM"`
- **Why**: Avoids timezone issues; backend validates times
- **Benefit**: No local time math; matches backend slot generation

### 6. **Error Message Extraction**
- **Decision**: Extract `detail` field from DioException response, display to user
- **Why**: Backend provides human-readable errors; frontend just passes through
- **Pattern**:
  ```dart
  String errorMessage = e.response?.data['detail'] ?? "Booking failed";
  ```
- **Benefit**: Maintainable; error text centralized in backend

### 7. **Riverpod Notifier Pattern (Not Hooks)**
- **Decision**: Use `NotifierProvider<CartNotifier, List<Map>>` explicitly
- **Why**: Clearer state management for team unfamiliar with Riverpod hooks
- **Trade-off**: More verbose than hooks version
- **Future**: Consider migration to hooks for conciseness

## Trade-offs & Limitations

| Feature | Decision | Why | Cost |
|---------|----------|-----|------|
| Authentication | None | Prototyping | No multi-user support; patient_id hardcoded |
| Cart Persistence | Riverpod only | Simplicity | Cart lost on app restart |
| Caregiver Selection | Backend auto-assigns | Simpler UX | No choice; user can't pick preferred caregiver |
| Payment UI | Not implemented | Out of scope | No revenue collection |
| Notifications | None | Out of scope | No confirmation/reminder push notifications |
| Offline Mode | Not supported | Complexity | Always requires internet connection |
| Pagination | Not used | Small datasets | May break with 1000+ services |

## Performance & Scalability

### What Breaks Under Load

1. **ListView Without Virtualization (Slots)**
   - Current: All slots rendered in ListView
   - Issue: If backend returns 100+ slots, frame drops on scroll
   - Fix: Use `ListView.builder` (already done) or add `itemExtent` for efficiency

2. **No Caching of Services**
   - Current: `getServices()` called on every app launch
   - Issue: 100+ app launches = 100+ HTTP requests
   - Fix: Cache services with `SharedPreferences` or local DB

3. **Missing Pagination on Services**
   - Current: Fetches all services at once
   - Issue: With 1000+ services, JSON parsing takes seconds
   - Fix: Implement offset/limit pagination on backend & frontend

4. **Multiple API Calls for Slots**
   - Current: "Get Slots" button triggers new API call
   - Issue: If user clicks multiple times, multiple requests fire
   - Fix: Add loading state, disable button during API call

5. **No Request Debouncing**
   - Current: No delay between date selection and slot fetch
   - Issue: If user changes date rapidly, 5+ requests fire
   - Fix: Debounce slot fetch (wait 500ms after user stops typing/selecting)

6. **Checkout Button: No Loading State**
   - Current: Button remains tappable during checkout API call
   - Issue: Double-tap creates duplicate bookings
   - Fix: Show loading spinner, disable button until response

### Performance Recommendations

```dart
// 1. Add loading state to checkout
bool _isCheckingOut = false;

// 2. Cache services
Future<List<ServiceModel>> getServicesCached() async {
  final cached = await SharedPreferences.getInstance()
      .getString('services_cache');
  if (cached != null) return ServiceModel.fromJsonList(json.decode(cached));
  
  final services = await getServices();
  SharedPreferences.getInstance().setString(
    'services_cache',
    json.encode(services),
  );
  return services;
}

// 3. Debounce slot loading
final _slotDebouncer = Debouncer(delay: Duration(milliseconds: 500));

onDateChanged(DateTime date) {
  _slotDebouncer.call(() => loadSlots());
}

// 4. Pagination on services
Future<List<ServiceModel>> getServices({int limit = 20, int offset = 0}) {
  return _dio.get('/services', queryParameters: {
    'limit': limit,
    'offset': offset,
  });
}
```

## API Integration

### Base Configuration
```dart
class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.6:8000',  // Change for production
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}
```

### Error Handling
```dart
// Check if DioException has backend error detail
if (e.response?.statusCode == 400) {
  final detail = e.response?.data['detail'];
  // Display to user
}
```

## Testing

### Widget Tests
```bash
flutter test test/screens/service_picker_screen_test.dart
```

### Integration Tests
```bash
flutter test integration_test/app_test.dart
```

### Manual Testing Checklist
- [ ] Load services on app start
- [ ] Select service → load available slots
- [ ] Add multiple services to cart
- [ ] Checkout with all items → success page
- [ ] Checkout with overbooking → error message displayed
- [ ] Close app → reopen → cart lost (expected)

## Project Structure

```
frontend/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── screens/
│   │   ├── service_picker_screen.dart # Browse services, pick date/time
│   │   ├── cart_screen.dart           # Review cart, checkout
│   │   └── checkout_result_screen.dart # Show success/failure
│   ├── models/
│   │   ├── service_model.dart         # Service data class
│   │   ├── slot_model.dart            # Slot (time string)
│   │   └── cart_item_model.dart       # Cart item with serialization
│   ├── providers/
│   │   └── cart_provider.dart         # Riverpod cart state
│   └── services/
│       └── api_service.dart           # Dio HTTP client
├── pubspec.yaml
└── README.md
```

## Environment Setup

### Update Backend URL
If backend runs on different IP/port, update `api_service.dart`:
```dart
final Dio _dio = Dio(
  BaseOptions(
    baseUrl: 'http://<your-ip>:8000',  // e.g., 192.168.1.100:8000
  ),
);
```

### Update patient_id (Temporary)
Replace hardcoded `1` in `cart_screen.dart:83` with authenticated user ID:
```dart
// TODO: Get from auth provider
final patientId = ref.watch(authProvider).userId;
await ApiService().checkoutCart(patientId, cart);
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.0.0  # State management
  dio: ^5.0.0              # HTTP client
  intl: ^0.19.0            # Date formatting
```

## Known Issues & TODOs

- [ ] Patient ID hardcoded as 1 (no auth)
- [ ] No cart persistence (lost on app restart)
- [ ] No loading/error states on API calls
- [ ] Multiple rapid checkouts may create duplicate bookings
- [ ] No pagination for large service lists
- [ ] Slots display all at once (no virtualization needed yet, but ready with `ListView.builder`)
- [ ] No offline support
- [ ] Timezone handling assumes device local time matches backend

## Future Enhancements (Priority Order)

1. **Authentication** (blocking)
   - Phone OTP or JWT login
   - Store auth token in secure storage
   - Auto-logout on token expiry

2. **Cart Persistence** (high)
   - Save cart to local SQLite on add/remove
   - Restore on app launch

3. **Loading & Error States** (high)
   - Show spinners during API calls
   - Disable buttons, show retry prompts on errors

4. **Caregiver Profiles** (medium)
   - Show caregiver name/rating on confirmation
   - Allow caregiver selection with backend scoring

5. **Booking History** (medium)
   - Screen showing past bookings with receipts
   - Cancel/reschedule options

6. **Notifications** (medium)
   - Firebase Cloud Messaging for confirmations
   - Reminder push 1 day before appointment

7. **Payment Integration** (critical for production)
   - Stripe/Razorpay payment flow
   - Invoice generation and storage

8. **Reviews & Ratings** (low)
   - Post-booking review of caregiver
   - Affects future caregiver selection scoring

## Common Issues

**Q: App won't connect to backend**
- A: Check IP address in `api_service.dart`; ensure backend is running
- Run `flutter run -v` to see HTTP errors

**Q: Slots showing "No available slots"**
- A: Check if all caregivers are booked for that time
- Verify backend has caregivers in database

**Q: Checkout always fails with "Booking Failed"**
- A: Check error message on `CheckoutResultScreen`
- Verify patient ID in payload matches existing patient in DB

## Questions for Interviewers

1. Should cart persist across app restarts?
2. Should users see which caregiver was assigned before confirming?
3. How should cancellations within 24 hours be handled?
4. Do we need estimated arrival time for caregivers?
5. Should ratings/reviews affect caregiver ranking?

---

**Last Updated**: 2026-05-27  
**Maintainer**: [Your Name]  
**Flutter Version**: 3.0+  
**Dart Version**: 3.0+
