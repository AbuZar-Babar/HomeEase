# HomeEase Mobile Application

A cross-platform Flutter application connecting households in Pakistan with verified domestic workers (maids, cooks, cleaners, nannies, caregivers, plumbers, and electricians).

---

## ⚡ Quick Start (Zero-Config)

This project is fully self-contained. **No `.env` file or manual configuration is required.**

### 1. Fetch Dependencies
```bash
flutter pub get
```

### 2. Verify Devices
```bash
flutter devices
```

### 3. Run the Application
```bash
# Default device (Android Emulator or USB Debugging Device)
flutter run

# Web / Chrome
flutter run -d chrome

# Windows Desktop
flutter run -d windows
```

---

## 🔑 Preloaded Demo Accounts

The sign-in screen contains **1-tap Quick Demo buttons** (`Household` and `Worker`):

- **Household Employer**:
  - Email: `household@homeease.com`
  - Password: `password123`
  - Role: Household
- **Domestic Worker**:
  - Email: `worker@homeease.com`
  - Password: `password123`
  - Role: Worker

---

## 🧪 Testing & Code Quality

Run static analysis and the automated test suite:

```bash
# Static analysis (0 warnings / 0 errors)
flutter analyze

# Comprehensive test suite (225 tests)
flutter test
```

---

## 🏗️ Architecture & Features

- **Backend & Auth**: [Supabase](https://supabase.com/) with GoTrue role-based access control and PostgreSQL Row-Level Security (RLS).
- **Graceful Offline Mode**: Automated fallback to local mock data and conflict detection if offline or uninitialized.
- **Explainable AI Matching**: Content-based Cosine similarity on trade skills + Haversine spatial decay across Abbottabad localities (`Mandian`, `Jhangi Syedan`, `Supply Bazaar`, `Nawan Shehr`, `PMA Kakul Road`).
- **Conflict-Free Scheduling**: Mathematical interval overlap detection ($S_{req} < E_{exist} \land E_{req} > S_{exist}$).
- **Bilingual Support**: Instant toggle between English and Urdu (`اردو`) with high-affordance pictorial icons.
