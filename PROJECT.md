# Project: HomeEase (Priority 0 — Critical Committee Directives & Master Roadmap Completion)

## Architecture
HomeEase is a hyper-local domestic worker connect platform in Abbottabad, Pakistan.
- **Frontend / Client**: Flutter 3.41.4 (Dart 3.11.1) mobile application under `Home Ease Project/MobileApp/homeease/`.
- **Backend / BaaS**: Supabase PostgreSQL database, Supabase GoTrue Auth, PostgREST API at `https://ppuenornykkqgdxufrkg.supabase.co`.
- **AI Recommendation Engine**: Vector-based recommendation engine (`ai_recommendation_engine.dart`) combining Cosine skill similarity (0.50), Haversine geographic decay (0.35), Bayesian rating normalization (0.15), and Explainable AI (XAI) transparent badge generation.
- **Payment & Escrow System**: Simulated multi-mode payment gateway (`PaymentGatewaySheet`) supporting Easypaisa USSD push, JazzCash MPIN, Stripe Card (Luhn, brand badge, 3DS modal), and Cash on Delivery with Serene Hearth `DigitalReceiptDialog` watermark and proof.
- **Geospatial Discovery Engine**: OpenStreetMap (`flutter_map: ^7.0.2` & `latlong2: ^0.9.1`) centered on Abbottabad (`34.1983° N, 73.2425° E`), CartoDB Voyager Retina tiles, locality jump chips, trade category filters, and interactive worker markers with quick preview card and direct booking routing.
- **Administrative Governance Tier**: Dual-screen responsive `AdminDashboardScreen` (persistent sidebar for Web/Desktop $\ge 900\text{dp}$, tabs/drawer for Mobile $< 900\text{dp}$) with Platform Analytics, Worker Verification Desk (NADRA CNIC format), Dispute Resolution Desk (Refund, Payout, Dismiss), and Chronological System Audit Logs.
- **State & Navigation**: State machine (`HomeEaseFlow`) wrapped in bilingual (EN/UR) responsive layout (`AppScaffold`).

## Code Layout
- Mobile App Root: `c:\Users\AbuZar\Desktop\Fyp\HomeEase\Home Ease Project\MobileApp\homeease`
- `lib/widgets/payment_gateway_sheet.dart` — PaymentGatewaySheet (Easypaisa, JazzCash, Stripe, COD)
- `lib/widgets/digital_receipt_dialog.dart` — Serene Hearth DigitalReceiptDialog with watermark & TxID copy
- `lib/screens/service_agreement_screen.dart` — Service agreement, OTP verification, payment gateway integration & manual receipt fallback
- `lib/screens/worker_map_screen.dart` — Abbottabad OpenStreetMap discovery, CartoDB Voyager tiles, locality chips, trade filter, marker layer, preview card
- `lib/screens/home_search_screen.dart` — Search screen with "Map View" button
- `lib/screens/admin_dashboard_screen.dart` — Responsive admin dashboard (Analytics, Verification, Disputes, Audit Logs)
- `lib/screens/sign_in_screen.dart` — Sign in screen with Admin role selector & 1-tap "Demo Admin Login" pill
- `lib/services/audit_log_service.dart` — Platform event audit log service
- `lib/services/supabase_auth_service.dart` — Supabase authentication with Admin demo account
- `lib/services/worker_repository.dart` — Worker data operations, verification status updates
- `lib/services/dispute_repository.dart` — Dispute operations, live feed, adjudication actions
- `lib/services/booking_repository.dart` — Booking operations, payment completion sync (`status: completed`, `payment_status: confirmed`)
- `lib/services/localization_service.dart` — Bilingual (EN / UR) dictionary and directionality
- `lib/app/home_ease_flow.dart` — Navigation coordinator and stage transitions (`AppStage.workerMap`, `AppStage.adminDashboard`)
- `test/` — Full regression test suite ($\ge 480$ passing tests)

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Easypaisa Payment Mode | 03XXXXXXXXX validation, 5-digit PIN, 2-sec USSD modal push, TxID `EP-XXXXXXXX` | M1 | ORIGINAL_REQUEST §R1 |
| 2 | JazzCash Payment Mode | 03XXXXXXXXX validation, 4-digit MPIN, 2-sec spinner, TxID `JC-XXXXXXXX` | M1 | ORIGINAL_REQUEST §R1 |
| 3 | Stripe Card Payment Mode | 16-digit Luhn validation, Visa/Mastercard badge, MM/YY, CVC, 2-sec 3D Secure modal dialog, TxID `ch_3M...` | M1 | ORIGINAL_REQUEST §R1 |
| 4 | Cash on Delivery (COD) Mode | Mutual cash settlement acknowledgment, TxID `COD-XXXXXXXX` | M1 | ORIGINAL_REQUEST §R1 |
| 5 | Serene Hearth Digital Receipt | Branded receipt dialog with watermark, timestamp, TxID copy button, booking/worker summary | M1 | ORIGINAL_REQUEST §R1 |
| 6 | Payment DB & Repo Sync | `completeBookingPayment(...)` transitions `status: 'completed'` & `payment_status: 'confirmed'` in Supabase & cache | M1 | ORIGINAL_REQUEST §R1 |
| 7 | ServiceAgreementScreen Payment Integration | Dual pathway: Instant Payment Gateway + manual receipt fallback (100% test preservation) | M1 | ORIGINAL_REQUEST §R1 |
| 8 | OSM Map Dependencies & Config | Add `flutter_map: ^7.0.2` and `latlong2: ^0.9.1` to pubspec.yaml and resolve dependencies | M2 | ORIGINAL_REQUEST §R2 |
| 9 | Abbottabad OSM Map Engine | `WorkerMapScreen` centered on Abbottabad (34.1983° N, 73.2425° E) with CartoDB Voyager tiles & OSM fallback | M2 | ORIGINAL_REQUEST §R2 |
| 10 | Abbottabad Locality Jump Chips | Locality jump chips (All, Mandian, Jhangi Syedan, Supply Bazaar, Nawan Shehr, PMA Kakul Road) with camera pan | M2 | ORIGINAL_REQUEST §R2 |
| 11 | Trade Category Filter Chips | Filter chips (All, Cook, Cleaner, Nanny, Caregiver, Maid, Electrician, Plumber) | M2 | ORIGINAL_REQUEST §R2 |
| 12 | Interactive Worker Marker Layer | Map pins with trade iconography, rating badges, and jitter dispersion for identical coords | M2 | ORIGINAL_REQUEST §R2 |
| 13 | Worker Quick Preview Card | Slide-up card with avatar, name, category, rating, distance, rate, and direct "Book Now" routing | M2 | ORIGINAL_REQUEST §R2 |
| 14 | Map View Navigation Wiring | "Map View" trigger in `HomeSearchScreen` and `AppStage.workerMap` in `HomeEaseFlow` | M2 | ORIGINAL_REQUEST §R2 |
| 15 | Responsive Admin Dashboard Layout | Dual-screen responsiveness: persistent sidebar (Web $\ge 900\text{dp}$) vs top tabs/drawer (Mobile $< 900\text{dp}$) | M3 | ORIGINAL_REQUEST §R3 |
| 16 | Admin Platform Analytics Tab | Gross PKR volume, total bookings, active disputes, verified workers, and category distribution | M3 | ORIGINAL_REQUEST §R3 |
| 17 | Worker Verification Desk Tab | Moderation queue with NADRA CNIC format (`13101-XXXXXXX-X`), bio, experience, 1-tap Approve/Reject | M3 | ORIGINAL_REQUEST §R3 |
| 18 | Dispute Resolution Desk Tab | Live feed from DisputeRepository, photo evidence thumbnails, Refund/Payout/Dismiss adjudication | M3 | ORIGINAL_REQUEST §R3 |
| 19 | System Audit Logs Tab | Chronological timeline of platform events (auth, verification, adjudication, settlement) | M3 | ORIGINAL_REQUEST §R3 |
| 20 | Admin Auth & Demo Login | Admin role in SignInScreen tab selector, 1-tap "Demo Admin Login" pill, AppStage.adminDashboard | M3 | ORIGINAL_REQUEST §R3 |
| 21 | Quality & Static Analysis | Zero errors and zero warnings on `flutter analyze` | M4 | ORIGINAL_REQUEST §R4 |
| 22 | Comprehensive Test Suite | Master test suite expanding from 403 to $\ge 480$ passing tests (100% success rate) | M4 | ORIGINAL_REQUEST §R4 |
| 23 | Touch Target & RTL Enforcement | All interactive controls $\ge 48 \times 48\text{dp}$ touch target boundaries, full Urdu RTL support | M4 | ORIGINAL_REQUEST §R4 |
| 24 | Master Roadmap 100% Update | Update `ISSUES_AND_ROADMAP.md` (root & mobile app) marking Priority 0 & master roadmap 100% complete | M4 | ORIGINAL_REQUEST §R4 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Realistic Pakistani & Global Payment Gateway Simulation | Features 1–7 (PaymentGatewaySheet, DigitalReceiptDialog, BookingRepository sync, ServiceAgreementScreen integration, bilingual strings) | none | DONE |
| M2 | Interactive Abbottabad OpenStreetMap Worker Discovery | Features 8–14 (flutter_map & latlong2, WorkerMapScreen, locality chips, trade filter, marker layer, preview card, HomeSearchScreen & HomeEaseFlow wiring) | none | DONE |
| M3 | Responsive Admin Governance & Moderation Dashboard | Features 15–20 (AdminDashboardScreen dual responsiveness, 4 tabs, Admin auth, 1-tap Demo Login, repository extensions, AuditLogService) | M1, M2 | DONE |
| M4 | E2E Verification, Quality Standards, and Roadmap Completion | Features 21–24 (flutter analyze 0 issues, flutter test $\ge 480$ tests passing 100%, touch target & RTL audit, ISSUES_AND_ROADMAP.md updates) | M1, M2, M3 | DONE |

## Interface Contracts

### 1. Payment Gateway ↔ Booking Repository
- **Method**: `BookingRepository.completeBookingPayment({required String bookingId, required String paymentMethod, required String txId, String paymentStatus = 'confirmed'})`
- **Output**: Returns updated `Booking` with `status: 'Completed'`, `paymentStatus: 'confirmed'`, `paymentMethod: paymentMethod.toLowerCase()`.
- **Supabase Sync**: Updates `public.bookings` where `id = bookingId` with `{'status': 'completed', 'payment_status': 'confirmed', 'payment_method': paymentMethod}`.

### 2. Map Screen ↔ Navigation Flow
- **Stage**: `AppStage.workerMap` in `HomeEaseFlow`.
- **Input**: `List<WorkerProfile> workers`, `Function(WorkerProfile) onSelectWorker`, `VoidCallback onBack`.
- **Routing**: Tapping "Book Now" in preview card invokes `onSelectWorker(worker)` navigating directly to `AppStage.workerDetail`.

### 3. Admin Dashboard ↔ Repositories
- **Dispute Adjudication**:
  - `DisputeRepository.resolveDispute({required String disputeId, required String resolution, required String adminNotes})`
  - Valid resolutions: `'resolved_refund'`, `'resolved_payout'`, `'dismissed'`.
- **Worker Verification**:
  - `WorkerRepository.updateWorkerVerificationStatus({required String workerId, required String status})`
  - Valid status: `'Verified'`, `'Rejected'`.
  - Also sets `verified: true/false` and updates Supabase `worker_profiles`.
- **Platform Analytics**:
  - `BookingRepository.fetchAllBookings()`: calculates Gross PKR volume and total counts.
  - `DisputeRepository.fetchAllDisputes()`: calculates active disputes.
  - `WorkerRepository.fetchAllWorkersAdmin()`: calculates verification ratio.
