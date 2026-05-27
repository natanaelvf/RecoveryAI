/**
 * Privacy Policy — Public page (no auth required)
 * Rendered as a clean, readable page without the dashboard sidebar.
 */

export function privacyView() {
  return {
    render() {
      return `
        <div class="content__inner" style="max-width: 720px; margin: 0 auto; padding: 32px 20px;">
          <header style="margin-bottom: 32px;">
            <h1 style="font-size: 1.8rem; font-weight: 700; margin-bottom: 8px;">Privacy Policy</h1>
            <p style="opacity: 0.6; font-size: 0.85rem;">Unmissed — Missed-Lead Recovery Service</p>
            <p style="opacity: 0.5; font-size: 0.8rem;">Last updated: May 2026</p>
          </header>

          <section style="margin-bottom: 24px;">
            <h2 style="font-size: 1.2rem; font-weight: 600; margin-bottom: 12px;">1. What Data We Collect</h2>
            <p style="margin-bottom: 12px;">When you call a business that uses Unmissed and they miss your call, we may collect the following data through an SMS conversation — <strong>only if you give explicit consent</strong>:</p>
            <table style="width: 100%; border-collapse: collapse; margin-bottom: 12px; font-size: 0.9rem;">
              <tr style="border-bottom: 1px solid var(--clr-border, #e0e0e0);">
                <td style="padding: 8px 12px; font-weight: 600;">Phone number</td>
                <td style="padding: 8px 12px;">Identifying you and communicating via SMS</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--clr-border, #e0e0e0);">
                <td style="padding: 8px 12px; font-weight: 600;">Name</td>
                <td style="padding: 8px 12px;">Addressing you properly</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--clr-border, #e0e0e0);">
                <td style="padding: 8px 12px; font-weight: 600;">Issue description</td>
                <td style="padding: 8px 12px;">Understanding your service need</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--clr-border, #e0e0e0);">
                <td style="padding: 8px 12px; font-weight: 600;">Urgency level</td>
                <td style="padding: 8px 12px;">Prioritizing your request</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--clr-border, #e0e0e0);">
                <td style="padding: 8px 12px; font-weight: 600;">Booking time</td>
                <td style="padding: 8px 12px;">Scheduling a callback</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--clr-border, #e0e0e0);">
                <td style="padding: 8px 12px; font-weight: 600;">Satisfaction score</td>
                <td style="padding: 8px 12px;">Improving service quality</td>
              </tr>
              <tr>
                <td style="padding: 8px 12px; font-weight: 600;">Conversation log</td>
                <td style="padding: 8px 12px;">Record of all SMS exchanges</td>
              </tr>
            </table>
            <p>We do <strong>not</strong> collect payment information, location data, or email address.</p>
          </section>

          <section style="margin-bottom: 24px;">
            <h2 style="font-size: 1.2rem; font-weight: 600; margin-bottom: 12px;">2. Legal Basis</h2>
            <p style="margin-bottom: 12px;">We process your data based on <strong>explicit consent</strong> (GDPR Article 6(1)(a)). You must reply <strong>YES</strong> (or <strong>KYLLÄ</strong>) to opt in. Reply <strong>STOP</strong> (or <strong>EI</strong>) at any time to withdraw consent.</p>
            <p>You can also withdraw consent by emailing <a href="mailto:privacy@unmissed.io" style="color: var(--clr-primary, #6366f1);">privacy@unmissed.io</a></p>
          </section>

          <section style="margin-bottom: 24px;">
            <h2 style="font-size: 1.2rem; font-weight: 600; margin-bottom: 12px;">3. How We Use Your Data</h2>
            <p style="margin-bottom: 8px;">Your data is used solely for connecting you with the contractor:</p>
            <ul style="padding-left: 20px; margin-bottom: 12px; line-height: 1.8;">
              <li>SMS qualification and callback scheduling</li>
              <li>Appointment booking via Calendly</li>
              <li>One satisfaction survey (24h after job completion)</li>
            </ul>
            <p>Your data is <strong>never</strong> sold, used for marketing, or shared with other contractors.</p>
          </section>

          <section style="margin-bottom: 24px;">
            <h2 style="font-size: 1.2rem; font-weight: 600; margin-bottom: 12px;">4. Data Retention</h2>
            <p>Data is retained for <strong>12 months</strong> after the last interaction, then automatically anonymized. You can request immediate deletion at any time.</p>
          </section>

          <section style="margin-bottom: 24px;">
            <h2 style="font-size: 1.2rem; font-weight: 600; margin-bottom: 12px;">5. Data Storage</h2>
            <p style="margin-bottom: 12px;">All data is stored in the <strong>EU (Frankfurt, Germany)</strong> and encrypted in transit and at rest.</p>
            <table style="width: 100%; border-collapse: collapse; font-size: 0.9rem;">
              <tr style="border-bottom: 1px solid var(--clr-border, #e0e0e0);">
                <td style="padding: 8px 12px; font-weight: 600;">Database</td>
                <td style="padding: 8px 12px;">Supabase (Frankfurt, EU)</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--clr-border, #e0e0e0);">
                <td style="padding: 8px 12px; font-weight: 600;">Backend</td>
                <td style="padding: 8px 12px;">Fly.io (Frankfurt, EU)</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--clr-border, #e0e0e0);">
                <td style="padding: 8px 12px; font-weight: 600;">SMS</td>
                <td style="padding: 8px 12px;">Twilio (EU routing)</td>
              </tr>
              <tr>
                <td style="padding: 8px 12px; font-weight: 600;">Notifications</td>
                <td style="padding: 8px 12px;">Firebase (Google, EU-US DPF)</td>
              </tr>
            </table>
          </section>

          <section style="margin-bottom: 24px;">
            <h2 style="font-size: 1.2rem; font-weight: 600; margin-bottom: 12px;">6. Your Rights (GDPR)</h2>
            <p style="margin-bottom: 8px;">You have the right to:</p>
            <ul style="padding-left: 20px; line-height: 1.8;">
              <li><strong>Access</strong> — request a copy of your data</li>
              <li><strong>Rectification</strong> — correct inaccurate data</li>
              <li><strong>Erasure</strong> — request deletion ("right to be forgotten")</li>
              <li><strong>Restriction</strong> — limit processing</li>
              <li><strong>Portability</strong> — receive data in machine-readable format</li>
              <li><strong>Object</strong> — object to processing</li>
            </ul>
            <p style="margin-top: 12px;">Contact: <a href="mailto:privacy@unmissed.io" style="color: var(--clr-primary, #6366f1);">privacy@unmissed.io</a> (response within 30 days)</p>
            <p style="margin-top: 8px; font-size: 0.85rem; opacity: 0.7;">Complaints: <a href="https://tietosuoja.fi" target="_blank" style="color: var(--clr-primary, #6366f1);">Finnish Data Protection Ombudsman</a></p>
          </section>

          <footer style="margin-top: 40px; padding-top: 20px; border-top: 1px solid var(--clr-border, #e0e0e0); font-size: 0.8rem; opacity: 0.6;">
            <p>Unmissed — <a href="mailto:privacy@unmissed.io">privacy@unmissed.io</a></p>
          </footer>
        </div>
      `;
    },
  };
}
