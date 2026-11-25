# HomeEase

A mobile-first, bilingual (English & Urdu RTL) domestic services marketplace built for Abbottabad, Pakistan. HomeEase connects households with NADRA CNIC-verified cooks, cleaners, nannies, caregivers, maids, electricians, and plumbers using Explainable AI (XAI) matching, interactive Google Maps discovery, recurring household plans, arrival OTP verification with live safety check-ins, and administrative governance.

## Features

- **Mobile-First Experience**: Thumb-zone bottom tab bar per user role, slide-up bottom sheets, master-detail booking inspection, safe-area support, and responsive multi-column desktop layout.
- **Branded Entry Flow**: Animated splash screen, first-time 3-step interactive onboarding showcase, and split authentication with one-tap demo sign-in.
- **Explainable AI Matching & Abbottabad Map**: Ranks specialists by skill fit (`50%`), Haversine neighborhood proximity (`35%`), and verified household rating (`15%`) across Grid view and an interactive Google Map (`@vis.gl/react-google-maps` with `AdvancedMarker` and graceful fallback).
- **Recurring Plans & Conflict Prevention**: Supports One-Time, Bi-Weekly (`5%` off), Weekly (`10%` off), and Monthly (`15%` off) plans backed by interval-overlap conflict detection (`S_req < E_exist && E_req > S_exist`).
- **Active Session Safety Console**: 4-digit Arrival OTP starts a live ticking session timer, timestamped safety check-ins, saved emergency contact with live visit summary sharing, and guarded emergency alerts dispatched to the Admin Governance desk.
- **Worker Profile Builder & Admin Verification**: Workers edit skills/rates and upload NADRA CNIC & Police Character Certificate image previews that sync directly into the Admin Verification desk, alongside Dispute Arbitration and Audit Logs.
- **Bilingual & Theme Parity**: Full English / Urdu (`اردو`) RTL layout support and Light / Dark themes persisted in versioned `localStorage` (with a Reset Demo Data utility).

## Tech Stack

| Layer | Technology |
| :--- | :--- |
| **Framework** | React 19 + TypeScript 5 |
| **Build Tool** | Vite 6 |
| **Styling** | Tailwind CSS v4 |
| **Mapping** | Google Maps Platform (`@vis.gl/react-google-maps`) |
| **Icons** | `lucide-react` |
| **Persistence** | Versioned `localStorage` state store |

## Project Structure

```text
.
├── Docs/                        # Academic deliverables (proposal, SRS, SDD, thesis)
├── src/
│   ├── assets/images/           # Editorial photography & studio worker portraits
│   ├── components/
│   │   ├── AbbottabadWorkerMap.tsx
│   │   ├── AdminDashboard.tsx
│   │   ├── AuthScreen.tsx
│   │   ├── BookingAndAgreementViews.tsx
│   │   ├── EntryExperience.tsx
│   │   ├── HouseholdViews.tsx
│   │   ├── WorkerAvatar.tsx
│   │   └── WorkerViews.tsx
│   ├── data/sampleData.ts       # Seed data, localities, recurring plans
│   ├── services/
│   │   ├── engines.ts           # XAI matching, conflict detection, plan pricing
│   │   ├── localization.ts      # English & Urdu (RTL) translations
│   │   └── storage.ts           # Versioned localStorage persistence & demo reset
│   ├── App.tsx                  # App shell, navigation, state orchestration
│   ├── index.css                # Tailwind v4 theme, typography, mobile utilities
│   ├── main.tsx                 # Bootstrap & Maps quota listeners
│   └── types.ts                 # Shared TypeScript domain models
├── .editorconfig
├── .env.example
├── .gitignore
├── index.html
├── package.json
├── tsconfig.json
└── vite.config.ts
```

## Getting Started

```bash
# 1. Install dependencies
npm install

# 2. Configure environment variables (optional — interactive fallback map works without a key)
cp .env.example .env

# 3. Start the development server on http://localhost:3000
npm run dev
```

### Available Scripts

| Command | Description |
| :--- | :--- |
| `npm run dev` | Start Vite dev server on `0.0.0.0:3000` |
| `npm run lint` | Run strict TypeScript typechecking (`tsc --noEmit`) |
| `npm run build` | Typecheck and build production bundle to `dist/` |
| `npm run preview` | Preview the production build locally on port `3000` |

## Demo Accounts

| Role | Email | Password |
| :--- | :--- | :--- |
| **Household** | `household@homeease.com` | `password123` |
| **Worker** | `worker@homeease.com` | `password123` |
| **Admin** | `admin@homeease.com` | `admin123` |
