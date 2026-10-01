# HomeEase — Test Infrastructure & 4-Tier Verification Architecture

**Project:** HomeEase (Hyper-Local Domestic Worker Connect Platform — Abbottabad, Pakistan)  
**Milestone:** 60% Final Year Project (FYP) Milestone  
**Target Environment:** Flutter 3.41.4 • Dart 3.11.1 • Supabase PostgreSQL BaaS  
**Author:** test_writer_e2e (E2E Testing Architect)  
**Date:** 2026-10-01  

---

## 1. Executive Summary

This document defines the comprehensive End-to-End (E2E) testing architecture for the HomeEase mobile platform. To ensure production-grade reliability across authentication, geospatial worker matching, the bidirectional marketplace, and the booking engine with time-slot conflict detection, HomeEase employs a rigorous **4-Tier Testing Methodology**:

- **Tier 1: Feature Coverage (>=5 test cases per feature)** — Validates nominal operation, primary happy paths, and fundamental domain logic.
- **Tier 2: Boundary, Corner & Adversarial Cases (>=5 test cases per feature)** — Stresses limits, extreme values, empty inputs, leap conditions, and adversarial inputs.
- **Tier 3: Pairwise & Combinatorial Testing** — Evaluates orthogonal interaction spaces across user roles, Abbottabad localities, trade categories, and payment schemes.
- **Tier 4: Real-World Scenarios / E2E Journeys** — Simulates full multi-party lifecycles from registration through AI search, booking, conflict resolution, payment submission, and multi-criteria review.

---

## 2. The 4-Tier Testing Architecture

```
+-------------------------------------------------------------------------+
|                  TIER 4: REAL-WORLD E2E SCENARIOS                       |
|   Complete User Lifecycles • Multi-Role Interaction • State Transitions |
+-------------------------------------------------------------------------+
                                    ^
+-------------------------------------------------------------------------+
|                  TIER 3: PAIRWISE COMBINATORIAL TESTING                 |
|   Roles (2) x Localities (5) x Trades (6) x Payments (4) x Statuses (5) |
+-------------------------------------------------------------------------+
                                    ^
+-------------------------------------------------------------------------+
|                  TIER 2: BOUNDARY & CORNER CASE TESTING                 |
|   Zero Distance • Zero Reviews • Overlap Boundaries • Extreme Budgets   |
+-------------------------------------------------------------------------+
                                    ^
+-------------------------------------------------------------------------+
|                  TIER 1: CORE FEATURE & UNIT COVERAGE                   |
|   Auth • Deserialization • Haversine • Cosine Match • Conflict Check    |
+-------------------------------------------------------------------------+
```

---

## 3. Feature Specifications & 4-Tier Test Matrix

### Feature 1: Authentication & Role-Based Access Control (RBAC)

- **Scope:** Supabase GoTrue Auth, session persistence, role separation (`household` vs `worker`), credential validation.
- **Interface Contract:**
  - `signUp({name, email, phone, password, role}) -> AppUser`
  - `signIn(email, password, role) -> AppUser?`
  - `signOut() -> void`
  - `currentUser -> AppUser?`

| Tier | Test ID | Scenario Description | Expected Outcome |
| :--- | :--- | :--- | :--- |
| **Tier 1** | AUTH-T1-01 | Household user registration with valid parameters | Creates `AppUser` with `role = 'Household'`, session set, status `'Active'` |
| **Tier 1** | AUTH-T1-02 | Worker user registration with valid parameters | Creates `AppUser` with `role = 'Worker'`, session set, status `'Active'` |
| **Tier 1** | AUTH-T1-03 | Sign in with valid household credentials | Returns valid `AppUser`, sets `currentUser` |
| **Tier 1** | AUTH-T1-04 | Sign in with valid worker credentials | Returns valid `AppUser`, sets `currentUser` |
| **Tier 1** | AUTH-T1-05 | Sign out of active session | Sets `currentUser` to null, revokes session |
| **Tier 2** | AUTH-T2-01 | Case-insensitive email normalization on sign-in | `WORKER@HomeEase.com` resolves successfully to `worker@homeease.com` |
| **Tier 2** | AUTH-T2-02 | Whitespace trimming on email inputs | Leading/trailing spaces (`  user@test.com  `) trimmed before auth |
| **Tier 2** | AUTH-T2-03 | Sign in with incorrect password | Returns `null`, does not mutate active session |
| **Tier 2** | AUTH-T2-04 | Sign in with mismatched role (household user trying worker role) | Rejects sign-in or returns null due to role mismatch |
| **Tier 2** | AUTH-T2-05 | Sign in with unregistered email | Returns `null` without throwing unhandled exception |
| **Tier 3** | AUTH-T3-01 | Pairwise: Role (`Household`, `Worker`) x Domain Formats (`.com`, `.pk`, `.edu.pk`) | All 6 combinations parse correctly and maintain strict role boundaries |
| **Tier 4** | AUTH-T4-01 | Registration, session switch, sign out, and re-login journey | User registers, signs out, re-authenticates with new session tokens verified |

---

### Feature 2: Worker Repository & AI Recommendation Engine

- **Scope:** PostgREST worker profile querying, spherical Haversine distance, Cosine skill similarity, Bayesian rating normalization, cold-start handling, and Explainable AI (XAI) transparent badge generation.
- **Mathematical Formulations:**
  - **Haversine Distance:**
    $$d = 2 R \arcsin \left( \sqrt{ \sin^2\left(\frac{\Delta \phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta \lambda}{2}\right) } \right)$$
    where $R = 6371.0\text{ km}$, $\phi$ is latitude in radians, $\lambda$ is longitude in radians.
  - **Skill Cosine Similarity:**
    $$S_{\text{skill}} = 0.4 \cdot S_{\text{cat}} + 0.6 \cdot \frac{|T_{\text{pref}} \cap T_{\text{worker}}|}{|T_{\text{pref}}|}$$
  - **Hyperbolic Distance Decay:**
    $$S_{\text{geo}} = \frac{1}{1 + 0.2 \cdot d_{\text{km}}}$$
  - **Bayesian Rating Normalization & Cold Start:**
    $$S_{\text{rating}} = \begin{cases} \frac{R - 1.0}{4.0}, & \text{if } N > 0 \\ \frac{3.5 - 1.0}{4.0} = 0.625, & \text{if } N = 0 \text{ (Cold Start Prior)} \end{cases}$$
  - **Composite Score:**
    $$\text{Score} = 0.50 \cdot S_{\text{skill}} + 0.35 \cdot S_{\text{geo}} + 0.15 \cdot S_{\text{rating}}$$

| Tier | Test ID | Scenario Description | Expected Outcome |
| :--- | :--- | :--- | :--- |
| **Tier 1** | AI-T1-01 | Haversine distance calculation between Abbottabad localities | Mandian (34.1983, 73.2425) to Jhangi (34.1750, 73.2280) is $2.7 \pm 0.4\text{ km}$ |
| **Tier 1** | AI-T1-02 | Cosine skill similarity for direct trade match | Exact trade match yields score $> 0.70$ |
| **Tier 1** | AI-T1-03 | Rating normalization for established 5-star worker | $R = 5.0, N = 20 \implies S_{\text{rating}} = 1.0$ |
| **Tier 1** | AI-T1-04 | Composite score ranking monotonicity | Worker with higher skill match and closer distance ranks strictly above lower candidate |
| **Tier 1** | AI-T1-05 | Explainable AI (XAI) badge formatting | Generates string containing `"[N]% AI Match • [D] km • [Locality]"` |
| **Tier 2** | AI-T2-01 | Self-distance calculation (identical coordinates) | Distance strictly equals $0.0\text{ km}$; $S_{\text{geo}} = 1.0$ (no division by zero) |
| **Tier 2** | AI-T2-02 | Cold-start worker with zero reviews ($N=0$) | Receives neutral prior $R = 3.5$ ($S_{\text{rating}} = 0.625$), preventing score collapse |
| **Tier 2** | AI-T2-03 | Worker with zero matching skills | $S_{\text{skill}}$ evaluates to base non-match minimum ($0.30 \times 0.4 = 0.12$), not crashing |
| **Tier 2** | AI-T2-04 | Distant worker ($> 50\text{ km}$ outside Abbottabad) | $S_{\text{geo}}$ decays smoothly towards zero ($S_{\text{geo}} < 0.10$) without negative score |
| **Tier 2** | AI-T2-05 | Worker profile with empty bio and empty skill tags | Safe evaluation with fallback trade category scoring |
| **Tier 3** | AI-T3-01 | Pairwise: 6 Trades x 5 Localities Abbottabad Grid | Evaluates 30 location-trade combinations confirming rank stability across city sectors |
| **Tier 4** | AI-T4-01 | Household dynamic search & AI ranking journey | Household filters by "Cook" in "Mandian"; AI ranks Rabia Bibi at top with transparent reasoning badges |

---

### Feature 3: Bidirectional Marketplace (Jobs & Applications)

- **Scope:** Household gig posting (`jobs`), worker job feed (`worker_job_feed_screen`), worker bidding with proposed rates (`job_applications`), duplicate bid protection.
- **Interface Contract:**
  - `JobPost` creation, status lifecycle (`open` -> `assigned` -> `completed` -> `cancelled`)
  - `JobApplication` creation, status lifecycle (`pending` -> `accepted` -> `rejected`)

| Tier | Test ID | Scenario Description | Expected Outcome |
| :--- | :--- | :--- | :--- |
| **Tier 1** | MKT-T1-01 | JobPost model instantiation and property integrity | All fields populated, default status `'open'`, budget non-negative |
| **Tier 1** | MKT-T1-02 | Worker application instantiation with proposed rate | `JobApplication` created with worker details, proposed budget, status `'pending'` |
| **Tier 1** | MKT-T1-03 | Marketplace feed filtering by service category | Filtering by `'Cook'` returns only Cook job posts |
| **Tier 1** | MKT-T1-04 | Marketplace feed filtering by locality | Filtering by `'Mandian'` returns only Mandian jobs |
| **Tier 1** | MKT-T1-05 | Active jobs exclusion of closed/cancelled gigs | Jobs with status `'completed'` or `'cancelled'` excluded from worker feed |
| **Tier 2** | MKT-T2-01 | Job post with minimum allowed budget (PKR 500) | Successfully accepted and stored |
| **Tier 2** | MKT-T2-02 | Worker application proposing counter-bid rate higher than budget | Allowed; stores higher proposed rate transparently |
| **Tier 2** | MKT-T2-03 | Worker application proposing counter-bid rate lower than budget | Allowed; stores lower proposed rate transparently |
| **Tier 2** | MKT-T2-04 | Long multi-line task description with Urdu/English Unicode text | Text preserved without truncation or character corruption |
| **Tier 2** | MKT-T2-05 | Duplicate application prevention by same worker on same job | Second application rejected or marked existing |
| **Tier 3** | MKT-T3-01 | Pairwise: 5 Categories x 5 Localities x 3 Budget Tiers (Low/Med/High) | 75 matrix permutations verified for model serialization and filtering integrity |
| **Tier 4** | MKT-T4-01 | End-to-End Marketplace lifecycle journey | Household posts "Deep House Cleaning" in Supply Bazaar -> Worker Sana Gul browses feed -> submits application with PKR 4,000 counter-offer -> application status transitions to `'accepted'` |

---

### Feature 4: Booking Creation & Conflict Check Engine

- **Scope:** Household booking creation, service time duration calculation, amount calculation ($Amount = Duration \times Rate$), interval overlap detection ($S_{req} < E_{exist} \land E_{req} > S_{exist}$), and booking lifecycle status transitions (`Pending` -> `Accepted`/`Rejected` -> `Completed` -> `Disputed`).
- **Conflict Algorithmic Specification:**
  - Let requested booking interval on date $D$ be $[S_{req}, E_{req})$.
  - Let existing active booking on same date $D$ for worker $W$ be $[S_{exist}, E_{exist})$ where $\text{status} \in \{\text{'pending'}, \text{'accepted'}, \text{'in\_progress'}\}$.
  - **Conflict Condition:**
    $$\text{Conflict} \iff (S_{req} < E_{exist}) \land (E_{req} > S_{exist})$$
  - Cancelled or Rejected bookings **NEVER** trigger a conflict.

| Tier | Test ID | Scenario Description | Expected Outcome |
| :--- | :--- | :--- | :--- |
| **Tier 1** | BKG-T1-01 | Booking creation with valid date, slot, and address | Booking created with status `'Pending'`, correct duration and agreed amount |
| **Tier 1** | BKG-T1-02 | Direct overlap conflict detection on same date | Requested `10:00 - 12:00` against existing `11:00 - 13:00` returns `hasConflict = true` |
| **Tier 1** | BKG-T1-03 | Non-overlapping consecutive booking slots | Requested `12:00 - 14:00` against existing `10:00 - 12:00` returns `hasConflict = false` |
| **Tier 1** | BKG-T1-04 | Same time slot on different dates | Slot `10:00 - 12:00` on Day A does not conflict with same slot on Day B |
| **Tier 1** | BKG-T1-05 | Worker accepts booking request | Status transitions from `'Pending'` to `'Accepted'` |
| **Tier 2** | BKG-T2-01 | Enclosing interval overlap ($S_{req} < S_{exist} \land E_{req} > E_{exist}$) | Requested `09:00 - 14:00` completely engulfs existing `10:00 - 12:00`; returns conflict |
| **Tier 2** | BKG-T2-02 | Internal sub-interval overlap ($S_{req} > S_{exist} \land E_{req} < E_{exist}$) | Requested `10:30 - 11:30` inside existing `10:00 - 12:00`; returns conflict |
| **Tier 2** | BKG-T2-03 | Inactive booking status immunity (Cancelled/Rejected) | Slot identical to a `'Cancelled'` or `'Rejected'` booking returns `hasConflict = false` |
| **Tier 2** | BKG-T2-04 | Dynamic total amount calculation ($Hours \times HourlyRate$) | 3.5 hours at PKR 1,000/hr yields exactly PKR 3,500.00 (not hardcoded 2,500) |
| **Tier 2** | BKG-T2-05 | Invalid interval rejection ($S_{req} \ge E_{req}$) | Attempting start `14:00` and end `12:00` rejected by validation |
| **Tier 3** | BKG-T3-01 | Pairwise: 4 Statuses x 4 Payment Methods (`cash`, `easypaisa`, `jazzcash`, `bank`) | 16 combinations verified for status transition validity |
| **Tier 4** | BKG-T4-01 | End-to-End Booking & Conflict Prevention Journey | Household A books Rabia Bibi `10:00-12:00` -> Household B attempts `11:30-13:30` and is blocked by conflict engine -> Household B picks `13:00-15:00` (succeeds) -> Rabia accepts Household A -> Service completes -> Review submitted |

---

### Feature 5: Bilingual Localization & Affordance Layer

- **Scope:** English / Urdu toggle (`LocalizationService`), TextDirectionality (`LTR` vs `RTL`), domestic trade iconography and thematic color mapping.

| Tier | Test ID | Scenario Description | Expected Outcome |
| :--- | :--- | :--- | :--- |
| **Tier 1** | LOC-T1-01 | English to Urdu language toggle | `LocalizationService.isUrdu` flips to `true`, direction becomes `TextDirection.rtl` |
| **Tier 1** | LOC-T1-02 | Urdu translation string retrieval | `tr('appTitle')` returns `'ہوم ایز'`, `tr('postAJob')` returns `'نیا کام / جاب پوسٹ کریں'` |
| **Tier 1** | LOC-T1-03 | Trade category iconography mapping | Category `'Cook'` maps to `Icons.restaurant_rounded`, `'Cleaner'` to `Icons.cleaning_services_rounded` |
| **Tier 1** | LOC-T1-04 | Trade category thematic color distinction | Unique distinct color themes assigned across domestic categories |
| **Tier 1** | LOC-T1-05 | Urdu to English toggle restoration | `LocalizationService.isUrdu` returns to `false`, direction becomes `TextDirection.ltr` |
| **Tier 2** | LOC-T2-01 | Fallback key handling for undefined translation keys | Returns key string as-is without crashing or throwing null error |
| **Tier 2** | LOC-T2-02 | Category icon lookup for unknown trade | Returns safe fallback icon (`Icons.handyman_rounded`) |
| **Tier 2** | LOC-T2-03 | Category color lookup for unknown trade | Returns safe primary theme fallback color |
| **Tier 2** | LOC-T2-04 | Rapid consecutive language toggles | Maintains consistent state without memory leaks |
| **Tier 2** | LOC-T2-05 | Numeric and currency formatting in Urdu mode | Formats PKR currency strings with readable spacing |
| **Tier 3** | LOC-T3-01 | Pairwise: 2 Languages x 6 Categories x 5 Localities | All 60 localized combinations return valid non-null headers and labels |
| **Tier 4** | LOC-T4-01 | Complete Bilingual App Navigation Journey | App launches in EN -> user toggles to Urdu -> browses worker feed in RTL -> initiates booking -> toggles back to EN |

---

## 4. Test Suite Mapping & Directory Layout

All tests are located in `Home Ease Project/MobileApp/homeease/test/`:

```
test/
├── ai_recommendation_engine_test.dart       # Mathematical ranking, Haversine, Cosine, XAI badges
├── auth_service_test.dart                   # Tier 1-4 Auth, Role dispatch, and Session validation
├── booking_conflict_test.dart               # Tier 1-4 Booking creation, Conflict formula, and Status transitions
├── marketplace_test.dart                    # Tier 1-4 Job posting, Application bidding, and Category filtering
├── worker_repository_ai_scoring_test.dart   # Tier 1-4 Worker models, Spatial decay, and Cold-start priors
└── widget_test.dart                         # Splash screen animation and onboarding navigation
```

---

## 5. Verification Commands & Quality Gates

### Running All Tests
```powershell
cd "c:\Users\AbuZar\Desktop\Fyp\HomeEase\Home Ease Project\MobileApp\homeease"
flutter test
```

### Running Individual Test Suites
```powershell
# Authentication & RBAC Suite
flutter test test/auth_service_test.dart

# Worker Repository & AI Scoring Suite
flutter test test/worker_repository_ai_scoring_test.dart

# Marketplace Suite
flutter test test/marketplace_test.dart

# Booking Conflict & Lifecycle Suite
flutter test test/booking_conflict_test.dart
```

### Static Analysis Quality Gate
```powershell
flutter analyze
```
*Quality Criteria:* Zero compilation errors, zero warnings.

---

## 6. Traceability Matrix

| Requirement (ORIGINAL_REQUEST.md) | Feature (PROJECT.md) | Test Suite | Minimum Test Cases |
| :--- | :--- | :--- | :--- |
| **R1**: Role-Based Auth | Feature 6, 7 | `test/auth_service_test.dart` | 10+ cases (Tier 1-4) |
| **R2**: Schema & Seed | Feature 1, 4, 8 | `test/worker_repository_ai_scoring_test.dart` | 10+ cases (Tier 1-4) |
| **R3**: AI Recommendation Engine | Feature 9, 10 | `test/worker_repository_ai_scoring_test.dart` & `test/ai_recommendation_engine_test.dart` | 15+ cases (Tier 1-4) |
| **R4**: Bidirectional Marketplace | Feature 11, 12 | `test/marketplace_test.dart` | 10+ cases (Tier 1-4) |
| **R5**: Booking & Conflict Check | Feature 13, 14 | `test/booking_conflict_test.dart` | 15+ cases (Tier 1-4) |
| **R6**: Bilingual & UI Quality | Feature 15, 16 | `test/ai_recommendation_engine_test.dart` & `test/widget_test.dart` | 10+ cases (Tier 1-4) |
