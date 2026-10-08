# HomeEase — Project Documentation Directory

Welcome to the central documentation repository for **HomeEase** (Final Year Project - Computer Science / Software Engineering, COMSATS University Islamabad).

This directory maintains all academic deliverables, engineering specifications, diagrams, and milestone evaluation artifacts organized chronologically.

---

## 📂 Directory Structure Overview

```text
Docs/
├── 00_Project_Specs/               # Core project specifications & orientation
│   ├── HOME_EASE_PROJECT_ORIENTATION.md  # Technical orientation, stack, & milestones
│   └── HOME_EASE_STITCH_UI_SPEC.md       # Stitch UI & screen specifications
│
├── 01_Proposal_10/                 # Milestone 1: 10% Evaluation (Project Proposal)
│   ├── HomeEase_Proposal_10.docx         # Proposal Word document
│   ├── HomeEase_Proposal_v1.0_10.pdf     # Proposal PDF (initial submission)
│   ├── HomeEase_Proposal_v1.5_10.pdf     # Proposal PDF (revised v1.5 submission)
│   └── HomeEase_Proposal_Presentation_10.pptx # Proposal presentation slides
│
├── 02_Requirements_and_Design_30/  # Milestone 2: 30% Evaluation (SRS & SDD)
│   ├── HomeEase_SRS_30.docx              # Software Requirements Specification (SRS)
│   ├── HomeEase_SDD_30.docx              # Software Design Document (SDD)
│   ├── HomeEase_Presentation_30.pptm     # 30% Evaluation presentation
│   ├── SRS_Summary.md                    # Structured summary of requirements & actors
│   ├── SDD_Summary.md                    # Structured summary of architecture & modular design
│   ├── Diagrams_Summary.md               # Summary of 9 core system design diagrams (with Mermaid)
│   ├── apk/
│   │   └── HomeEase.apk                  # 30% Milestone Android Prototype APK
│   └── diagrams/                         # High-resolution exported PNG diagrams & draw.io source
│       ├── HomeEase_Diagram.drawio       # Master draw.io file (all 9 diagrams)
│       ├── Architecture.png              # Multi-tier system architecture
│       ├── Class.png                     # Domain class model
│       ├── ERD.png                       # Database Entity-Relationship Diagram
│       ├── ProcessFlow.png               # End-to-end platform workflow
│       ├── Sequence.png                  # Dynamic sequence interactions
│       ├── StateTransition.png           # State transition lifecycle
│       └── Use_Case_Diagram.png          # System use cases & actor boundaries
│
├── 03_Thesis_60/                   # Milestone 3: 60% Evaluation (Thesis Draft & Prototype)
│   ├── HomeEase_Thesis_60.docx           # Complete 60% thesis report (MS Word)
│   ├── HomeEase_Thesis_60.pdf            # Compiled thesis document (PDF)
│   ├── HomeEase_Thesis_60.md             # Markdown thesis source
│   ├── main.tex                          # Academic LaTeX thesis source
│   ├── thesis-assets/                    # Assets and images mapped for LaTeX compilation
│   └── diagrams/                         # High-res diagrams & screen mockups
│       ├── HomeEase_Diagram.drawio       # Master draw.io diagram file
│       ├── cui_logo.jpeg                 # University insignia (CUI)
│       ├── Architecture.png              # High-level architecture
│       ├── Class.png                     # Class diagram
│       ├── ERD.png                       # Database schema
│       ├── ProcessFlow.png               # Process flow diagram
│       ├── Sequence.png                  # Sequence diagram
│       ├── StateTransition.png           # State transition diagram
│       ├── Use_Case_Diagram.png          # Use case diagram
│       └── fig_5_*.png                   # High-fidelity Flutter screen mockups (Figs 5.1 - 5.6)
│
├── references/                     # Benchmarks & external references
│   └── TrekPal_Benchmark/                # CUI benchmark thesis template & sample LaTeX files
│       ├── trekpal_60_thesis.docx
│       ├── trekpal.tex
│       └── diagrams/
│
└── README.md                       # This index file
```

---

## 🎯 Milestones Breakdown

### 1. [00_Project_Specs](file:///c:/Users/AbuZar/Desktop/Fyp/HomeEase/Docs/00_Project_Specs)
Contains the ongoing architectural blueprints and high-level specifications:
- [`HOME_EASE_PROJECT_ORIENTATION.md`](file:///c:/Users/AbuZar/Desktop/Fyp/HomeEase/Docs/00_Project_Specs/HOME_EASE_PROJECT_ORIENTATION.md) — Tech stack decisions, Supabase backend strategy, and roadmap.
- [`HOME_EASE_STITCH_UI_SPEC.md`](file:///c:/Users/AbuZar/Desktop/Fyp/HomeEase/Docs/00_Project_Specs/HOME_EASE_STITCH_UI_SPEC.md) — Mobile UI specification for domestic workers and household clients.

### 2. [01_Proposal_10](file:///c:/Users/AbuZar/Desktop/Fyp/HomeEase/Docs/01_Proposal_10)
Documents submitted for the initial **10% Proposal Evaluation**:
- Scope definition, problem statement, and supervisor approvals.
- Presentation slides used for committee defense.

### 3. [02_Requirements_and_Design_30](file:///c:/Users/AbuZar/Desktop/Fyp/HomeEase/Docs/02_Requirements_and_Design_30)
Deliverables submitted for the **30% Software Engineering Evaluation**:
- **SRS**: Functional and Non-Functional Requirements, IEEE 830-compliant.
- **SDD**: Comprehensive architecture, subsystem breakdown, interface design.
- **Prototype**: Android APK (`HomeEase.apk`) demonstrating early UI flows.
- **Diagrams**: Vector drawings created in `draw.io` and exported to PNG.

### 4. [03_Thesis_60](file:///c:/Users/AbuZar/Desktop/Fyp/HomeEase/Docs/03_Thesis_60)
Deliverables submitted for the **60% Prototype & Thesis Defense**:
- **Thesis Document**: Chapters 1 (Introduction), 2 (Literature Review), 3 (Requirements), 4 (Design & Architecture), 5 (Implementation & Screenshots).
- **LaTeX Source**: [`main.tex`](file:///c:/Users/AbuZar/Desktop/Fyp/HomeEase/Docs/03_Thesis_60/main.tex) configured for CUI Abbottabad thesis format with all embedded diagrams linked via `thesis-assets/`.

### 5. [references](file:///c:/Users/AbuZar/Desktop/Fyp/HomeEase/Docs/references)
- Benchmark documents and formatting references (TrekPal benchmark project) used to align thesis structure with academic guidelines.

---

## 🧹 Housekeeping & Maintenance Rules
1. **Naming Standard**: Use `PascalCase` or `snake_case` with explicit milestone tags (e.g., `HomeEase_Thesis_60.docx`). Avoid whitespace, special characters, and `%` symbols in file or folder names.
2. **Diagram Updates**: Modify [`HomeEase_Diagram.drawio`](file:///c:/Users/AbuZar/Desktop/Fyp/HomeEase/Docs/03_Thesis_60/diagrams/HomeEase_Diagram.drawio) in `diagrams/` and export PNGs at high resolution with transparent backgrounds disabled.
3. **LaTeX Compiles**: Keep `main.tex` and `thesis-assets/` synchronized to ensure zero-error builds on both local LaTeX (MiKTeX / TeX Live) and Overleaf.
