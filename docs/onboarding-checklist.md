# Contractor Onboarding Checklist

Use this checklist when manually onboarding a new contractor to RecoveryAI.

---

## 1. Pre-Call Preparation

- [ ] Confirm contractor's trade type (plumber / HVAC / electrician / roofer / other)
- [ ] Confirm they have a Finnish +358 phone number
- [ ] Ask: "Do you want to forward your existing number to us, or use a new number?"

## 2. Collect Business Information

| Field | Value |
|-------|-------|
| Business name | |
| Contact name | |
| Contact email | |
| Contact phone | |
| Trade type | |
| Typical job value (€) | |
| Working hours (start) | |
| Working hours (end) | |
| Working days | Mon Tue Wed Thu Fri Sat Sun |
| After-hours emergency policy | |
| Ring on after-hours emergency? | Yes / No |
| Timezone | Europe/Helsinki |
| Calendly URL | |

## 3. System Setup

### 3.1 Create Supabase Auth Account
- [ ] Go to Supabase Dashboard → Authentication → Users
- [ ] Create user with the contractor's email
- [ ] Send them the temporary password or invite link

### 3.2 Create Contractor Row
- [ ] Run the `database/onboard_contractor.sql` template with the collected info
- [ ] Verify the row appears in the `contractors` table
- [ ] **Important**: The contractor row `id` must match the Supabase Auth user `id`

### 3.3 Provision Twilio Number
- [ ] Go to Twilio Console → Phone Numbers → Buy a Number
- [ ] Search for a Finnish +358 number
- [ ] Purchase the number (~€3/month)
- [ ] Configure Voice webhook:
  - URL: `https://missed-lead-recovery.fly.dev/webhooks/twilio-voice`
  - Method: POST
  - Status callback: `https://missed-lead-recovery.fly.dev/webhooks/twilio-voice`
- [ ] Configure SMS webhook:
  - URL: `https://missed-lead-recovery.fly.dev/webhooks/twilio-sms`
  - Method: POST
- [ ] Update the contractor row with the Twilio number

### 3.4 Set Up Calendly
- [ ] Help contractor create a free Calendly account (if they don't have one)
- [ ] Get their scheduling link
- [ ] Create a Calendly webhook subscription (via API):
  ```bash
  curl -X POST https://api.calendly.com/webhook_subscriptions \
    -H "Authorization: Bearer YOUR_CALENDLY_PAT" \
    -H "Content-Type: application/json" \
    -d '{
      "url": "https://missed-lead-recovery.fly.dev/webhooks/calendly",
      "events": ["invitee.created"],
      "organization": "CALENDLY_ORG_URI",
      "scope": "organization"
    }'
  ```
- [ ] Note the webhook signing key for `CALENDLY_WEBHOOK_SECRET`

### 3.5 Call Forwarding Setup (if forwarding)
Walk the contractor through setting up conditional call forwarding:
- [ ] **DNA/Elisa/Telia (Finland)**: Dial `**61*TWILIO_NUMBER#` to forward on no-answer
- [ ] Test: Call the contractor's number, let it ring → should forward to Twilio
- [ ] Verify in Supabase: a test lead should appear

## 4. App Installation

- [ ] Send contractor the APK (or Play Store link when published)
- [ ] Help them sign in with their email/password
- [ ] Verify notification permission prompt appears → tap Allow
- [ ] Check `contractors` table → `fcm_token` should be populated
- [ ] Send a test push notification to verify delivery

## 5. Legal

- [ ] Have contractor sign the DPA (docs/dpa-template.md)
- [ ] Confirm they have a privacy policy link or we host it for them
- [ ] Explain the consent flow and GDPR obligations

## 6. Go-Live Test

- [ ] Call the Twilio number from a test phone → let it ring → hang up
- [ ] Verify: consent SMS arrives within 30 seconds
- [ ] Reply YES → verify qualification flow completes
- [ ] Book a Calendly time → verify confirmation SMS
- [ ] Check the app: lead appears in real-time
- [ ] Mark lead as completed → verify satisfaction follow-up is scheduled

## 7. First Week Monitoring

- [ ] Check daily: are leads being created correctly?
- [ ] Monitor SMS delivery (Twilio Console → Messaging → Logs)
- [ ] Check for DNR alerts firing appropriately
- [ ] Get verbal feedback from contractor after 3 days
- [ ] Iterate on SMS wording if needed
