/**
 * Settings View
 * Contractor profile, working hours, recovery settings, account
 */

import { t } from '../i18n.js';
import { getContractor, updateContractor } from '../store.js';
import { renderSidebar } from '../components/sidebar.js';
import { showToast } from '../components/toast.js';

export function settingsView() {
  return {
    render() {
      renderSidebar();
      const c = getContractor();
      const smsPercent = Math.round((c.sms_used_this_month / c.monthly_sms_cap) * 100);
      const smsWarning = smsPercent > 80;

      const tradeOptions = ['plumber', 'hvac', 'electrician', 'roofer', 'other'];
      const dayLabels = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

      return `
        <div class="content__inner">
          <div class="content__header">
            <h1 class="content__title">${t('settings.title')}</h1>
            <button class="btn btn--primary" id="settings-save">${t('settings.save')}</button>
          </div>

          <form id="settings-form">
            <!-- Business Info -->
            <div class="settings-section">
              <h2 class="settings-section__title">${t('settings.business_info')}</h2>
              <div class="form-row">
                <div class="form-group">
                  <label class="label" for="s-business-name">${t('settings.business_name')}</label>
                  <input class="input" id="s-business-name" value="${c.business_name}" />
                </div>
                <div class="form-group">
                  <label class="label" for="s-contact-name">${t('settings.contact_name')}</label>
                  <input class="input" id="s-contact-name" value="${c.contact_name}" />
                </div>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label class="label" for="s-contact-email">${t('settings.contact_email')}</label>
                  <input class="input" type="email" id="s-contact-email" value="${c.contact_email}" />
                </div>
                <div class="form-group">
                  <label class="label" for="s-contact-phone">${t('settings.contact_phone')}</label>
                  <input class="input" id="s-contact-phone" value="${c.contact_phone}" />
                </div>
              </div>
              <div class="form-group">
                <label class="label" for="s-trade-type">${t('settings.trade_type')}</label>
                <select class="input" id="s-trade-type">
                  ${tradeOptions.map(opt => `<option value="${opt}" ${c.trade_type === opt ? 'selected' : ''}>${opt.charAt(0).toUpperCase() + opt.slice(1)}</option>`).join('')}
                </select>
              </div>
            </div>

            <!-- Working Hours -->
            <div class="settings-section">
              <h2 class="settings-section__title">${t('settings.working_hours')}</h2>
              <div class="form-group">
                <label class="label">${t('settings.working_days')}</label>
                <div class="day-toggles" id="day-toggles">
                  ${dayLabels.map((day, i) => {
                    const dayNum = i + 1;
                    const isActive = c.working_days.includes(dayNum);
                    return `<button type="button" class="day-toggle${isActive ? ' day-toggle--active' : ''}" data-day="${dayNum}">${t(`days.${day}`)}</button>`;
                  }).join('')}
                </div>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label class="label" for="s-start-time">${t('settings.start_time')}</label>
                  <input class="input" type="time" id="s-start-time" value="${c.working_hours_start}" />
                </div>
                <div class="form-group">
                  <label class="label" for="s-end-time">${t('settings.end_time')}</label>
                  <input class="input" type="time" id="s-end-time" value="${c.working_hours_end}" />
                </div>
              </div>
            </div>

            <!-- Recovery Settings -->
            <div class="settings-section">
              <h2 class="settings-section__title">${t('settings.recovery')}</h2>
              <div class="form-row">
                <div class="form-group">
                  <label class="label" for="s-urgent-threshold">${t('settings.urgent_threshold')}</label>
                  <input class="input" type="number" id="s-urgent-threshold" value="${c.urgency_threshold_urgent_min}" min="15" max="480" />
                </div>
                <div class="form-group">
                  <label class="label" for="s-normal-threshold">${t('settings.normal_threshold')}</label>
                  <input class="input" type="number" id="s-normal-threshold" value="${c.urgency_threshold_normal_min}" min="60" max="4320" />
                </div>
              </div>
              <div class="form-row">
                <div class="form-group">
                  <label class="label" for="s-default-value">${t('settings.default_job_value')}</label>
                  <input class="input" type="number" id="s-default-value" value="${c.default_job_value}" min="0" step="10" />
                </div>
                <div class="form-group">
                  <label class="label" for="s-calendly">${t('settings.calendly_url')}</label>
                  <input class="input" type="url" id="s-calendly" value="${c.calendly_url || ''}" placeholder="https://calendly.com/..." />
                </div>
              </div>
            </div>

            <!-- Account -->
            <div class="settings-section">
              <h2 class="settings-section__title">${t('settings.account')}</h2>
              <div class="form-group">
                <label class="label">${t('settings.tier')}</label>
                <div style="display: flex; align-items: center; gap: 0.75rem;">
                  <span class="status-badge status-badge--booked" style="font-size: 0.8rem; padding: 0.375rem 0.875rem;">${c.tier.toUpperCase()}</span>
                  <span style="font-size: 0.8125rem; color: var(--text-tertiary);">€${c.tier === 'starter' ? '149' : c.tier === 'growth' ? '249' : '399'}/mo</span>
                </div>
              </div>
              <div class="form-group">
                <label class="label">${t('settings.sms_usage')}</label>
                <div style="font-size: 0.875rem; color: var(--text-secondary);">
                  ${t('settings.sms_used_of', { used: c.sms_used_this_month, cap: c.monthly_sms_cap })}
                </div>
                <div class="usage-bar">
                  <div class="usage-bar__fill${smsWarning ? ' usage-bar__fill--warning' : ''}" style="width: ${smsPercent}%;"></div>
                </div>
              </div>
            </div>
          </form>
        </div>
      `;
    },

    mount() {
      // Day toggle handlers
      document.getElementById('day-toggles')?.addEventListener('click', (e) => {
        const btn = e.target.closest('.day-toggle');
        if (!btn) return;
        btn.classList.toggle('day-toggle--active');
      });

      // Save handler
      document.getElementById('settings-save')?.addEventListener('click', () => {
        const activeDays = [];
        document.querySelectorAll('.day-toggle--active').forEach(btn => {
          activeDays.push(parseInt(btn.dataset.day));
        });

        updateContractor({
          business_name: document.getElementById('s-business-name')?.value,
          contact_name: document.getElementById('s-contact-name')?.value,
          contact_email: document.getElementById('s-contact-email')?.value,
          contact_phone: document.getElementById('s-contact-phone')?.value,
          trade_type: document.getElementById('s-trade-type')?.value,
          working_hours_start: document.getElementById('s-start-time')?.value,
          working_hours_end: document.getElementById('s-end-time')?.value,
          working_days: activeDays.sort(),
          urgency_threshold_urgent_min: parseInt(document.getElementById('s-urgent-threshold')?.value) || 60,
          urgency_threshold_normal_min: parseInt(document.getElementById('s-normal-threshold')?.value) || 1440,
          default_job_value: parseInt(document.getElementById('s-default-value')?.value) || 350,
          calendly_url: document.getElementById('s-calendly')?.value,
        });

        showToast('success', t('toast.settings_saved'));
      });
    },

    cleanup() {}
  };
}
