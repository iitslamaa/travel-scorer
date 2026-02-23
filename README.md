Travel Adventure Finder

Production Travel Intelligence Platform
Web · iOS · React Native · Monorepo Architecture

Travel Adventure Finder is a full-stack travel intelligence platform that ranks every country and territory using a weighted, data-driven scoring system.

The goal is to transform fragmented global datasets into a clear, actionable decision engine for travelers.

Built end-to-end with scalable architecture, clean boundaries, and shared cross-platform logic.

⸻

Overview

Travel Adventure Finder calculates a dynamic Travelability Score (0–100) for every country using normalized global datasets.

Users can:
	•	Explore ranked countries
	•	Adjust scoring weights
	•	View safety advisories
	•	Compare affordability
	•	Analyze visa accessibility
	•	Evaluate seasonal timing
	•	Track personal travel lists
	•	Use social profile features
	•	Access real-time data updates

This is not a static dataset app. It is a structured scoring engine layered over normalized global inputs.

⸻

Scoring System

Each country receives a weighted composite score built from multiple normalized dimensions.

Dimensions include:
	•	Safety (US State Department travel advisory levels)
	•	Affordability (GDP PPP and cost proxies)
	•	Visa Ease (entry complexity)
	•	Seasonality (best travel months)
	•	English Accessibility (EF EPI)
	•	Transit and Infrastructure
	•	Women and Solo Safety
	•	Flight Accessibility

Weights are configurable and normalized dynamically.

Scoring logic lives in a shared TypeScript domain library used across web and mobile platforms.

⸻

Architecture Overview

Monorepo structure with shared domain logic across platforms.

```
travel-af/
├── apps/
│   ├── web/                             # Next.js 15 web application
│   │   ├── app/                         # App Router (pages, layouts, API routes)
│   │   │   └── api/
│   │   │       ├── advisories/route.ts  # Fetch & normalize travel.state.gov advisories
│   │   │       └── countries/route.ts   # Join UN/ISO seeds + advisories into one response
│   │   ├── lib/                         # Country matching, data joins, utilities
│   │   ├── data/                        # UN/ISO seed data + normalized datasets
│   │   └── scripts/
│   │       └── generate-seeds.mjs       # Idempotent seed generator
│   │
│   ├── mobile/                          # React Native (Expo Router) app
│   │   ├── app/                         # Expo Router entry + screens
│   │   ├── components/                  # Shared UI components
│   │   ├── hooks/                       # Custom React hooks
│   │   ├── context/                     # Auth + state providers
│   │   └── utils/                       # Overlay builders, helpers, adapters
│   │
│   └── ios/                             # Native Swift iOS application
│       ├── Features/                    # Feature modules (MVVM structured)
│       ├── Core/                        # Networking, models, shared utilities
│       └── Resources/                   # Assets and configuration
│
├── packages/
│   └── shared/                          # Shared TypeScript scoring engine
│       ├── src/                         # score.ts, weights.ts, types.ts, index.ts
│       └── dist/                        # Compiled output
│
├── data/                                # Canonical country metadata
│
└── package.json                         # npm workspaces (monorepo root)
```
⸻

Mobile Stack

Native iOS:
	•	Swift
	•	SwiftUI
	•	MVVM architecture
	•	Async/Await concurrency
	•	RESTful integration
	•	Real-time state synchronization
	•	Performance profiling with Instruments

Published on the Apple App Store.

React Native (Cross-Platform):
	•	Expo Router
	•	TypeScript
	•	Shared domain logic
	•	Platform-gated modules
	•	Web-compatible build configuration

⸻

Shared Domain Layer

Package: @travel-af/shared

Responsibilities:
	•	Score calculation engine
	•	Weight normalization
	•	Types and data contracts
	•	Deterministic score outputs
	•	Cross-platform logic reuse

This ensures:
	•	No duplicated scoring logic
	•	Predictable outputs across platforms
	•	Clean separation between UI and computation

⸻

Backend and Data
	•	Supabase (Postgres)
	•	Row-Level Security (RLS)
	•	Authentication flows
	•	Real-time sync
	•	Structured data modeling

Data sources include:
	•	US State Department
	•	UN ISO/M49
	•	World Bank
	•	EF English Proficiency Index
	•	Public visa datasets

All datasets are normalized before scoring to reduce bias and inconsistencies.

⸻

Engineering Principles
	•	Deterministic scoring logic
	•	Clear separation of UI and domain layers
	•	Modular MVVM boundaries
	•	Idempotent seed generation
	•	Runtime advisory parsing resilience
	•	Cross-platform shared contracts
	•	Performance-focused async workflows
	•	Incremental refactoring over rewrites

⸻

Reliability and Debugging
	•	Structured API boundaries
	•	Deterministic weight normalization
	•	Advisory parsing guards for runtime failures
	•	Platform-specific module gating for React Native Web compatibility
	•	Xcode Instruments profiling
	•	Incremental feature PR workflow

⸻

Running Locally

Requirements:
	•	Node 18+
	•	npm 9+
	•	Xcode (for iOS)
	•	Expo CLI (for mobile)

Install:

git clone https://github.com/iitslamaa/travel-af.git
cd travel-af
npm install

Build shared library:

npm run build -w @travel-af/shared

Run web:

npm run dev -w apps/web

Open:
http://localhost:3000

Run mobile (Expo):

cd apps/mobile
npx expo start

⸻

Contribution Activity
	•	400+ commits in the core repository
	•	190+ merged pull requests
	•	Continuous iteration and refactoring
	•	Active 2026 development cycle

⸻

Purpose

Most travel apps present static information.

Travel Adventure Finder builds a structured scoring system that:
	•	Abstracts global datasets
	•	Normalizes inconsistencies
	•	Enables configurable prioritization
	•	Supports cross-platform delivery
	•	Demonstrates production-grade system design

⸻

Author

Lama Yassine
Mobile and Systems Engineer
Swift · TypeScript · Systems Architecture · Cross-Platform Mobile
