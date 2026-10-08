---
name: HomeEase
description: Hyper-local domestic services marketplace connecting households and verified workers in Abbottabad
colors:
  primary: "#0F766E"
  primary-dark: "#115E59"
  primary-light: "#CCFBF1"
  secondary: "#14B8A6"
  status-verified: "#10B981"
  status-pending: "#F59E0B"
  status-error: "#EF4444"
  status-info: "#0284C7"
  neutral-dark: "#0F172A"
  neutral-muted: "#64748B"
  neutral-border: "#E2E8F0"
  neutral-card: "#F1F5F9"
  neutral-surface: "#FFFFFF"
  neutral-bg: "#F8FAFC"
typography:
  display:
    fontFamily: "Roboto, sans-serif"
    fontSize: "32px"
    fontWeight: 800
    lineHeight: 1.15
  headline:
    fontFamily: "Roboto, sans-serif"
    fontSize: "26px"
    fontWeight: 700
    lineHeight: 1.2
  title:
    fontFamily: "Roboto, sans-serif"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1.3
  title-medium:
    fontFamily: "Roboto, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.4
  body:
    fontFamily: "Roboto, sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.5
  body-medium:
    fontFamily: "Roboto, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.45
  label:
    fontFamily: "Roboto, sans-serif"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: 1.35
rounded:
  sm: "8px"
  md: "14px"
  lg: "16px"
  xl: "20px"
  pill: "9999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.neutral-surface}"
    rounded: "{rounded.lg}"
    height: "52px"
  button-secondary:
    backgroundColor: "{colors.neutral-border}"
    textColor: "{colors.neutral-dark}"
    rounded: "{rounded.lg}"
    height: "52px"
  card-primary:
    backgroundColor: "{colors.neutral-surface}"
    rounded: "{rounded.xl}"
    padding: "18px"
  input-field:
    backgroundColor: "{colors.neutral-bg}"
    rounded: "{rounded.lg}"
    padding: "16px 18px"
  chip-filter:
    backgroundColor: "{colors.neutral-surface}"
    textColor: "{colors.neutral-dark}"
    rounded: "{rounded.pill}"
    padding: "8px 16px"
---

# Design System: HomeEase

## Overview

**Creative North Star: "The Pine Valley Haven"**

HomeEase is a dignified, hyper-local domestic service platform serving Abbottabad, Pakistan. Its visual language balances the trustworthy dependability of a community utility with the modern, refined clarity of an AI-assisted marketplace. Rooted in high-altitude pine teal tones (`#0F766E`) and fresh mint accents (`#14B8A6`), the interface creates immediate visual calmness and reliability for both busy households and honest domestic workers.

The system prioritizes accessible tactile hierarchy. Because workers and households across Hazara navigate the app under varying conditions and literacy levels, every interactive element is physically grounded: touch targets strictly adhere to 48dp+ tap areas, cards utilize gentle tactile scale compressions upon press (`0.96` scale factor with light haptic feedback), and text maintains WCAG AAA contrast against clean, cool-paper backgrounds (`#F8FAFC`).

**Key Characteristics:**
- **Calm, High-Trust Atmosphere**: Deep Pine Teal anchor paired with subtle mint glow highlights.
- **Bilingual Symmetry**: Seamless bidirectional layout supporting English LTR and Urdu RTL without layout breakage.
- **Physical Affordance**: Generous touch targets, rounded tactile geometry (16–20dp radii), and physical feedback.
- **Explainable Transparency**: Clear visual badges communicating verification, distance, and match reasons.

## Colors

The HomeEase palette balances institutional trust, energetic mint accents, and high-legibility slate neutrals.

### Primary
- **Pine Teal Anchor** (`#0F766E`): The primary brand signifier. Used for hero buttons, active navigation, key brand banners, and focused borders. Evokes trust, security, and institutional integrity.
- **Deep Forest Shade** (`#115E59`): Pressed button states, gradient terminal stops, and high-emphasis accents.
- **Mint Tint** (`#CCFBF1`): Subtle category highlights, badge fills, and AI match chip backgrounds.

### Secondary
- **Aquamarine Mint** (`#14B8A6`): Energetic accent color for interactive toggles, micro-animations, and positive state highlights.

### Neutral
- **Slate Ink** (`#0F172A`): Primary text color offering maximum contrast (WCAG AAA) for effortless reading on outdoor mobile screens.
- **Slate Muted** (`#64748B`): Secondary labels, timestamps, metadata, and placeholder text.
- **Slate Outline** (`#E2E8F0`): Clean container boundaries, dividers, and inactive borders.
- **Surface Canvas** (`#FFFFFF`): Elevated card and bottom sheet background.
- **Canvas Base** (`#F8FAFC`): Screen background canvas providing soft, glare-free reading comfort.

### Semantic Status
- **Emerald Verified** (`#10B981`): Identity verified badges, accepted bookings, and completed jobs.
- **Amber Pending** (`#F59E0B`): Pending verification alerts and awaiting-acceptance requests.
- **Crimson Alert** (`#EF4444`): Schedule conflicts, errors, and dispute indicators.
- **Sky Info** (`#0284C7`): Informational notices and general system alerts.

### Named Rules
**The Deep Teal Anchor Rule.** The primary pine teal (`#0F766E`) serves as the functional anchor of every screen. It is reserved strictly for primary calls-to-action, active navigation tabs, and verified security markers. It should never cover more than 20% of screen surface area to maintain breathable elegance.

**The Redundant Status Indicator Rule.** Never communicate booking or verification status through color alone. Every status badge must pair its semantic color with a recognizable icon (e.g. checkmark shield for verified, clock for pending, alert triangle for conflict).

## Typography

**Display & Body Font:** Roboto (System Sans-Serif on Android) with Nastaliq-friendly fallbacks for Urdu.

**Character:** Balanced, crisp, modern humanist grotesque with open counters and tall x-height, ensuring effortless scanning across both small phone screens and localized Urdu script.

### Hierarchy
- **Display** (800, 32px, line-height 1.15): Primary screen titles and splash greetings.
- **Headline** (700, 26px, line-height 1.2): Section headers and screen titles within `AppScaffold`.
- **Title** (700, 20px, line-height 1.3): Card headers, sheet headings, and modal titles.
- **Title Medium** (600, 16px, line-height 1.4): Worker names, gig titles, and form section labels.
- **Body** (400, 15px, line-height 1.5): Standard descriptions, bios, and service explanations.
- **Body Medium** (400, 14px, line-height 1.45): Secondary metadata, list item details, and notes.
- **Label / Caption** (500, 12px, line-height 1.35): Status badges, timestamp chips, and helper micro-copy.

### Named Rules
**The Bilingual RTL Invariance Rule.** Every typographic hierarchy element must render identically in visual weight, relative margin, and alignment when toggled between English (LTR) and Urdu (RTL). Never use hardcoded left/right paddings; always use start/end insets.

## Layout

HomeEase utilizes a fluid, single-column mobile layout constrained to a maximum content width of 480dp on wider devices or tablets.

- **Screen Gutter**: 20dp horizontal edge padding (`EdgeInsets.symmetric(horizontal: 20)`).
- **Vertical Section Rhythm**: 16dp to 24dp vertical spacing between logical screen blocks.
- **Safe Area Insets**: Edge-to-edge support with explicit `SafeArea` handling for status bar, display cutouts, and bottom navigation bars.
- **Form Factor Guard**: Tablets and foldables center content inside a 480dp max-width column to prevent uncomfortably stretched form fields.

## Elevation & Depth

HomeEase follows a modern layered-plane philosophy rather than heavy, artificial drop shadows. Surfaces feel clean, light, and tactile.

### Shadow Vocabulary
- **Card Rest Shadow** (`0px 4px 16px rgba(15, 23, 42, 0.04), 0px 1px 4px rgba(15, 23, 42, 0.02)`): Subtle ambient depth separating white cards from the `#F8FAFC` canvas.
- **Elevated Sheet Shadow** (`0px 8px 24px rgba(15, 23, 42, 0.08)`): Bottom sheets, modals, and floating action elements.
- **Teal Trust Glow** (`0px 6px 16px rgba(15, 118, 110, 0.28)`): Soft radiant glow under primary submission buttons and post-job banners.
- **Mint Accent Glow** (`0px 3px 14px rgba(20, 184, 166, 0.35)`): Micro-interaction highlight glow for active tags and AI badges.

### Named Rules
**The Tonal Border Rule.** Elevated cards resting on the canvas must pair their subtle ambient shadow with a 1px border of `#E2E8F0` (`cardDark`). This ensures clean edge definition on budget mobile screens with variable contrast ratios.

## Shapes

- **Base Radius**: 16dp (`BorderRadius.circular(16)`) on buttons, text fields, and worker avatars.
- **Card Radius**: 20dp (`BorderRadius.circular(20)`) on cards, job banners, and dialog containers.
- **Pill Radius**: Fully rounded (`BorderRadius.circular(9999)`) on service category chips and filter tags.
- **Modal Radius**: Top-edge only 24dp (`BorderRadius.vertical(top: Radius.circular(24))`) on bottom sheets.

## Components

### Buttons
- **Primary CTA (`HomeEaseButton` / `AnimatedPrimaryButton`)**: 52dp height, Pine Teal (`#0F766E`), white text, 16dp radius, `0.96` scale tap feedback with light haptic response.
- **Secondary Action**: 52dp height, Slate border/card fill, Slate 900 text.
- **Text Action (`HomeEaseTextAction`)**: Text button with teal foreground and generous touch padding.

### Cards (`HomeEaseCard`)
- 20dp rounded corners, pure white (`#FFFFFF`) background, 1px `#E2E8F0` border, 18dp internal padding, and ambient rest shadow.

### Input Fields
- 52dp height, `#F8FAFC` filled background, 16dp radius, 1px `#E2E8F0` border, transitioning to 1.8px `#0F766E` focus border.

### Service & Filter Chips
- Pill-shaped (`BorderRadius.circular(9999)`), white background when unselected with 1px border; Pine Teal background with white text when selected.

### AI Explainability Card (`_AIWorkerCard`)
- 164dp height horizontal scrolling card featuring worker avatar, match percentage tag (`X% match`), category badge, and concise rationale ("Top Rated • 1.2 km away").

### Status Badge
- Horizontal chip with 8dp radius, semantic background tint (e.g. `#ECFDF5`), bold semantic text, and accompanying status icon.

## Do's and Don'ts

### Do:
- **Do** maintain a strict 48x48 dp minimum touch target on every button, chip, icon button, and card.
- **Do** support both English LTR and Urdu RTL seamlessly across all screens.
- **Do** provide tactile press feedback (`AnimatedScaleTap` with `HapticFeedback.lightImpact()`) on primary actions.
- **Do** explain AI recommendation criteria clearly using human-readable badge chips.
- **Do** preserve zero-conflict scheduling and alert users with clear date/time overlap warnings.

### Don't:
- **Don't** use raw, harsh primary colors (generic blue, flat red, plain green); stick to curated Pine Teal, Emerald, Amber, and Slate.
- **Don't** rely on color alone to indicate status; always provide an icon and textual description.
- **Don't** hardcode left/right margins that invert incorrectly in Urdu RTL mode.
- **Don't** create crowded multi-column grid layouts on mobile phones; keep discovery clean and vertical.
- **Don't** introduce fake or unverified mock data back into the app runtime.
