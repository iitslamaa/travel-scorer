# ✈️ Travel AF — Travelability Scoring App

**Status:** Work in Progress (Public Portfolio Project)

A modern travel discovery app that ranks every country and territory by **“Travelability”** — a composite score that reflects safety, affordability, seasonality, language accessibility, visa ease, transit quality, and more.

Built as a **TypeScript monorepo** with:
- **Next.js (Web)** — `apps/web`
- **Shared Scoring Library** — `packages/shared`
- (Soon) **Expo Mobile App** — `apps/mobile`

---

## 🌍 Overview

Travel AF aggregates and normalizes open global data sources:

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

## 🧱 Tech Stack

| Layer | Tech |
|-------|------|
| Web | Next.js 15 + React 19 + TypeScript |
| Shared Logic | TypeScript library (`@travel-af/shared`) |
| Styling | TailwindCSS + dark mode |
| Build | npm workspaces + tsc monorepo setup |
| Mobile (planned) | Expo + React Native + Metro monorepo integration |

---

## 🗂️ Project Structure
