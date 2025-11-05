# TravelScorer — Travelability Scoring App

**Status:** Work in Progress (Public Portfolio Project)

A modern travel discovery app that ranks every country and territory by **“Travelability”** — a composite score that reflects safety, affordability, seasonality, language accessibility, visa ease, transit quality, and more.

Built as a **TypeScript monorepo** with:
- **Next.js (Web)** — `apps/web`
- **Shared Scoring Library** — `packages/shared`
- (Soon) **Expo Mobile App** — `apps/mobile`

---

## Overview

TravelScorer aggregates and normalizes open global data sources:

| Data Source | Purpose |
|--------------|----------|
| [US State Dept (travel.state.gov)](https://travel.state.gov) | Live safety advisory levels (1–4) |
| United Nations (UN M49 / ISO-3166) | Canonical country and territory metadata |
| World Bank, CIA Factbook (planned) | Affordability, GDP PPP, infrastructure metrics |
| English Proficiency Index | English accessibility |
| VisaGuide, T-Mobile Maps, Weather APIs (planned) | Visa & mobility data, connectivity, best travel months |

Each country receives a **Travelability Score (0–100)** based on weighted factors:

| Factor | Weight | Example |
|--------|--------|----------|
| Safety | 25% | US Travel Advisory Level |
| Affordability | 15% | GDP PPP, cost of living index |
| English | 10% | EF EPI |
| Seasonality | 10% | Best travel months |
| Visa | 10% | Ease of entry for US travelers |
| Flight Time | 10% | Estimated distance from NYC |
| Transit | 10% | Public transportation availability |
| Women Safety | 5% | UN/NGO data |
| Solo Safety | 5% | Traveler sentiment |

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Web | Next.js 15 + React 19 + TypeScript |
| Shared Logic | TypeScript library (`@travel-af/shared`) |
| Styling | TailwindCSS + dark mode |
| Build | npm workspaces + tsc monorepo setup |
| Mobile (planned) | Expo + React Native + Metro monorepo integration |

---

## Project Structure

```
travel-af/
├── apps/
│   └── web/                     # Next.js app (website)
│       ├── app/                 # Next.js App Router (pages, API routes)
│       │   └── api/
│       │       ├── advisories/route.ts   # Fetch & normalize travel.state.gov advisories
│       │       └── countries/route.ts    # Join UN/ISO seeds + advisories into one response
│       ├── lib/                 # Country matching, facts joiners, types
│       ├── data/                # UN/ISO seed data + public datasets
│       └── scripts/
│           └── generate-seeds.mjs # Seed generator (idempotent)
│
├── packages/
│   └── shared/                  # Shared TypeScript library (scoring/types)
│       ├── src/                 # source (score.ts, types.ts, index.ts)
│       └── dist/                # compiled output after build
│
└── package.json                 # npm workspaces (monorepo)
```

## Running Locally

**Requirements**
- Node 18+ (or 20+ recommended)
- npm 9+ (uses **npm workspaces**)

### 1) Clone & install

```bash
git clone https://github.com/iitslamaa/travel-af.git
cd travel-af
npm install
```

### 2) Build the Shared Library

```
# from the repo root
npm run build -w @travel-af/shared
# (or) cd packages/shared && npm run build
```

### 3) Start the web app (Next.js)
```
# from the repo root
npm run dev -w apps/web
# open http://localhost:3000
```
