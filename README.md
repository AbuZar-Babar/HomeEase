# HomeEase — Hyper-Local Domestic Worker Connect Platform (Web)

HomeEase connects Abbottabad households with verified domestic workers (cooks, cleaners, nannies, caregivers, maids, electricians, and plumbers) using Explainable AI worker recommendations, conflict-free booking, a bidirectional job marketplace, escrow payment settlement, and an administrative governance dashboard.

## Running Locally

```bash
npm install
npm run dev
```

The development server listens on `http://0.0.0.0:3000`.

## Quick Demo Accounts (1-Tap Login)

| Role | Email | Password |
| :--- | :--- | :--- |
| **Household** | `household@homeease.com` | `password123` |
| **Worker** | `worker@homeease.com` | `password123` |
| **Admin** | `admin@homeease.com` | `admin123` |

## Core Features

- **Explainable AI (XAI) Worker Matching**: Ranks domestic workers using skill similarity (50%), spherical Haversine distance decay from Abbottabad localities (35%), and Bayesian normalized ratings (15%) with transparent match badges.
- **Conflict-Free Booking & Service Agreements**: Prevents overlapping bookings (`S_req < E_exist && E_req > S_exist`), generates deterministic 4-digit Arrival OTPs, supports Direct Chat, Escrow Payment Gateway (`Easypaisa`, `JazzCash`, `Card`, `COD`) with Digital Receipts, Ratings & Reviews, and Dispute Filing.
- **Bidirectional Job Marketplace**: Households post open gigs and accept worker proposals; workers browse open gigs, submit custom PKR bids, and manage their availability schedule.
- **Bilingual English / Urdu (`اردو`)**: One-click language toggle with automatic RTL layout switching.
- **Admin Governance Dashboard**: Platform analytics, worker CNIC verification queue, dispute arbitration (refund / payout / dismiss), and chronological audit logs.
