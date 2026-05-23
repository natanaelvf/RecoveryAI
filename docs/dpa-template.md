# Data Processing Agreement (DPA) — RecoveryAI

**Between:**
- **Data Controller** ("Controller"): The contractor using RecoveryAI
- **Data Processor** ("Processor"): RecoveryAI [Your company legal name]

**Effective Date:** [Date of signing]

---

## 1. Subject Matter and Duration

This DPA governs the processing of personal data by the Processor on behalf of the Controller in connection with the RecoveryAI missed-lead recovery service.

The duration of processing corresponds to the term of the service agreement between the parties.

---

## 2. Nature and Purpose of Processing

The Processor processes personal data for the sole purpose of:
- Detecting missed calls to the Controller's phone number
- Conducting SMS-based lead qualification on behalf of the Controller
- Facilitating appointment booking between the lead and the Controller
- Sending satisfaction follow-up surveys on behalf of the Controller
- Providing the Controller with a dashboard to manage recovered leads

---

## 3. Categories of Data Subjects

- **Leads**: Individuals who call the Controller's phone number and are not answered

---

## 4. Types of Personal Data Processed

- Phone number
- Name (if provided by the lead)
- Issue description (free-text)
- Urgency level (selected by the lead)
- Booking time
- Satisfaction score and feedback
- SMS conversation log

---

## 5. Obligations of the Processor

The Processor shall:

### 5.1 Instructions
Process personal data only on documented instructions from the Controller, unless required by EU or Member State law.

### 5.2 Confidentiality
Ensure that persons authorized to process the personal data have committed themselves to confidentiality.

### 5.3 Security Measures
Implement appropriate technical and organizational measures to ensure a level of security appropriate to the risk, including:
- Encryption of data in transit (TLS 1.2+) and at rest (AES-256)
- Row Level Security in the database (contractor isolation)
- Authentication required for all API access
- Regular security updates and patching
- Automated data anonymization after retention period

### 5.4 Sub-processors
The Processor uses the following sub-processors:

| Sub-processor | Purpose | Location | DPA in place? |
|---------------|---------|----------|---------------|
| Supabase Inc. | Database & Auth | Frankfurt, EU | Yes |
| Twilio Inc. | SMS delivery | EU | Yes |
| Calendly LLC | Booking | US (EU-US DPF) | Yes |
| Google LLC (Firebase) | Push notifications | Global (EU-US DPF) | Yes |
| Fly.io Inc. | Backend hosting | Frankfurt, EU | Yes |

The Processor shall inform the Controller of any intended changes concerning the addition or replacement of sub-processors, giving the Controller the opportunity to object.

### 5.5 Data Subject Rights
The Processor shall assist the Controller in fulfilling its obligation to respond to data subject requests (access, rectification, erasure, restriction, portability, objection).

The Processor provides:
- A GDPR deletion endpoint that fully removes all lead data
- An audit log of all deletion actions
- The ability to export lead data on request

### 5.6 Data Breach Notification
The Processor shall notify the Controller without undue delay (and in any case within 72 hours) after becoming aware of a personal data breach.

### 5.7 Data Protection Impact Assessment
The Processor shall assist the Controller with data protection impact assessments and prior consultations with supervisory authorities, where required.

### 5.8 Deletion or Return
Upon termination of the service, the Processor shall delete all personal data and confirm deletion in writing, unless EU or Member State law requires storage.

---

## 6. Obligations of the Controller

The Controller shall:
- Ensure a lawful basis for processing (consent via SMS opt-in)
- Inform data subjects about the processing via the privacy policy
- Respond to data subject requests within the legally required timeframe
- Not instruct the Processor to process data in a manner that would violate GDPR

---

## 7. Data Retention

- Active leads: retained until job completion + 12 months
- After retention period: automatically anonymized by the Processor
- The Controller may request immediate deletion of specific leads at any time

---

## 8. International Data Transfers

The Processor stores primary data within the EU (Frankfurt, Germany). Sub-processors in the US participate in the EU-US Data Privacy Framework (DPF) and have appropriate safeguards in place.

---

## 9. Audits

The Processor shall make available to the Controller all information necessary to demonstrate compliance with GDPR Article 28, and allow for and contribute to audits, including inspections, conducted by the Controller or an auditor mandated by the Controller.

---

## 10. Liability

Each party's liability under this DPA is subject to the limitations set out in the main service agreement.

---

## 11. Governing Law

This DPA shall be governed by Finnish law. Disputes shall be settled by the courts of Helsinki, Finland.

---

## Signatures

**Controller:**
Name: ___________________________
Title: ___________________________
Date: ___________________________
Signature: ___________________________

**Processor (RecoveryAI):**
Name: ___________________________
Title: ___________________________
Date: ___________________________
Signature: ___________________________

---

> **Note**: This DPA template should be reviewed by a lawyer familiar with Finnish/EU GDPR before use. Standard DPA templates from GDPR compliance services (e.g., Iubenda, Termly) can be used as additional references.
