# Design Diagrams Summary

This document provides a detailed summary and breakdown of the **9 Design Diagrams** defined in the HomeEase project (`HomeEase_Diagram.drawio`). It includes the purpose, key elements, relationships, and embedded rendering code (using Mermaid syntax) for each diagram.

---

## 1. Use Case Diagram
* **Purpose:** Defines the boundary of the HomeEase system, the actors involved, and the specific operations (use cases) they can perform, along with the backend services they trigger.
* **Actors:** Household User, Worker User, Admin User.
* **Services:** Authentication Service, Database Service, Notification Service.
* **Key Relations:**
  - Household and Worker actors interact with Authentication (`UC1`, `UC2`).
  - Household initiates search (`UC5`) and bookings (`UC6`).
  - Worker accepts/rejects bookings (`UC7`).
  - Admin handles verifications (`UC4`) and disputes (`UC10`).

```mermaid
flowchart LR
    Household["Household User"]
    Worker["Worker User"]
    Admin["Admin User"]
    Auth["Authentication Service"]
    DB["Database Service"]
    Notify["Notification Service"]

    Household --> UC1["Register / Sign Up"]
    Household --> UC2["Log In"]
    Household --> UC5["Search Workers"]
    Household --> UC17["View AI Recommendations"]
    Household --> UC14["Post Job / Gig Request"]
    Household --> UC6["Send Booking Request"]
    Household --> UC11["View Service Agreement"]
    Household --> UC8["Submit Payment Receipt"]
    Household --> UC9["Submit Rating and Review"]
    Household --> UC10["Raise Dispute"]
    Household --> UC18["Toggle Bilingual Mode"]

    Worker --> UC1
    Worker --> UC2
    Worker --> UC3["Create Worker Profile"]
    Worker --> UC15["Browse Available Jobs"]
    Worker --> UC16["Apply for Job"]
    Worker --> UC7["Accept or Reject Booking"]
    Worker --> UC11
    Worker --> UC12["Confirm Payment Received"]
    Worker --> UC10
    Worker --> UC18["Toggle Bilingual & Visual Icons"]

    Admin --> UC2
    Admin --> UC4["Verify Worker Profile"]
    Admin --> UC10
    Admin --> UC13["Admin Booking/User Overview"]

    UC1 --> Auth
    UC2 --> Auth
    UC3 --> DB
    UC5 --> DB
    UC17 --> DB
    UC14 --> DB
    UC14 --> Notify
    UC15 --> DB
    UC16 --> DB
    UC16 --> Notify
    UC7 --> DB
    UC8 --> DB
    UC8 --> Notify
    UC10 --> DB
    UC10 --> Notify
    UC11 --> DB
    UC12 --> DB
    UC12 --> Notify
    UC13 --> DB
```

---

## 2. Entity Relationship Diagram (ERD)
* **Purpose:** Details the logical database structure, key constraints (PK/FK), and structural relationships between tables in the Supabase PostgreSQL database.
* **Key Entities & Relations:**
  - `USERS` has a 1-to-0..1 relationship with `HOUSEHOLD_PROFILES` and `WORKER_PROFILES`.
  - `WORKER_PROFILES` has many-to-many relationship with `SERVICE_CATEGORIES` through `WORKER_SERVICES`.
  - `BOOKINGS` acts as the central intersection table linking `HOUSEHOLD_PROFILES`, `WORKER_PROFILES`, and `SERVICE_CATEGORIES`.
  - A `BOOKING` generates exactly one `SERVICE_AGREEMENT`, and can have multiple `PAYMENT_RECORDS`, `REVIEWS`, and `DISPUTES`.

```mermaid
erDiagram
    USERS {
        uuid id PK
        text full_name
        text email
        text phone
        text role
        text account_status
        timestamp created_at
    }
    HOUSEHOLD_PROFILES {
        uuid id PK
        uuid user_id FK
        text address
        text city
        text area
        text service_preferences
    }
    WORKER_PROFILES {
        uuid id PK
        uuid user_id FK
        text bio
        int experience_years
        text city
        text area
        text availability_status
        text verification_status
        decimal average_rating
        boolean profile_visibility
    }
    SERVICE_CATEGORIES {
        uuid id PK
        text name
        text description
    }
    WORKER_SERVICES {
        uuid id PK
        uuid worker_id FK
        uuid service_category_id FK
        decimal rate
        text rate_unit
    }
    AVAILABILITY_SLOTS {
        uuid id PK
        uuid worker_id FK
        text day_of_week
        time start_time
        time end_time
        boolean is_available
    }
    BOOKINGS {
        uuid id PK
        uuid household_id FK
        uuid worker_id FK
        uuid service_category_id FK
        date booking_date
        time start_time
        time end_time
        text address
        text notes
        decimal agreed_amount
        text status
        timestamp created_at
    }
    SERVICE_AGREEMENTS {
        uuid id PK
        uuid booking_id FK
        uuid household_id FK
        uuid worker_id FK
        uuid service_category_id FK
        text agreement_text
        decimal agreed_amount
        text terms
        text status
        timestamp generated_at
    }
    PAYMENT_RECORDS {
        uuid id PK
        uuid booking_id FK
        uuid household_id FK
        uuid worker_id FK
        decimal amount
        text payment_method
        text receiver_account_title
        text receiver_account_number
        text receipt_url
        text transaction_note
        text status
        timestamp submitted_at
        timestamp confirmed_at
    }
    REVIEWS {
        uuid id PK
        uuid booking_id FK
        uuid household_id FK
        uuid worker_id FK
        int rating
        text comment
        timestamp created_at
    }
    NOTIFICATIONS {
        uuid id PK
        uuid user_id FK
        text title
        text message
        text type
        boolean is_read
        timestamp created_at
    }
    VERIFICATION_REQUESTS {
        uuid id PK
        uuid worker_id FK
        text submitted_details
        text status
        uuid admin_id FK
        text rejection_reason
        timestamp submitted_at
        timestamp reviewed_at
    }
    DISPUTES {
        uuid id PK
        uuid booking_id FK
        uuid payment_record_id FK
        uuid raised_by FK
        uuid against_user_id FK
        text category
        text description
        text evidence_url
        text status
        uuid admin_id FK
        text admin_remarks
        timestamp created_at
        timestamp resolved_at
    }
    ISSUE_REPORTS {
        uuid id PK
        uuid reporter_id FK
        uuid related_booking_id FK
        text message
        text status
        timestamp created_at
    }
    JOB_POSTS {
        uuid id PK
        uuid household_id FK
        uuid service_category_id FK
        text title
        text description
        text city
        text area
        decimal latitude
        decimal longitude
        decimal budget
        date required_date
        text status
        timestamp created_at
    }
    JOB_APPLICATIONS {
        uuid id PK
        uuid job_post_id FK
        uuid worker_id FK
        decimal proposed_rate
        text notes
        text status
        timestamp applied_at
    }

    USERS ||--o| HOUSEHOLD_PROFILES : has
    USERS ||--o| WORKER_PROFILES : has
    WORKER_PROFILES ||--o{ WORKER_SERVICES : offers
    SERVICE_CATEGORIES ||--o{ WORKER_SERVICES : belongs_to
    WORKER_PROFILES ||--o{ AVAILABILITY_SLOTS : has
    HOUSEHOLD_PROFILES ||--o{ BOOKINGS : creates
    WORKER_PROFILES ||--o{ BOOKINGS : receives
    SERVICE_CATEGORIES ||--o{ BOOKINGS : requested_for
    BOOKINGS ||--|| SERVICE_AGREEMENTS : generates
    BOOKINGS ||--o{ PAYMENT_RECORDS : has
    BOOKINGS ||--o| REVIEWS : receives
    BOOKINGS ||--o{ DISPUTES : has
    HOUSEHOLD_PROFILES ||--o{ JOB_POSTS : publishes
    SERVICE_CATEGORIES ||--o{ JOB_POSTS : categorized_under
    JOB_POSTS ||--o{ JOB_APPLICATIONS : receives
    WORKER_PROFILES ||--o{ JOB_APPLICATIONS : submits
    BOOKINGS ||--o{ ISSUE_REPORTS : related_to
    HOUSEHOLD_PROFILES ||--o{ PAYMENT_RECORDS : pays
    WORKER_PROFILES ||--o{ PAYMENT_RECORDS : receives
    HOUSEHOLD_PROFILES ||--o{ REVIEWS : writes
    WORKER_PROFILES ||--o{ REVIEWS : receives
    USERS ||--o{ NOTIFICATIONS : receives
    WORKER_PROFILES ||--o{ VERIFICATION_REQUESTS : submits
    PAYMENT_RECORDS ||--o{ DISPUTES : may_create
    USERS ||--o{ ISSUE_REPORTS : reports
    USERS ||--o{ DISPUTES : raises
    USERS ||--o{ DISPUTES : against
```

---

## 3. System Architecture Diagram
* **Purpose:** Represents the layered architecture of the application, delineating separation of concerns from user interaction down to persistent storage.
* **Layers & Relations:**
  - **Presentation Layer:** Flutter app and React Web app.
  - **Application/State Layer:** Binds interactive components to state objects (Selected Role, Booking UI State).
  - **Service Layer:** Houses modular services that coordinate tasks (e.g., Booking Service calling Notification Service).
  - **Data Layer:** PostgreSQL database and Storage Buckets accessed via Supabase Client Libraries.
  - **External Services:** Supabase Auth, Mobile Push Alerts, and manual Payment Providers (EasyPaisa/JazzCash).

```mermaid
flowchart TB
    subgraph Users
        HU[Household User]
        WU[Worker User]
        AU[Admin User]
    end

    subgraph Presentation["Presentation Layer"]
        F[Flutter Mobile App<br/>Screens & Widgets]
        R[React / Vite Admin Dashboard<br/>Pages & Components]
    end

    subgraph Application["Application / State Layer"]
        SF[Screen Flow]
        FV[Form Validation]
        SR[Selected Role]
        SW[Selected Worker]
        SS[Service Filters]
        BS[Booking UI State]
        AG[Agreement Display State]
        PR[Payment Receipt State]
        DS[Dispute Status State]
    end

    subgraph Services["Service Layer"]
        AUTH[Authentication Service]
        PROF[Profile Service]
        SEARCH[Search Service]
        BOOK[Booking Service]
        AGREEMENT[Agreement Service]
        PAYMENT[Payment Tracking Service]
        DISPUTE[Dispute Service]
        REVIEW[Review Service]
        NOTIFY[Notification Service]
        ADMIN[Admin Service]
    end

    subgraph Data["Data Layer"]
        CLIENT[Supabase Client Libraries]
        DB[(Supabase PostgreSQL)]
        STORAGE[(Storage Buckets)]
    end

    subgraph External["External Services"]
        AUTHAPI[Supabase Authentication]
        PUSH[Push Notification Service]
        EASY[EasyPaisa / JazzCash]
    end

    HU --> F
    WU --> F
    AU --> R

    F --> SF
    F --> FV
    F --> SR
    F --> SW
    F --> SS
    F --> BS
    F --> AG
    F --> PR
    F --> DS

    R --> SF
    R --> FV

    SF --> AUTH
    FV --> AUTH
    SR --> AUTH
    SW --> SEARCH
    SS --> SEARCH
    BS --> BOOK
    AG --> AGREEMENT
    PR --> PAYMENT
    DS --> DISPUTE

    BOOK --> AGREEMENT
    BOOK --> PAYMENT
    BOOK --> DISPUTE
    BOOK --> REVIEW
    BOOK --> NOTIFY
    ADMIN --> DISPUTE
    ADMIN --> PAYMENT
    ADMIN --> AGREEMENT

    AUTH --> CLIENT
    PROF --> CLIENT
    SEARCH --> CLIENT
    BOOK --> CLIENT
    AGREEMENT --> CLIENT
    PAYMENT --> CLIENT
    DISPUTE --> CLIENT
    REVIEW --> CLIENT
    NOTIFY --> CLIENT
    ADMIN --> CLIENT

    CLIENT --> DB
    CLIENT --> STORAGE

    AUTH --> AUTHAPI
    PAYMENT -.-> EASY
    NOTIFY -.-> PUSH

    AUTHAPI --> DB
    DB --> STORAGE
```

---

## 4. Household Booking Process Flow (ProcessFlow1)
* **Purpose:** Details the sequential steps a household user goes through to book a worker and obtain a response.
* **Relations:**
  - Login $\rightarrow$ Search $\rightarrow$ Select Worker $\rightarrow$ Send Request.
  - Generates a "Pending" record in the Database, triggering an alert to the Worker.

```mermaid
flowchart TD
    A([Start]) --> B[Household Login]
    B --> C[Search Services]
    C --> D[Filter by Category / City]
    D --> E[Select Worker]
    E --> F[View Worker Details]
    F --> G[Create Booking Request]
    G --> H[Booking Stored as Pending]
    H --> I[Worker Receives Notification]
    I --> J[Wait for Worker Response]
    J --> K{Worker Response?}
    K -->|Accept| L[Booking Accepted]
    K -->|Reject| M[Booking Rejected]
    L --> N[Update Booking Status]
    M --> N
    N --> O[Notify Household]
    O --> P([End])
```

---

## 5. Worker Dashboard Process Flow (ProcessFlow2)
* **Purpose:** Shows how a worker views and manages incoming job requests from their dashboard.

```mermaid
flowchart TD
    A([Start]) --> B[Worker Login]
    B --> C[Open Dashboard]
    C --> D[View Pending Booking Requests]
    D --> E[Select Booking]
    E --> F{Accept Booking?}
    F -->|Accept| G[Update Status = Accepted]
    F -->|Reject| H[Update Status = Rejected]
    G --> I[Notify Household]
    H --> I
    I --> J([End])
```

---

## 6. Master System Process Flow (ProcessFlow3)
* **Purpose:** Provides a comprehensive flowchart showing the entire end-to-end user journeys (Household, Worker, Admin), including agreement generation, manual payment processing, dispute loops, and worker verification.

```mermaid
flowchart TD
    A([Start]) --> B[User Login]
    B --> C{User Role?}

    C -->|Household| D[Search Services]
    D --> E[Filter by Category / City]
    E --> F[Select Worker]
    F --> G[View Worker Profile]
    G --> H[Create Booking Request]
    H --> I[Booking Status = Pending]

    C -->|Worker| J[Worker Dashboard]
    J --> K[View Pending Booking Requests]
    I --> K
    K --> L{Accept Booking?}

    L -->|No| M[Reject Booking]
    M --> N[Notify Household]
    N --> Z([End])

    L -->|Yes| O[Accept Booking]
    O --> P[Generate Service Agreement]
    P --> Q[Store Agreement]
    Q --> R[Household & Worker View Agreement]

    R --> S[Household Pays via EasyPaisa / JazzCash]
    S --> T[Upload Payment Receipt]
    T --> U[Worker Reviews Receipt]
    U --> V{Payment Valid?}

    V -->|Yes| W[Confirm Payment]
    W --> X[Update Payment Status]

    V -->|No| Y[Create Payment Dispute]

    Y --> AA[Admin Reviews Evidence]
    AA --> AB{Decision}
    AB -->|Resolved| AC[Mark Resolved]
    AB -->|Rejected| AD[Mark Rejected]
    AC --> AE[Notify Household & Worker]
    AD --> AE

    X --> AF[Complete Service]
    AF --> AG[Submit Rating & Review]
    AG --> AH[Update Worker Rating]

    C -->|Worker Verification| AI[Submit Verification Request]
    AI --> AJ[Admin Reviews Profile]
    AJ --> AK{Approved?}
    AK -->|Yes| AL[Verification Status = Verified]
    AK -->|No| AM[Verification Status = Rejected]
    AL --> AN[Notify Worker]
    AM --> AN

    AH --> Z
    AE --> Z
    AN --> Z
```

---

## 7. Class Diagram
* **Purpose:** Details the object-oriented structure of the backend models and services, outlining attributes and structural relationships.

```mermaid
classDiagram
    class AppUser{
        +UUID id
        +String fullName
        +String email
        +String phone
        +String password
        +String role
        +String accountStatus
        +DateTime createdAt
    }
    class HouseholdProfile{
        +UUID id
        +String address
        +String city
        +String area
        +String servicePreferences
    }
    class WorkerProfile{
        +UUID id
        +String bio
        +int experienceYears
        +String city
        +String area
        +String availabilityStatus
        +String verificationStatus
        +double averageRating
        +bool profileVisibility
    }
    class ServiceCategory{
        +UUID id
        +String name
        +String description
    }
    class WorkerService{
        +UUID id
        +double rate
        +String rateUnit
    }
    class AvailabilitySlot{
        +UUID id
        +String dayOfWeek
        +Time startTime
        +Time endTime
        +bool isAvailable
    }
    class Booking{
        +UUID id
        +Date bookingDate
        +Time startTime
        +Time endTime
        +String address
        +String notes
        +double agreedAmount
        +String status
    }
    class ServiceAgreement{
        +UUID id
        +String agreementText
        +double agreedAmount
        +String terms
        +String status
        +DateTime generatedAt
    }
    class PaymentRecord{
        +UUID id
        +double amount
        +String paymentMethod
        +String receiverAccountTitle
        +String receiverAccountNumber
        +String receiptURL
        +String transactionNote
        +String status
    }
    class Review{
        +UUID id
        +int rating
        +String comment
        +DateTime createdAt
    }
    class Notification{
        +UUID id
        +String title
        +String message
        +String type
        +bool isRead
        +DateTime createdAt
    }
    class VerificationRequest{
        +UUID id
        +String submittedDetails
        +String status
        +String rejectionReason
        +DateTime submittedAt
        +DateTime reviewedAt
    }
    class Dispute{
        +UUID id
        +String category
        +String description
        +String evidenceURL
        +String status
        +String adminRemarks
    }
    class IssueReport{
        +UUID id
        +String message
        +String status
        +DateTime createdAt
    }
    class AdminAction{
        +UUID id
        +String actionType
        +String remarks
        +DateTime actionDate
    }

    AppUser "1" --> "0..1" HouseholdProfile : owns
    AppUser "1" --> "0..1" WorkerProfile : owns
    WorkerProfile "1" --> "*" WorkerService : provides
    WorkerProfile "1" --> "*" AvailabilitySlot : has
    HouseholdProfile "1" --> "*" Booking : creates
    WorkerProfile "1" --> "*" Booking : receives
    ServiceCategory "1" --> "*" WorkerService : categorizes
    ServiceCategory "1" --> "*" Booking : requestedFor
    Booking "1" --> "0..1" ServiceAgreement : generates
    Booking "1" --> "*" PaymentRecord : has
    Booking "1" --> "0..1" Review : receives
    Booking "1" --> "*" Dispute : contains
    Booking "1" --> "*" IssueReport : reports
    WorkerProfile "1" --> "*" Review : receives
    WorkerProfile "1" --> "*" VerificationRequest : submits
    AppUser "1" --> "*" Notification : receives
    AdminAction --> VerificationRequest : manages
    AdminAction --> Dispute : resolves
```

---

## 8. Sequence Diagram
* **Purpose:** Represents the timeline of messages exchanged between user actors, client apps, services, and the database for key operations.

```mermaid
sequenceDiagram
    autonumber
    actor Household
    actor Worker
    actor Admin
    participant Mobile as Flutter Mobile App
    participant Booking as Booking Service
    participant Verify as Verification Service
    participant Notify as Notification Service
    participant DB as Supabase Database

    Household->>Mobile: Open Worker Details
    Household->>Mobile: Select Book Now
    Mobile->>Booking: Submit Booking Form
    Booking->>Booking: Validate Household, Worker, Service, Date & Time
    Booking->>DB: Check Worker Availability
    DB-->>Booking: Availability Status

    alt Worker Available
        Booking->>DB: Store Pending Booking
        Booking->>Notify: Create Worker Notification
        Notify-->>Worker: New Booking Request
        Booking-->>Mobile: Display Booking Confirmation
    else Worker Not Available
        Booking-->>Mobile: Display Booking Failed
    end

    Worker->>Mobile: Open Dashboard
    Worker->>Mobile: View Pending Requests
    Worker->>Mobile: Accept / Reject Booking
    Mobile->>Booking: Submit Booking Response
    Booking->>Booking: Validate Booking Status

    alt Booking Accepted
        Booking->>DB: Update Booking Status = Accepted
        Booking->>Notify: Notify Household
        Notify-->>Household: Booking Accepted
    else Booking Rejected
        Booking->>DB: Update Booking Status = Rejected
        Booking->>Notify: Notify Household
        Notify-->>Household: Booking Rejected
    end
    Booking-->>Mobile: Display Updated Status

    Worker->>Mobile: Submit Verification Request
    Mobile->>Verify: Send Verification Details
    Verify->>DB: Create Pending Verification Request
    Admin->>Verify: Review Verification Request

    alt Approved
        Verify->>DB: Update Verification Status = Verified
        Verify->>Notify: Notify Worker
        Notify-->>Worker: Verification Approved
    else Rejected
        Verify->>DB: Update Verification Status = Rejected
        Verify->>Notify: Notify Worker
        Notify-->>Worker: Verification Rejected
    end
```

---

## 9. State Transition Diagram
* **Purpose:** Represents the states of Verification, Bookings, Payments, and Disputes and the operations that trigger state changes.

```mermaid
stateDiagram-v2
    [*] --> NotSubmitted
    NotSubmitted --> PendingVerification : Submit Verification
    PendingVerification --> Verified : Approved
    PendingVerification --> RejectedVerification : Rejected
    RejectedVerification --> PendingVerification : Resubmit

    Verified --> PendingBooking : Worker Available
    PendingBooking --> Accepted : Worker Accepts
    PendingBooking --> RejectedBooking : Worker Rejects
    PendingBooking --> CancelledBooking : Household Cancels

    Accepted --> PendingPayment : Service Completed
    PendingPayment --> Submitted : Upload Receipt
    Submitted --> Confirmed : Worker Confirms
    Submitted --> Disputed : Payment Issue
    PendingPayment --> CancelledPayment : Booking Cancelled
    Submitted --> CancelledPayment : Booking Cancelled

    Confirmed --> CompletedBooking : Payment Successful
    Disputed --> OpenDispute : Create Dispute
    OpenDispute --> InReview : Admin Reviews
    InReview --> Resolved : Resolve
    InReview --> RejectedDispute : Reject

    Resolved --> CompletedBooking
    RejectedDispute --> CompletedBooking

    RejectedBooking --> [*]
    CancelledBooking --> [*]
    CancelledPayment --> [*]
    CompletedBooking --> [*]
```
