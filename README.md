# Missed-Lead Recovery

A SaaS platform that automatically recovers missed leads for home service contractors (plumbers, HVAC, electricians, roofers). When a contractor misses a call, the system detects it via Twilio, engages the caller through an SMS qualification sequence, books a callback via Calendly, and follows up with satisfaction surveys — turning missed calls into booked jobs and tracked revenue.

---

## Architecture

The platform is built on three core layers:

- **Supabase** (Frankfurt EU region) — Postgres database with Row Level Security, Auth (email/password), and Realtime subscriptions for live lead updates.
- **Node.js Backend** (TypeScript) — Handles Twilio voice/SMS webhooks, Calendly booking webhooks, scheduled cron jobs (DNR checks, satisfaction follow-ups), FCM push notifications, and a REST API for the mobile app.
- **Flutter Android App** — Contractor-facing mobile app with lead management, real-time conversation logs, a revenue dashboard, and push notification handling.

```
Lead calls → Twilio (missed call detection) → Node.js backend → Supabase
                                                    ↓
                                              SMS sequence
                                              (consent → issue → urgency → name → booking link)
                                                    ↓
                                              Calendly booking → confirmation → satisfaction follow-up
```

---

## Project Structure

```
missed-lead-recovery/
├── README.md
├── .gitignore
├── docs/
│   ├── implementation_plan.md      # Full architecture & workflow spec
│   └── tasks.md                    # Phased task breakdown
├── database/
│   ├── schema.sql                  # Supabase Postgres schema + RLS + indexes
│   └── seed.sql                    # Test data (1 contractor, 2 leads)
├── backend/                        # Node.js (TypeScript) — coming soon
│   ├── src/
│   │   ├── webhooks/               # Twilio voice/SMS, Calendly
│   │   ├── api/                    # REST API routes
│   │   ├── cron/                   # DNR check, satisfaction follow-up
│   │   ├── services/               # SMS state machine, FCM, Calendly
│   │   └── utils/                  # Supabase client, Twilio client
│   ├── package.json
│   └── tsconfig.json
└── app/                            # Flutter Android app — coming soon
    ├── lib/
    │   ├── screens/                # Login, Lead List, Lead Detail, Dashboard, Settings
    │   ├── services/               # API client, Supabase, FCM
    │   ├── models/                 # Lead, Contractor, Message
    │   └── widgets/                # Reusable UI components
    └── pubspec.yaml
```

---

## Getting Started

### Prerequisites

- Node.js 18+
- npm or yarn
- Supabase account (project in Frankfurt EU)
- Twilio account with a Finnish +358 number
- Calendly account (free tier)
- Flutter SDK (for the mobile app)
- Firebase project (for FCM push notifications)

### Setup

1. **Clone the repository:**
   ```bash
   git clone <repo-url>
   cd missed-lead-recovery
   ```

2. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Fill in: SUPABASE_URL, SUPABASE_SERVICE_KEY, TWILIO_SID, TWILIO_AUTH_TOKEN,
   #          TWILIO_PHONE_NUMBER, CALENDLY_WEBHOOK_SECRET, FCM_SERVER_KEY
   ```

3. **Apply the database schema:**
   ```bash
   # Run database/schema.sql in the Supabase SQL editor
   # Optionally run database/seed.sql for test data
   ```

4. **Install backend dependencies:**
   ```bash
   cd backend
   npm install
   ```

5. **Start the development server:**
   ```bash
   npm run dev
   ```

---

## Documentation

- **[Implementation Plan](docs/implementation_plan.md)** — Full architecture, database schema, workflow detail, GDPR requirements, pricing, and timeline.
- **[Tasks](docs/tasks.md)** — Phased task breakdown across setup, backend, app, GDPR, testing, and onboarding.
