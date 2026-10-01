# Project: HomeEase (60% FYP Milestone)

## Architecture
HomeEase is a hyper-local domestic worker connect platform in Abbottabad, Pakistan.
- **Frontend / Client**: Flutter 3.41.4 (Dart 3.11.1) mobile application under `Home Ease Project/MobileApp/homeease/`.
- **Backend / BaaS**: Supabase PostgreSQL database, Supabase GoTrue Auth, PostgREST API at `https://oiozlhpogpwlnedzueia.supabase.co`.
- **AI Engine**: Algorithmic Content-Based Vector Recommendation Engine (`ai_recommendation_engine.dart`) combining Cosine skill similarity (0.50), Haversine geographic decay (0.35), Bayesian rating normalization (0.15), and Explainable AI (XAI) transparent badge generation.
- **State & Navigation**: Explicit 17-stage state machine (`HomeEaseFlow`) wrapped in bilingual (EN/UR) responsive layout (`AppScaffold`).

## Code Layout
- Mobile App Root: `c:\Users\AbuZar\Desktop\Fyp\HomeEase\Home Ease Project\MobileApp\homeease`
- `lib/config/supabase_config.dart` — Supabase URL & Anon Key credentials
- `lib/models/worker_profile.dart` — Domain models with `fromMap`/`toMap` serialization
- `lib/services/supabase_auth_service.dart` — Production Supabase authentication & session management
- `lib/services/worker_repository.dart` — Supabase data operations for worker profiles
- `lib/services/job_repository.dart` — Supabase marketplace operations (jobs & applications)
- `lib/services/booking_repository.dart` — Supabase booking operations & time conflict detection
- `lib/services/ai_recommendation_engine.dart` — Algorithmic recommendation engine & XAI badges
- `lib/screens/` — UI screens (auth, search, worker details, marketplace feed, job posting, bookings, dashboard)
- `test/` — Unit, service, and algorithm tests

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Supabase PostgreSQL Core Schema | DDL for profiles, worker_profiles, jobs, job_applications, bookings, reviews | M1 | ORIGINAL_REQUEST §R2 |
| 2 | Automated Database Triggers | on_auth_user_created, sync_worker_rating, touch_updated_at triggers | M1 | survey (explorer_2) |
| 3 | Row Level Security (RLS) | Security policies for all tables and roles (household, worker, admin) | M1 | ORIGINAL_REQUEST §R2 |
| 4 | Abbottabad Seed Dataset | Realistic seed data for Mandian, Jhangi Syedan, Supply Bazaar, Nawan Shehr across 6 trades | M1 | ORIGINAL_REQUEST §R2 |
| 5 | Supabase Flutter Integration | Install `supabase_flutter` in pubspec.yaml, initialize in main.dart | M2 | ORIGINAL_REQUEST §R1 |
| 6 | Supabase Role-Based Auth Service | Implement SupabaseAuthService (sign up, sign in, session persistence, role dispatch) | M2 | ORIGINAL_REQUEST §R1 |
| 7 | Auth Screen Integration | Wire SignInScreen, SignUpScreen, HomeEaseFlow to live SupabaseAuthService | M2 | ORIGINAL_REQUEST §R1 |
| 8 | Model Deserialization Layer | Add `fromMap`/`toMap` serialization to WorkerProfile, JobPost, Booking, Review, etc. | M3 | survey (explorer_1) |
| 9 | Dynamic Worker Search & Listings | Replace sample_data.dart with live PostgREST queries in home_search and worker_list | M3 | ORIGINAL_REQUEST §R3 |
| 10 | AI Recommendation Live Feed | Feed dynamic Supabase worker profiles into AIRecommendationEngine with XAI badges | M3 | ORIGINAL_REQUEST §R3 |
| 11 | Household Job Posting | Persist new job postings from post_job_screen to Supabase `jobs` table | M4 | ORIGINAL_REQUEST §R4 |
| 12 | Worker Job Feed & Apply | Fetch live jobs in worker_job_feed_screen, persist applications in `job_applications` | M4 | ORIGINAL_REQUEST §R4 |
| 13 | Booking Creation & Conflict Check | Interval overlap validation ($S_{req} < E_{exist} \land E_{req} > S_{exist}$) & amount calculation | M4 | ORIGINAL_REQUEST §R5 |
| 14 | Booking History & Dashboard Sync | Live fetch, display, and state transitions (pending, accepted, rejected, completed) | M4 | ORIGINAL_REQUEST §R5 |
| 15 | Static Analysis Remediation | Fix Flutter deprecations in DropdownButtonFormField and RadioListTile for clean analyze | M5 | ORIGINAL_REQUEST §R6 |
| 16 | Comprehensive Test Suite | Unit/service tests in `test/` for auth, repositories, conflict logic, and status transitions | M5 | ORIGINAL_REQUEST §R6 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Supabase Backend Schema & Seed Migration | PostgreSQL schema DDL, RLS, triggers, Abbottabad seed data | none | DONE |
| M2 | Supabase Client & Authentication Layer | `supabase_flutter` integration, SupabaseAuthService, role-based auth flow | M1 | DONE |
| M3 | Dynamic Worker Search & AI Engine | Model mapping, WorkerRepository, live queries, AIRecommendationEngine integration | M2 | DONE |
| M4 | Marketplace & Booking with Conflict Engine | Job posting, job feed & apply, booking creation with interval conflict check, dashboard sync | M3 | DONE |
| M5 | Mobile Architecture Quality & Verification | Static analysis remediation (0 errors/warnings), unit/service test suite execution | M4 | DONE |

## Interface Contracts

### 1. Supabase Backend ↔ SupabaseAuthService
- **Sign Up**: `supabase.auth.signUp(email, password, data: {'full_name': ..., 'role': ...})`
  - Trigger `handle_new_user` on `auth.users` creates `profiles` record.
  - If role == 'worker', inserts initial record into `worker_profiles`.
- **Sign In**: `supabase.auth.signInWithPassword(email, password)`
  - Query `profiles` table to fetch role (`household` | `worker`).
- **Session**: `supabase.auth.currentSession != null`.

### 2. Supabase Data ↔ Mobile Repositories
- **WorkerRepository**:
  - `fetchWorkers({String? category, String? area})`: returns `List<WorkerProfile>` joined from `worker_profiles` and `profiles`.
  - Coordinates: `latitude` (double), `longitude` (double) for Haversine distance calculations.
- **JobRepository**:
  - `fetchOpenJobs()`: returns `List<JobPost>` where `status = 'open'`.
  - `createJob(JobPost post)`: inserts into `jobs`.
  - `applyForJob(JobApplication app)`: inserts into `job_applications`.
- **BookingRepository**:
  - `createBooking(Booking booking)`: checks existing bookings for `worker_id` on `service_date` with `status IN ('pending', 'accepted')`. Rejects if interval overlap exists. Otherwise inserts into `bookings`.
  - `updateBookingStatus(String bookingId, String newStatus)`: updates status to `'accepted'`, `'rejected'`, or `'completed'`.

### 3. Booking Conflict Validation Contract
- An overlap occurs between requested interval $[S_{req}, E_{req})$ and existing booking $[S_{exist}, E_{exist})$ if and only if:
  $$S_{req} < E_{exist} \quad \text{AND} \quad E_{req} > S_{exist}$$
- Conflicting records must trigger a validation error preventing booking creation and notifying the household.
