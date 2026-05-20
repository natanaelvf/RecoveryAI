# Missed-Lead Recovery SaaS — Tasks

## Phase 1: Project Setup (Week 1)

- [ ] Create Supabase project (Frankfurt EU region)
  - [ ] Set up database with schema from implementation plan
  - [ ] Enable Row Level Security policies (contractors see only their data)
  - [ ] Configure Supabase Auth (email/password)
  - [ ] Enable Realtime on `leads` table
- [ ] Create Twilio account
  - [ ] Provision a test Finnish +358 number
  - [ ] Configure voice webhook URL (placeholder, update after backend deploy)
  - [ ] Configure SMS webhook URL (placeholder)
  - [ ] Verify Finnish caller ID regulations — can we pass through the lead's number?
- [ ] Scaffold Node.js backend (TypeScript)
  - [ ] Init project with Express or Fastify
  - [ ] Set up Supabase client (server-side, service role key)
  - [ ] Set up Twilio SDK
  - [ ] Set up environment variables (.env): Supabase URL/key, Twilio SID/auth/number, Calendly API key
  - [ ] Deploy to EU-region host (Railway, Render, or Fly.io) with CI/CD
- [ ] Scaffold Flutter Android project
  - [ ] Init project
  - [ ] Add dependencies: supabase_flutter, dio (HTTP), firebase_messaging, go_router
  - [ ] Set up Firebase project for FCM (push notifications)
  - [ ] Configure Supabase client in Flutter

---

## Phase 2: Core Backend (Weeks 2–3)

### Twilio Voice Webhook
- [ ] `POST /webhooks/twilio/voice` — incoming call handler
  - [ ] Look up contractor by Twilio number
  - [ ] Check working hours (contractor timezone)
  - [ ] Within hours: return TwiML `<Dial>` to contractor's real phone with timeout + status callback URL
  - [ ] After hours: return TwiML `<Say>` message + `<Hangup>`, trigger missed call flow
  - [ ] Set caller ID on `<Dial>` to lead's number (if Finnish regulations allow, otherwise skip)
- [ ] `POST /webhooks/twilio/voice/status` — call status callback
  - [ ] On `no-answer` or `busy`: trigger missed call flow
  - [ ] On `completed` or `answered`: no action

### Missed Call Flow (shared logic)
- [ ] Deduplication: query leads for same `caller_phone` + `contractor_id` within 24 hours
  - [ ] If duplicate: increment `call_count`, do not send SMS
  - [ ] If new: create lead record, send consent SMS
- [ ] Send consent SMS via Twilio (English draft, Finnish before launch)
- [ ] Set lead status to `consent_sent`

### SMS State Machine
- [ ] `POST /webhooks/twilio/sms` — inbound SMS handler
  - [ ] Look up lead by `caller_phone` + Twilio number → contractor
  - [ ] Route based on lead `status`:
    - [ ] `consent_sent` → check for YES/STOP → advance to `opted_in`, send issue question
    - [ ] `opted_in` → store `issue_description`, send urgency question → `qualifying`
    - [ ] `qualifying` → parse urgency (1–4 mapping), store, send name question + Calendly link → `booking_sent`
    - [ ] `booking_sent` → store `caller_name` from reply (best effort)
  - [ ] Log every inbound/outbound message to `messages` table
  - [ ] Increment `sms_used_this_month` on contractor

### Calendly Integration
- [ ] `POST /webhooks/calendly/booking` — booking event handler
  - [ ] Match booking to lead (by phone number or Calendly invitee email if available)
  - [ ] Update lead: `status = 'booked'`, `booking_time`, `calendly_event_id`
  - [ ] Send confirmation SMS to lead
  - [ ] Send push notification to contractor (via FCM)
- [ ] Set up Calendly webhook subscription (per contractor, during manual onboarding)

### DNR Check Cron
- [ ] Scheduled job every 5 minutes
  - [ ] Query leads where `status = 'booking_sent'` and threshold exceeded based on urgency:
    - [ ] emergency/high urgency: `created_at + urgency_threshold_urgent_min < now()`
    - [ ] normal urgency: `created_at + urgency_threshold_normal_min < now()`
  - [ ] For each: set `dnr_alert_sent = true`, send SMS to contractor, send push notification
- [ ] After-hours emergency: if lead urgency is emergency AND `called_during_after_hours = true` AND `contractor.after_hours_ring = true`, send immediate push notification (don't wait for threshold)

### Satisfaction Follow-up Cron
- [ ] Scheduled job every 5 minutes
  - [ ] Query `scheduled_tasks` where `task_type = 'satisfaction_followup'` and `execute_at < now()` and `executed = false`
  - [ ] Send satisfaction SMS to lead
  - [ ] Parse reply: number → `satisfaction_score`, text → `satisfaction_feedback`
  - [ ] If score ≤ 2: push notification to contractor
  - [ ] Mark task as executed

### REST API (for Flutter app)
- [ ] Auth middleware: validate Supabase JWT, extract contractor_id
- [ ] `GET /api/leads` — list leads for contractor, filterable by status, paginated
- [ ] `GET /api/leads/:id` — lead detail with messages
- [ ] `PATCH /api/leads/:id` — update status, add notes, set estimated_value, mark complete
  - [ ] On mark complete: create `satisfaction_followup` scheduled task (24hr delay)
  - [ ] Set `estimated_value` to `contractor.default_job_value` if not overridden
- [ ] `GET /api/stats` — recovered leads count, total estimated value, response rate, this month vs last
- [ ] `GET /api/contractor/settings` — current settings
- [ ] `PATCH /api/contractor/settings` — update working hours, thresholds, emergency policy

### Push Notifications (FCM)
- [ ] Utility function: send FCM notification to contractor's device token
- [ ] Store device token on contractor login (sent from Flutter app)
- [ ] Trigger points: new lead, booking confirmed, DNR alert, low satisfaction score, after-hours emergency

### GDPR
- [ ] `DELETE /api/leads/:id/gdpr` — full deletion
  - [ ] Delete lead record
  - [ ] Delete all associated messages
  - [ ] Cancel associated scheduled tasks
  - [ ] Log deletion event (timestamp + requesting contractor, no PII)

---

## Phase 3: Flutter App (Weeks 2–3, parallel with backend)

### Auth
- [ ] Login screen (email + password via Supabase Auth)
- [ ] Session persistence (auto-login on app restart)
- [ ] Register FCM device token on login → send to backend

### Lead List Screen
- [ ] Fetch `GET /api/leads` on load
- [ ] Display: caller name (or phone if no name), issue snippet, urgency badge, status badge, time ago
- [ ] Show "Called X times" badge if `call_count > 1`
- [ ] Filter tabs or chips: All / New / Booked / Completed / DNR
- [ ] Pull-to-refresh
- [ ] Supabase Realtime subscription: auto-update list when lead status changes

### Lead Detail Screen
- [ ] Header: name, phone (tap to call), urgency, status
- [ ] Conversation log (messages table, chronological)
- [ ] Booking info (if booked): date/time, Calendly link
- [ ] If `called_during_after_hours`: show contractor's emergency policy text
- [ ] Notes field (editable, saved via PATCH)
- [ ] Estimated value field (pre-filled with default, editable)
- [ ] Action buttons based on status:
  - [ ] "Mark Complete" → triggers satisfaction follow-up scheduling
  - [ ] "Call Lead" → opens phone dialer
- [ ] Satisfaction results (if followed up): score + feedback text

### Dashboard Screen
- [ ] Stats cards: leads recovered this month, total estimated value, response rate (% of consent → booked)
- [ ] Comparison to last month (arrow up/down + %)
- [ ] Simple bar chart: leads per day (last 30 days) — use `fl_chart` package

### Settings Screen
- [ ] Business name (read-only in V1, set during onboarding)
- [ ] Working hours: start time, end time, working days (checkboxes)
- [ ] Urgency thresholds: urgent (minutes), non-urgent (minutes)
- [ ] After-hours emergency policy (text field)
- [ ] Ring on after-hours emergency (toggle)
- [ ] Trade type + default job value (read-only in V1, set during onboarding)

### Push Notifications
- [ ] Handle FCM messages: show system notification when app is in background
- [ ] On tap: navigate to relevant lead detail screen
- [ ] Notification types: new_lead, booking_confirmed, dnr_alert, low_satisfaction, after_hours_emergency

---

## Phase 4: GDPR & Legal (Week 3, parallel)

- [ ] Draft privacy policy (English first, translate to Finnish)
  - [ ] What data is collected (phone, name, issue, urgency, conversation log)
  - [ ] Purpose (connecting lead with contractor)
  - [ ] Retention period (12 months default)
  - [ ] Right to deletion (how to request)
  - [ ] Data processor (your company) and controller (contractor)
- [ ] Host privacy policy on a public URL
- [ ] Draft Data Processing Agreement template
- [ ] Have both reviewed by a lawyer familiar with Finnish/EU GDPR
- [ ] Add data retention cron job: anonymize leads older than 12 months with no activity

---

## Phase 5: Testing & Polish (Week 4)

### Automated Tests
- [ ] Unit: SMS state machine — test every status transition with valid and invalid inputs
- [ ] Unit: deduplication logic — same phone within 24hr, different phone, same phone after 24hr
- [ ] Unit: DNR threshold calculation — urgent vs normal, edge cases around exact threshold
- [ ] Unit: working hours check — timezone handling, boundary conditions (exactly at start/end)
- [ ] Integration: Twilio voice webhook → lead creation → consent SMS sent
- [ ] Integration: full SMS sequence (mock Twilio) → lead progresses through all statuses
- [ ] Integration: Calendly booking webhook → lead status update → confirmation SMS
- [ ] Integration: DNR cron → alert sent when threshold exceeded
- [ ] Integration: satisfaction cron → SMS sent, response parsed correctly
- [ ] Integration: GDPR deletion → all related data removed, audit log created

### Manual / E2E Testing
- [ ] Provision real Finnish Twilio number, call from real phone, verify full flow
- [ ] Test conditional call forwarding from a real Finnish carrier → Twilio
- [ ] Install Flutter app on real Android device
- [ ] Verify push notifications arrive for each trigger type
- [ ] Verify Calendly booking from lead's perspective (click link → pick time → confirmation SMS)
- [ ] Test after-hours: call outside working hours, verify no ring + SMS flow + emergency notification
- [ ] Test dedup: call same number 3 times, verify single lead with `call_count = 3`

### SMS Copy
- [ ] Finalize English draft of all SMS templates
- [ ] Get native Finnish speaker to translate/review all templates
- [ ] Test Finnish SMS end-to-end (character encoding, message length — Finnish uses more chars)

---

## Phase 6: First Contractor Onboarding (Week 5)

- [ ] Find first contractor (personal network, cold outreach to Finnish plumbers/HVAC)
- [ ] Onboarding call:
  - [ ] Explain the service, get buy-in
  - [ ] Ask: forward existing number or new number?
  - [ ] Collect: business name, trade type, typical job value, phone number, email
  - [ ] Ask: working hours, what counts as emergency for their trade
  - [ ] Have them create a free Calendly account, get their scheduling link
  - [ ] Sign DPA
- [ ] Set up in system:
  - [ ] Create contractor record in Supabase
  - [ ] Provision Twilio number, configure webhooks
  - [ ] Set up Calendly webhook subscription
  - [ ] Create Supabase Auth account for them
  - [ ] Help them install Flutter app, log in, verify push notifications work
  - [ ] If forwarding: walk them through setting up conditional call forwarding on their carrier
- [ ] Monitor first week closely:
  - [ ] Check every lead for correct flow
  - [ ] Verify SMS timing, content, urgency classification
  - [ ] Get feedback from contractor: what's useful, what's confusing, what's missing
  - [ ] Iterate based on feedback before onboarding contractor #2
