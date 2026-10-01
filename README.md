# HomeEase: Hyper-Local Domestic Worker Connect Platform

HomeEase is a centralized, secure mobile platform designed to bridge the trust and communication gap in Pakistan's informal domestic worker hiring sector. It connects households directly with nearby, verified domestic workers—such as maids, cooks, cleaners, nannies, and caregivers—replacing informal word-of-mouth hiring systems with a structured, transparent, and secure digital environment.

---

## 🚀 Key Features & Functionalities

### 🏠 For Households (Employers)
* **AI-Based Worker Recommendations (60% Stage)**: Algorithmic matching using Content-Based Vector Similarity (Cosine similarity on skills, Haversine geo-distance, rating normalization) with Explainable AI match percentage badges (e.g., `94% AI Match • 1.2 km away • Desi Cooking`).
* **Post a Job / Gig (Bidirectional Marketplace)**: Publish open tasks specifying required service, Abbottabad neighborhood, date, and budget.
* **Hyper-Local Search**: Discover domestic workers nearby across Abbottabad localities.
* **Instant Booking**: Send job requests with preferred dates, times, addresses, and task details.
* **Service Agreements**: Review and agree to auto-generated service scopes and pricing terms.
* **Manual Payment Logs**: Log manual cash or mobile wallet transfers (EasyPaisa/JazzCash) and upload receipts.
* **Ratings & Feedback**: Submit star ratings and behavioral reviews (punctuality, behavior, and performance).

### 💼 For Domestic Workers (Service Providers)
* **Bidirectional Job Search & Apply (60% Stage)**: Browse a live feed of open household gigs and apply with one tap.
* **Bilingual & Visual Interface (60% Stage)**: Toggle between English and Urdu (`اردو`) with high-affordance pictorial icons tailored for low-literacy workers.
* **Digital Profile Builder**: Create professional profiles detailing skills, charges, experience, and bios.
* **Availability Scheduler**: Configure and update day-of-week slots for job matching.
* **Job Request Manager**: View, accept, or reject incoming household booking requests.
* **Verified Badges**: Gain trusted visibility by submitting identity verification documents for review.

### 🛡️ For Admins (Platform Quality Control)
* **Worker Verification**: Review worker profiles, CNIC scans, and police character certificates.
* **User & Booking Audits**: Monitor platform activity, user accounts, and booking statistics.
* **Dispute Resolution**: Investigate and resolve conflicts related to bookings or manual payments.

---

## 🛠️ Technology Stack
* **Mobile Application**: [Flutter](https://flutter.dev/) & [Dart](https://dart.dev/) (Cross-platform iOS and Android)
* **Admin Web Dashboard**: [React](https://react.dev/) & [Vite](https://vite.dev/) (Vite + TypeScript)
* **Backend Database & Authentication**: [Supabase](https://supabase.com/) (PostgreSQL Database, Auth, Storage, Row-Level Security)
* **State & Navigation**: Interactive Custom Navigation Flow (`home_ease_flow.dart`)

---

## 📁 Repository Structure
```text
HomeEase/
├── Docs/                               # Project requirements and documentation
│   ├── 30 Percent/                     # SRS, SDD, and Diagrams summaries
│   └── Diagrams/                       # Draw.io design sheets
├── HOME_EASE_PROJECT_ORIENTATION.md    # Project overview and timeline
├── Home Ease Project/                  # Codebase Directory
│   ├── MobileApp/                      # Flutter Mobile Project
│   │   └── homeease/
│   │       ├── lib/                    # Dart source code (screens, models, app flows, widgets)
│   │       └── pubspec.yaml            # Project dependencies
│   └── WebApp/                         # React/Vite Admin Web Dashboard (postponed to 60%)
└── README.md                           # Master project guide
```

---

## 🏃 Setup & Installation

### Prerequisites
1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.x stable).
2. Install [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter and Dart extensions.
3. Configure a physical device (enabled for USB debugging) or an emulator.

### Run the Flutter Mobile App

1. **Clone the repository** (or navigate to your local directory):
   ```bash
   git clone https://github.com/your-username/HomeEase.git
   cd HomeEase
   ```

2. **Navigate to the Flutter project folder**:
   ```bash
   cd "Home Ease Project/MobileApp/homeease"
   ```

3. **Fetch project dependencies**:
   ```bash
   flutter pub get
   ```

4. **Verify connected devices**:
   ```bash
   flutter devices
   ```

5. **Run the application**:
   ```bash
   flutter run
   ```

---

## 📈 Roadmap & Milestones
* [x] **30% Milestone**: Design SRS, SDD, database schemas, UML diagrams, and complete client-side mobile screens with mock navigation flow.
* [ ] **60% Milestone**: Supabase database setup, auth integration, geo-location search functions, booking overlap prevention logic, and React admin web dashboard.
* [ ] **100% Milestone**: End-to-end integration testing, system bug fixes, project manual, and thesis submission.
