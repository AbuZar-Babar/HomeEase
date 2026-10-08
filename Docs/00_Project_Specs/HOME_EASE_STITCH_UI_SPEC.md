# HomeEase — Google Stitch Mobile UI Design System & Screen Catalogue

## 1. Project Overview & Stitch Link
- **Project Title:** `HomeEase - Domestic Worker Marketplace`
- **Stitch Project ID:** `6252619078293577022`
- **Google Stitch Web Access:** [Google Labs Stitch](https://labs.google.com/stitch)
- **Target Platform:** Mobile (iOS / Android 390px responsive)
- **Design Paradigm:** Light-Mode First, Minimalist, High Contrast, Anti-Slop Professionalism

---

## 2. Design System Tokens & Hierarchy

### Core Color Palette
| Token | Hex | Role |
|---|---|---|
| **Canvas White** | `#F8FAFC` (Slate-50) | Primary background substrate |
| **Pure Surface** | `#FFFFFF` | Card containers, bottom sheets, navigation bar |
| **Deep Teal** | `#0F766E` (Teal-700) | Primary brand color, main CTAs, active indicators |
| **Mint Tint** | `#CCFBF1` (Teal-100) | Highlight badges, active category chips, XAI badges |
| **Charcoal Ink** | `#0F172A` (Slate-900) | High-contrast readable typography (WCAG AAA) |
| **Muted Steel** | `#64748B` (Slate-500) | Helper text, secondary metadata, inactive icons |
| **Whisper Border** | `#E2E8F0` (Slate-200) | Razor-thin 1px structural boundaries on cards & inputs |
| **Safety Emerald** | `#10B981` (Emerald-500) | NADRA CNIC verified shield, confirmed booking status |
| **Warm Amber** | `#F59E0B` (Amber-500) | Rating stars, pending state alerts |
| **Alert Crimson** | `#EF4444` (Red-500) | Time conflicts, dispute alerts |

### Typography Architecture
- **Primary Typeface:** `Plus Jakarta Sans`
- **Headings:** Track-tight (-0.02em), bold weights (600/700) for structured visual anchors.
- **Body & Labels:** 14px/15px with relaxed 1.4x line-height for seamless English & Urdu reading.
- **Tabular Figures:** Tabular numeric alignment for PKR pricing (`Rs. 850/hr`), distance (`1.2 km`), and ratings (`4.9 ★`).

---

## 3. Screen Catalogue

### Screen 1: Onboarding & Role Selection (Welcome Flow)
- **Screen ID:** `0d0e9f215cd4472d976b406b64e75d29`
- **Components:**
  - Bilingual switcher pill (`English` / `اردو`)
  - Hero branding: Geometric HomeEase logo & clear value proposition
  - NADRA CNIC verified trust highlight banner
  - Role selection platter cards: **Household** vs **Service Provider**
  - High-touch solid Deep Teal primary action button (`Get Started`)

### Screen 2: Household Home & Worker Discovery Feed
- **Screen ID:** `7cfd40d6d320479fb0e1636c8915dc42`
- **Components:**
  - Abbottabad neighborhood selector dropdown (`Mandian`, `Supply Bazaar`, `Jhangi`)
  - Search input with category filter drawer trigger
  - Horizontal trade pill selector (`Plumbing`, `Electrician`, `Cleaning`, `Cooking`, `Carpentry`, `Painting`)
  - **Algorithmic AI Match Card:** Transparent explainable badge (`98% Match · 0.8 km · Skill Match + Verified CNIC`)
  - Verified worker cards with Haversine distance, hourly rate, and direct quick-book CTA
  - Persistent 4-tab bottom navigation (`Discover`, `Post Job`, `Bookings`, `Profile`)

### Screen 3: Worker Profile & Authentic Reviews Detail
- **Screen ID:** `b07086c54b964a94bbed9fd4908a2994`
- **Components:**
  - Verified provider hero: Avatar, CNIC verified badge, rating & completed jobs count
  - Verified credentials chip: NADRA database verification & background check
  - Skills & service specialization chips
  - Transparent pricing box: `PKR 850 / hour` with callout inclusions
  - Client review timeline with verified Abbottabad client testimonials
  - Dual action bottom bar: `Call / WhatsApp` + `Book Appointment`

### Screen 4: Schedule Service Booking & Conflict Engine
- **Screen ID:** `614675c96d1d4417ad30b1218e4813ec`
- **Components:**
  - Provider summary header card
  - Horizontal date picker carousel (`Today`, `Tomorrow`, `Pick Date`)
  - Interval time slot picker (`09:00 AM - 11:00 AM`, `11:00 AM - 01:00 PM`)
  - **Conflict Engine Status Banner:** Live interval verification (`Slot Available · No Scheduling Conflict`)
  - Service address input with Abbottabad neighborhood picker
  - Itemized transparent cost calculation (`Base Hours + Platform Safety Fee = Total PKR`)
  - `Confirm & Send Booking Request` primary action

### Screen 5: Post a Domestic Job Request (Quick Hire)
- **Components:**
  - Service category selector dropdown
  - Job title & task description fields
  - Abbottabad area selector
  - Budget model toggle (`Fixed Price` vs `Hourly Rate`) with fair rate recommendation
  - Urgency chips (`Urgent Today`, `Within 48h`, `Flexible`)
  - Dotted photo attachment upload card
  - `Publish Job to Verified Workers` primary CTA

### Screen 6: Worker Dashboard & Live Marketplace Job Feed
- **Components:**
  - Online/Offline availability toggle with emerald status dot
  - Metric overview cards (`Today's Earnings PKR`, `Active Jobs`, `Rating`)
  - Live job request feed sorted by distance from worker
  - Fast-action card: Job details, budget PKR, one-tap `Apply for Job` and `Pass`

### Screen 7: Bookings History & Active Service Tracker
- **Components:**
  - Status segmented tabs (`Active`, `Upcoming`, `Completed`, `Cancelled`)
  - Active booking card with live ETA and status pill (`Provider On The Way`)
  - 4-digit **Service Start OTP** box (`OTP: 8492`) for household security
  - Post-service review card with star rating and receipt download

### Screen 8: Dispute Resolution & Safety Center
- **Components:**
  - Linked booking dropdown
  - Category selection grid (`No Show`, `Pricing Conflict`, `Quality Issue`, `Safety`)
  - Problem description & photo evidence upload box
  - 24/7 Abbottabad emergency hotline & WhatsApp mediation bridge
  - `Submit Dispute for Investigation` with 2-hour SLA guarantee
