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
├── Docs/                               # Project documentation & milestones
│   ├── 00_Project_Specs/               # Core specifications & UI designs
│   ├── 01_Proposal_10/                 # Milestone 1 (10%): Proposal & Defense
│   ├── 02_Requirements_and_Design_30/  # Milestone 2 (30%): SRS, SDD, APK & Diagrams
│   ├── 03_Thesis_60/                   # Milestone 3 (60%): Thesis, Prototype & LaTeX
│   ├── references/                     # External templates & academic benchmarks
│   └── README.md                       # Documentation guide & table of contents
├── Home Ease Project/                  # Codebase Directory
│   ├── MobileApp/                      # Flutter Mobile Project (iOS & Android)
│   │   └── homeease/
│   │       ├── lib/                    # Dart source code (screens, models, app flows, widgets)
│   │       └── pubspec.yaml            # Project dependencies
│   └── WebApp/                         # React/Vite Admin Web Dashboard
└── README.md                           # Master project guide
```

---

## 🏃 Setup & Installation (Zero-Config)

HomeEase is configured for **plug-and-play local execution**. **No `.env` file or environment variables setup is required.** Cloud credentials are embedded into the client configuration with automated, seamless offline/demo fallbacks.

### Prerequisites
1. [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.0.0` stable).
2. [Android Studio](https://developer.android.com/studio), VS Code, or an active browser (Chrome) / desktop target.
3. Connected physical Android phone (USB debugging enabled) or an Android Emulator (or run directly on Chrome / Windows).

---

### Step-by-Step Run Instructions

1. **Clone or Download the Repository**:
   ```bash
   git clone https://github.com/your-username/HomeEase.git
   cd HomeEase
   ```

2. **Navigate to the Flutter App Directory**:
   ```bash
   cd "Home Ease Project/MobileApp/homeease"
   ```

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Verify Connected Devices**:
   ```bash
   flutter devices
   ```

5. **Launch the App**:
   ```bash
   # Run on default connected device or active emulator
   flutter run

   # Or run directly on Web (Chrome)
   flutter run -d chrome

   # Or run directly on Windows Desktop
   flutter run -d windows
   ```

6. **(Optional) Run Automated Test Suite**:
   ```bash
   flutter test
   ```
   *(Verifies all 225 unit, integration, recommendation math, and widget tests passing 100%).*

---

## 🔑 Quick Demo Login (No Sign-Up Required)

The login screen features **1-tap Quick Demo chips** for immediate testing:

| Role | Email | Password | Preloaded Capabilities |
| :--- | :--- | :--- | :--- |
| **🏠 Household** | `household@homeease.com` | `password123` | Search domestic workers, AI match badges, post gigs, book workers |
| **💼 Worker** | `worker@homeease.com` | `password123` | Browse open job feed, submit proposals/bids, manage bookings |

> **Note**: You can either tap the **Household** or **Worker** Quick Demo chip on the sign-in screen to auto-fill these credentials, or register a new user in seconds.

---

## 📈 Roadmap & Milestones
* [x] **30% Milestone**: Design SRS, SDD, database schemas, UML diagrams, and complete client-side mobile screens with interactive navigation.
* [x] **60% Milestone**: Live Supabase backend integration, GoTrue role-based authentication, Explainable AI recommendation engine (Cosine skill match + Haversine distance decay), mathematical conflict detection ($S_{req} < E_{exist} \land E_{req} > S_{exist}$), bidirectional job marketplace, bilingual English/Urdu support, and 100% test pass rate (225/225 tests).
* [ ] **100% Milestone**: React/Vite admin web dashboard, end-to-end user evaluation, system bug fixes, and final thesis defense.
