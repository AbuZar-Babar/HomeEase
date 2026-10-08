# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users
- **Household Employers**: Families and residents in Abbottabad (Mandian, Jhangi Syedan, Supply Bazaar, Nawan Shehr, PMA Kakul Road) seeking vetted, reliable domestic help (cooks, maids, cleaners, nannies, caregivers).
- **Domestic Workers**: Local service professionals in Abbottabad looking for transparent daily gig opportunities, direct household contact, fair pricing, and clear terms without exploitation.

## Product Purpose
HomeEase bridges the informal domestic labor market in Abbottabad with a hyper-local, transparent mobile marketplace. It replaces word-of-mouth uncertainty with verified worker identity, transparent wage ranges, interval conflict-free booking, and an explainable AI recommendation engine tailored for local geography.

## Positioning
Unlike generic gig platforms or unverified classified listings, HomeEase is engineered specifically for hyper-local Abbottabad domestic labor dynamics: combining algorithmic multi-objective worker matching (Cosine skill matching, Haversine geographic decay, Bayesian rating normalization) with Explainable AI badges, bilateral gig posting, and bilingual (English/Urdu RTL) accessibility designed for varied literacy levels.

## Operating Context
- Urban and peri-urban Abbottabad neighborhoods with distinct transit corridors and steep topography.
- Dual-mode marketplace: direct worker discovery/booking by households, or open gig posting with counter-bidding by workers.
- Physical in-person household visits requiring clear safety verification, agreed timing, and dispute remediation.

## Capabilities and Constraints
- **Core Capabilities**:
  - Role-based authentication (Household vs. Worker) with persistent Supabase sessions.
  - Multi-trade discovery: Cook, Cleaner, Nanny, Caregiver, Maid.
  - Transparent XAI Scoring: 0–100% match indicator with human-readable rationale chips (Skill Match, Nearby, Top Rated).
  - Bilateral Marketplace: Households publish open job gigs; workers submit rate proposals.
  - Conflict-Free Booking Engine: Mathematical interval overlap detection ($S_{req} < E_{exist} \land E_{req} > S_{exist}$) preventing double-booking.
  - Service Agreement & Receipt Verification: In-app workflow for job execution, completion confirmation, and dispute lodging.
- **Constraints**:
  - Offline-resilient and low-data mobile performance on Android devices.
  - Zero mock/dummy data in live runs; strict adherence to Supabase PostgreSQL schema.
  - Strict touch target standards (>= 48x48 dp) and full Urdu localization (Nastaliq-friendly RTL typography).

## Brand Commitments
- **Name**: HomeEase (گھر کی سہولت).
- **Palette**: Deep Teal Trust (`#0F766E`), Warm Amber (`#D97706`), clean surface neutrals.
- **Voice**: Respectful, dignified, reassuring, and community-centered. Avoid condescending or corporate bureaucratic language.

## Evidence on Hand
- Supabase PostgreSQL schema with 6 tables (`profiles`, `worker_profiles`, `jobs`, `job_applications`, `bookings`, `reviews`) deployed at `wgspffihkfdrqdrfndot.supabase.co`.
- Complete test suite: 225/225 tests passing in `test/`.
- Localized Abbottabad geographic coordinate matrix (`Mandian`, `Jhangi Syedan`, `Supply Bazaar`, `Nawan Shehr`, `PMA Kakul Road`).
- Fully implemented Flutter client with zero static analysis warnings.

## Product Principles
1. **Dignity & Transparency First**: Respect domestic labor with transparent compensation, clear scope, and mutual agreement protections.
2. **Explainable Recommendations**: Never show opaque black-box scores; explain why a worker is suggested (skills, locality, track record).
3. **Frictionless Affordance**: Simple touch targets, clear iconography, and fluent Urdu support ensure workers of all literacy levels can confidently accept work.
4. **Zero-Conflict Scheduling**: Guard both worker and household time by strictly preventing overlapping bookings.

## Accessibility & Inclusion
- Full bilingual English and Urdu (RTL) localization with one-tap language switcher.
- Minimum 48x48 dp touch targets across all interactive buttons, cards, and chips.
- Clear visual status badges with color and icon redundancy (never color alone).
- High-contrast text readability adhering to WCAG 2.1 AA standards.
