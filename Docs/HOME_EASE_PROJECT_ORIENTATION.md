# HomeEase Project Orientation

## Purpose of This Document

This document summarizes the 10% HomeEase proposal and presentation material in an organized way so the project can be developed step by step. It should be used as the starting reference for the 30% SRS, 30% SDD, mockups, 60% implementation, and final thesis.

## Final Year Project Stages

### 10% Stage - Proposal and Scope

The 10% stage defines the project idea, problem, proposed solution, scope, modules, tools, feasibility, schedule, and first iteration plan.

Current 10% files reviewed:

- `Docs/HomeEase Proposal 10%.docx`
- `Docs/HomeEase Proposal 10%.pdf`
- `Docs/HomeEase Proposal v1.5 10%.pdf`
- `Docs/HomeEase 10 ppt.pptx`

### 30% Stage - Analysis and Design

The 30% stage should produce:

- SRS document (Completed)
- SDD document (Completed)
- UML diagrams & Database design (Completed)
- Finalized feature list & Refined user flows (Completed)
- Flutter mobile app setup & core screens implementation (Active 30% Focus)
- Complete client-side screen-by-screen UI plan & mockups (Active 30% Focus)
- Note: The React/Vite Admin Web Dashboard is postponed to the 60% stage.

### 60% Stage - Main Implementation

The 60% stage should focus on building the working system:

- Mobile app implementation
- Backend/database setup
- Authentication
- User roles
- Worker profiles
- Search and filtering
- Booking flow
- Reviews and ratings
- Notifications
- Admin-side verification flow if included
- Testing document or progress report, depending on university requirements

### 100% Stage - Final Thesis and Complete Project

The 100% stage should include:

- Fully working app
- Complete thesis
- Final testing results
- Final diagrams
- User manual or deployment guide if required
- Final presentation/demo
- Future work and limitations

## General Project Idea

HomeEase is a mobile-based application for connecting households with trusted domestic and home-care workers in Pakistan. The target workers include maids, cooks, cleaners, nannies, caregivers, and similar home-service providers.

The main issue addressed by HomeEase is that domestic worker hiring in Pakistan is mostly informal. People usually hire through personal references, neighbors, relatives, or word of mouth. This creates problems related to trust, safety, availability, service quality, pricing clarity, and communication.

HomeEase proposes a centralized mobile platform where households can search for nearby workers, view their profiles, check skills and availability, book services, and give ratings after completion. Workers can create digital profiles, list their skills and expected charges, receive job requests, manage availability, and build a reputation over time.

In one line:

HomeEase is a hyper-local mobile platform that connects households with verified domestic workers using profiles, location-based search, booking, reviews, and notifications.

## Project Motivation

The 10% documents identify these motivations:

- Domestic worker hiring in Pakistan is mostly informal.
- Hiring depends heavily on references and word of mouth.
- Households face trust and safety concerns.
- Workers struggle to find stable and regular job opportunities.
- There is no dedicated centralized mobile platform for local home-care services.
- Current hiring methods are time-consuming and inefficient.
- Worker experience, availability, ratings, and pricing are usually unclear.
- Smartphones are widely used, making a mobile solution practical.

## Problem Statement

The problem is the lack of a structured digital system for hiring domestic/home-care workers.

Main problems:

- No centralized platform for households and workers.
- Lack of verified worker profiles.
- Difficulty in finding nearby available workers.
- Trust and safety concerns for households.
- Limited job visibility for workers.
- Inefficient communication between households and workers.
- No proper review or reputation system.
- Manual scheduling causes delays and confusion.
- Pricing and service details are often unclear.

## Proposed Solution

HomeEase solves the problem by providing a structured mobile application where households and workers can interact in an organized environment, plus a lightweight web dashboard where admins can verify workers and monitor basic platform activity.

Solution elements:

- User registration and secure login.
- Role-based access for households and workers.
- Worker profile creation.
- Basic worker verification.
- Service categories such as maid, cook, cleaner, nanny, and caregiver.
- Location-based search and matching.
- Availability management.
- Booking and scheduling.
- Rating and review system.
- Notifications for booking and status updates.
- Basic communication between users.
- Admin web dashboard for verification and basic monitoring.

## Target Users

### Household Users

Household users are people looking to hire domestic workers for home-care services.

They should be able to:

- Register and log in.
- Create and manage their profile.
- Search for nearby workers.
- Filter workers by service type, location, availability, rating, and experience.
- View worker profiles.
- Send booking requests.
- Track booking history.
- Rate and review workers after service completion.
- Receive notifications.

### Worker Users

Worker users are domestic/home-care workers offering services.

They should be able to:

- Register and log in.
- Create a worker profile.
- Add skills, experience, services, pricing, availability, and contact details.
- Receive booking requests.
- Accept or reject bookings.
- Manage availability.
- Receive ratings and reviews.
- Receive notifications.

### Admin Users

Admin users manage platform quality and verification.

They should be able to:

- Log in through a web dashboard.
- View users.
- Verify worker profiles.
- Approve or reject verification requests.
- Monitor bookings.
- Handle reported issues.
- Maintain platform reliability.

## Main Features Listed in the 10% Material

- Authentication and role management.
- Household user management.
- Worker profile management.
- Worker verification.
- Service category management.
- Worker pricing/expected charges.
- Location-based search.
- Worker matching.
- Filtering by skills, location, availability, ratings, and experience.
- Booking requests.
- Worker accept/reject booking actions.
- Availability management.
- One-time service booking.
- Recurring service booking.
- Rating and review system.
- Notification system.
- Lightweight admin web dashboard.
- Basic in-app communication.
- Admin management.
- User profile management.
- Booking history.
- Worker visibility management.
- Profile completeness checking.
- Verified worker badge/status.
- Scheduling conflict management.

## Modules from the Latest Proposal Version

The newer `HomeEase Proposal v1.5 10%.pdf` gives the clearest module breakdown.

### Module 1: Authentication and Role Management

Handles user registration, login, logout, secure session management, password security, account status, and role-based access.

Roles:

- Household
- Worker
- Admin

### Module 2: Household User Management

Allows households to manage:

- Profile information
- Contact details
- Address
- Service preferences
- Booking history
- Previous service requests

### Module 3: Worker Profile Management

Allows workers to create and manage professional profiles containing:

- Personal details
- Skills
- Experience
- Service categories
- Expected charges
- Availability
- Contact information
- Profile visibility

### Module 4: Worker Verification

Manages basic verification:

- Identity confirmation
- Profile completeness checking
- Approval status
- Verified worker marking

### Module 5: Service Category and Pricing

Manages home-care service types and worker rates.

Service categories listed:

- Maid
- Cook
- Cleaner
- Nanny
- Caregiver
- Other domestic services

### Module 6: Search and Matching

Allows households to find suitable workers using:

- Location
- Skills
- Service type
- Availability
- Rating
- Experience
- Distance/proximity
- Profile quality

### Module 7: Booking and Availability Management

Allows households to send booking requests and workers to manage responses.

Includes:

- Date selection
- Time selection
- Recurring services
- Accept/reject flow
- Booking status
- Scheduling conflict prevention
- Booking updates

### Module 8: Rating and Review

Allows households to review workers after service completion.

Review factors:

- Performance
- Punctuality
- Behavior
- Service quality

### Module 9: Notification and Communication

Handles alerts for:

- Job requests
- Booking updates
- Profile approvals
- Status changes
- Missed opportunities
- Basic service coordination messages

### Module 10: Admin Management

Allows admins to:

- Manage users
- Verify worker profiles
- Monitor bookings
- Handle reported issues
- Approve/reject worker verification
- Maintain platform quality

## Scope

The project includes:

- Mobile application for households and domestic workers.
- Registration for households and workers.
- Profile creation.
- Worker profile management.
- Worker skills, experience, and availability.
- Location-based search and filtering.
- Job request system.
- Worker accept/reject system.
- Booking and scheduling.
- One-time and recurring services.
- Rating and review system.
- Notifications.
- Simple and user-friendly interface.
- Admin verification and management if kept in final scope.

## Out of Scope

The project does not include:

- Government-level background verification.
- Police database integration.
- Official database integration.
- Full payroll management.
- Advanced financial accounting.
- Online payment gateway.
- Digital wallet.
- Household or worker web portal in the initial release.
- Advanced analytics dashboard.
- Direct employment contracts.
- Full employment agency functionality.
- Transportation/logistics services for workers.
- Video calling.
- Advanced real-time communication.
- AI-based recommendations.
- Automated worker selection.
- AI-based behavior prediction.
- Worker performance analytics.

## Literature Review / Related Systems

The 10% proposal compares HomeEase with:

### UrbanClap / Urban Company

Weakness:

- Not localized for Pakistan.
- Limited support for Pakistan's informal labor market.

HomeEase solution:

- Localized platform for Pakistan's domestic home-care labor needs.

### Care.com

Weakness:

- Subscription-based.
- Costly.
- Less accessible in developing regions.

HomeEase solution:

- Free or accessible platform for both households and workers.

### Handy

Weakness:

- Weak real-time matching.
- Not designed for informal local hiring systems.

HomeEase solution:

- Hyper-local matching based on location and availability.

## Advantages and Benefits

The proposed system benefits include:

- Replaces informal hiring with a structured digital process.
- Improves trust through verified worker profiles.
- Improves safety by allowing households to review worker details before hiring.
- Encourages accountability through ratings and reviews.
- Helps households find nearby available workers quickly.
- Gives workers better job visibility.
- Helps workers build a professional reputation.
- Improves scheduling and time management.
- Improves responsiveness through notifications.
- Makes home-care hiring more accessible through smartphones.
- Promotes transparency in pricing, availability, and service quality.

## System Limitations and Constraints

The 10% material lists these constraints:

- Requires internet connectivity.
- Poor internet may affect search, booking, and notifications.
- Matching accuracy depends on user-provided data.
- Incomplete worker profiles may reduce recommendation quality.
- No advanced government-level background verification.
- Trust is improved but not fully guaranteed.

## Software Process Methodology

The project uses Agile Software Development Methodology.

Reasons:

- Supports iterative development.
- Allows continuous testing.
- Supports frequent feedback.
- Suitable for evolving requirements.
- Allows modules to be built step by step.
- Helps manage authentication, matching, booking, reviews, and notifications separately.

## Tools and Technologies Mentioned

Tools mentioned across the proposal and presentation:

- Flutter
- Dart
- Android Studio
- Visual Studio Code
- Supabase
- PostgreSQL
- Firebase Console
- Node.js
- RESTful APIs
- Figma
- Draw.io
- StarUML
- MS Word
- MS PowerPoint
- MS Project
- GitHub

Important cleanup note:

The documents are not fully consistent. Some places mention Firebase, some mention Supabase, some mention Node.js APIs, and the PPT mentions React.js/Web. The revised direction keeps React/Web only for the admin dashboard, not for household or worker users. Before 30% documentation, the final technology stack should be fixed clearly.

Recommended final stack for consistency:

- Frontend: Flutter mobile app (Active 30% focus)
- Admin dashboard: React/Vite web app (Postponed to 60% stage)
- Backend/database/auth: Supabase
- Database: PostgreSQL through Supabase
- Design: Figma
- Diagrams: Draw.io or StarUML
- Version control: GitHub

Node.js should only be included if a custom backend API is actually planned.

## Concepts Listed in Proposal

### Location-Based Services

Used to find nearby workers through user location and distance calculations.

### Authentication and Authorization

Used for registration, login, password protection, session management, and role-based feature access.

### RESTful APIs

Used for communication between frontend and backend services if a custom backend is used.

### Notifications

Used to inform users about booking requests, updates, and scheduling changes.

### Database Management

Used to store users, worker profiles, bookings, ratings, services, and notifications.

## Stakeholders

Stakeholders listed in the 10% documents:

- Households
- Home-care workers
- Development team
- Project supervisor
- COMSATS University Islamabad, Abbottabad Campus
- Final Year Project Committee

## Team Members and Work Division

### Hashir Hamid

Registration:

- `CIIT/FA22-BSE-139/ATD`

Responsibilities:

- Authentication and user management
- Worker profile and verification
- Frontend development
- User authentication
- Profile management
- Database integration

### Aman Ullah Khan

Registration:

- `CIIT/FA22-BSE-074/ATD`

Responsibilities:

- Hyper-local search and matching
- Booking and scheduling
- Location-based services
- Search functionality
- Booking system
- Backend API development

### Umar Saeed

Registration:

- `CIIT/FA22-BCS-041/ATD`

Responsibilities:

- Rating and review
- Notification and communication
- Feedback system
- Notification management
- Testing
- System integration

## First Iteration Tasks Mentioned for 30%

The PPT lists these tasks for the first iteration:

- Flutter project setup.
- Splash screen.
- Onboarding screens.
- Login UI.
- Signup UI.
- Role selection screen.
- Basic home screen UI.
- Worker profile UI.
- Navigation setup.
- Supabase setup.
- Database structure creation.

## Feasibility Points

### Technical Feasibility

- Flutter/Dart can build cross-platform mobile apps.
- PostgreSQL is reliable for structured data.
- Supabase can support authentication, database, and backend services.
- UML/design tools are available for diagrams.

### Financial Feasibility

- Flutter and Dart are free.
- Supabase free tier is enough for early academic development.
- No expensive server setup is needed initially.
- Development is handled by students.
- Testing can be done using personal phones and emulators.

### Resource Feasibility

- Three developers and supervisor are available.
- Required software tools are free or accessible.
- Laptops and smartphones are enough for development/testing.
- University resources are sufficient.

### Operational Feasibility

- App targets real household and worker needs.
- Mobile interface makes adoption easier.
- Verification improves reliability.
- Platform promotes digital employment and organized home-care services.
- Modular architecture supports long-term growth.

## Important Inconsistencies to Fix Before 30%

These issues should be corrected in the SRS, SDD, and future presentation:

- PPT mentions `React.js (Web)`; keep web scope limited to the admin dashboard only.
- PPT mentions `hotels` and `trips` in database explanation, which does not belong to HomeEase.
- PPT says verification ensures safety for `trip companions`, which belongs to another project.
- Tools section repeats Android Studio in older proposal.
- Firebase and Supabase are both mentioned; choose one final approach.
- `Hyper local`, `hyper-local`, and `local` should be standardized.
- Some module names differ between older and newer proposal versions.
- Admin management is in the PPT/v1.5 proposal but not strongly described in the older 6-module proposal.

## Recommended Final Direction

For orderly development, HomeEase should be treated as a mobile-first Flutter application backed by Supabase, with a lightweight React/Vite admin web dashboard using the same Supabase project.

The final project should focus on three primary user journeys:

### Journey 1: Household Hiring Flow

1. Household signs up.
2. Household selects service category.
3. Household searches nearby workers.
4. Household views worker profile.
5. Household sends booking request.
6. Worker accepts or rejects.
7. Household receives notification.
8. Service is completed.
9. Household submits rating/review.

### Journey 2: Worker Job Flow

1. Worker signs up.
2. Worker creates profile.
3. Worker adds skills, service categories, pricing, and availability.
4. Worker submits verification details.
5. Worker receives booking request.
6. Worker accepts or rejects request.
7. Worker completes service.
8. Worker builds ratings and profile reputation.

### Journey 3: Admin Web Dashboard Flow

1. Admin logs in through the web dashboard.
2. Admin views pending worker profiles.
3. Admin approves or rejects verification.
4. Verified workers become visible or prioritized.
5. Admin views simple user and booking overview tables.

## Recommended 30% Work Plan

### Step 1: Freeze Scope (Decisions Finalized)

- **Mobile app plus admin web dashboard?** Yes, both. However, the Admin Web Dashboard implementation is postponed to the 60% stage; the 30% stage will focus purely on the client-side Mobile App.
- **Supabase only or Supabase plus Node.js?** Supabase only (serverless integration via client libraries).
- **Admin dashboard scope:** Verification requests, users overview, booking monitoring, and dispute reports (to be built in 60%).
- **Will payment be excluded completely?** No, manual payment uploads (receipt photos) with worker confirmations and admin dispute resolution will be implemented.
- **Will chat be simple messaging or only booking notes/contact coordination?** Simple coordination via booking notes and exchanging phone numbers upon booking acceptance.

### Step 1.5: Focus on Mobile App UI (Active 30% Milestone)

The 30% milestone focuses on implementing the Flutter Mobile App client-side flow and core user screens:
- Setup stable navigation and themes.
- Implement UI views for Splash, SignIn, SignUp, Home/Search, Worker List, Worker Details, Booking Request Form, and basic Worker Dashboard.

### Step 2: Create SRS

The SRS should include:

- Introduction
- Purpose
- Scope
- Definitions
- Overall description
- User classes
- Functional requirements
- Non-functional requirements
- Use cases
- Data requirements
- External interface requirements
- Constraints
- Assumptions
- Acceptance criteria

### Step 3: Create SDD

The SDD should include:

- System architecture
- App architecture
- Database design
- Module design
- API/service design
- Authentication design
- Role permission design
- Screen navigation design
- Error handling
- Security considerations
- Diagrams

### Step 4: Create Mockups

Mockups should cover:

- Splash screen
- Onboarding
- Role selection
- Household signup/login
- Worker signup/login
- Household home
- Worker home
- Worker profile creation
- Worker listing/search
- Worker detail screen
- Booking request screen
- Worker booking requests
- Booking status screen
- Rating/review screen
- Notifications screen
- Admin verification screen
- Admin web dashboard overview
- Admin web user management
- Admin web booking overview

### Step 5: Prepare 30% Presentation

The 30% presentation should show:

- Refined problem and solution
- Final scope
- User roles
- Main workflows
- SRS highlights
- SDD highlights
- Diagrams
- Mockups
- Technology stack
- Work completed
- Next work for 60%

## Recommended 60% Work Plan

Build the implementation in this order:

1. Flutter project setup.
2. Supabase project setup.
3. Database schema.
4. Authentication.
5. Role-based navigation.
6. Household profile.
7. Worker profile.
8. Worker verification status.
9. Service categories and pricing.
10. Search/filter screens.
11. Booking request flow.
12. Worker accept/reject flow.
13. Booking status management.
14. Ratings and reviews.
15. Notifications.
16. Admin web dashboard.
17. Admin verification.
18. Testing and bug fixes.

## Recommended 100% Work Plan

For the final thesis and demo:

- Finalize all implemented modules.
- Complete testing.
- Add screenshots of final app.
- Add final database schema.
- Add final diagrams.
- Write thesis chapters.
- Prepare final demo flow.
- Prepare final presentation.
- Document limitations and future work.

## Current Clean Project Definition

HomeEase is a Flutter-based mobile application that connects households with domestic workers in Pakistan, supported by a lightweight React/Vite admin web dashboard. It provides role-based access for households, workers, and admins. Households can search for nearby workers, view verified profiles, send booking requests, and submit ratings. Workers can create service profiles, manage availability, accept or reject bookings, and build reputation. Admins can verify workers and maintain platform trust through the web dashboard. The project focuses on improving trust, transparency, accessibility, and organization in the informal home-care labor sector.
