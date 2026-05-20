/**
 * Lead Detail View
 * Lead info + conversation thread
 */

import { t } from '../i18n.js';
import { getLead, getMessages, markLeadComplete } from '../store.js';
import { navigate } from '../router.js';
import { renderSidebar } from '../components/sidebar.js';
import { showToast } from '../components/toast.js';

/**
 * Format a date for display
 */
function formatDate(dateStr) {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  return d.toLocaleDateString('fi-FI', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

/**
 * Format time only
 */
function formatTime(dateStr) {
  const d = new Date(dateStr);
  return d.toLocaleTimeString('fi-FI', { hour: '2-digit', minute: '2-digit' });
}

/**
 * Render pipeline (same as leads view)
 */
function renderPipeline(status) {
  const stages = ['missed', 'contacted', 'booked', 'completed', 'followed_up'];
  const stageMap = {
    missed: 0, consent_sent: 0,
    opted_in: 1, qualifying: 1, booking_sent: 1, dnr_alert: 1,
    booked: 2, completed: 3, followed_up: 4, no_consent: -1,
  };
  const currentStage = stageMap[status] ?? -1;

  return `<div class="pipeline" style="margin: 0.75rem 0;">${stages.map((s, i) => {
    let cls = 'pipeline__step';
    if (i < currentStage) cls += ' pipeline__step--done';
    else if (i === currentStage) cls += ' pipeline__step--current';
    if (i === 0 && currentStage === 0) cls += ' pipeline__step--missed';
    const connector = i < stages.length - 1
      ? `<div class="pipeline__connector${i < currentStage ? ' pipeline__connector--done' : ''}"></div>`
      : '';
    return `<div class="${cls}"></div>${connector}`;
  }).join('')}</div>`;
}

/**
 * Render conversation thread
 */
function renderConversation(msgs) {
  if (!msgs || msgs.length === 0) {
    return `
      <div class="empty-state" style="padding: 2rem;">
        <div class="empty-state__icon">💬</div>
        <div class="empty-state__title">${t('lead_detail.no_messages')}</div>
      </div>
    `;
  }

  let html = '<div class="conversation" id="conversation-thread">';
  let lastDate = '';

  msgs.forEach(msg => {
    const msgDate = new Date(msg.sent_at).toLocaleDateString('fi-FI');
    if (msgDate !== lastDate) {
      html += `<div class="conversation__date-separator">${msgDate}</div>`;
      lastDate = msgDate;
    }

    const dirClass = msg.direction === 'outbound' ? 'conversation__bubble--outbound' : 'conversation__bubble--inbound';
    html += `
      <div class="conversation__bubble ${dirClass}">
        <div>${msg.body.replace(/\n/g, '<br>')}</div>
        <div class="conversation__meta">
          <span>${formatTime(msg.sent_at)}</span>
          ${msg.direction === 'outbound' ? '<span class="conversation__status">✓✓</span>' : ''}
        </div>
      </div>
    `;
  });

  html += '</div>';
  return html;
}

export function leadDetailView(params) {
  return {
    render() {
      renderSidebar();
      const lead = getLead(params.id);

      if (!lead) {
        return `
          <div class="content__inner">
            <a href="#/leads" class="back-link">← ${t('lead_detail.back')}</a>
            <div class="empty-state">
              <div class="empty-state__icon">❓</div>
              <div class="empty-state__title">Lead not found</div>
            </div>
          </div>
        `;
      }

      const msgs = getMessages(lead.id);
      const statusLabel = t(`status.${lead.status}`) || lead.status;
      const urgencyLabel = t(`urgency.${lead.urgency}`) || lead.urgency;
      const canComplete = ['booked', 'qualifying', 'booking_sent', 'dnr_alert'].includes(lead.status);

      return `
        <div class="content__inner">
          <a href="#/leads" class="back-link" id="back-to-leads">← ${t('lead_detail.back')}</a>

          <div class="content__header" style="margin-bottom: 1rem;">
            <h1 class="content__title">${lead.caller_name || lead.caller_phone}</h1>
            <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
              ${canComplete ? `<button class="btn btn--primary" id="btn-complete">✓ ${t('lead_detail.mark_complete')}</button>` : ''}
              <a href="tel:${lead.caller_phone.replace(/\s/g, '')}" class="btn btn--secondary">📞 ${t('lead_detail.call_lead')}</a>
            </div>
          </div>

          <div class="detail-layout">
            <!-- Left: Lead Info -->
            <div>
              <div class="card" style="margin-bottom: 1rem;">
                <h2 style="margin-bottom: 0.75rem;">Lead Info</h2>
                ${renderPipeline(lead.status)}
                <div style="margin-top: 0.5rem;">
                  <div class="info-row">
                    <span class="info-row__label">${t('lead_detail.phone')}</span>
                    <span class="info-row__value font-mono">${lead.caller_phone}</span>
                  </div>
                  <div class="info-row">
                    <span class="info-row__label">${t('lead_detail.status')}</span>
                    <span class="info-row__value"><span class="status-badge status-badge--${lead.status}"><span class="status-badge__dot"></span>${statusLabel}</span></span>
                  </div>
                  <div class="info-row">
                    <span class="info-row__label">${t('lead_detail.urgency')}</span>
                    <span class="info-row__value"><span class="urgency-badge urgency-badge--${lead.urgency}">${urgencyLabel}</span></span>
                  </div>
                  <div class="info-row">
                    <span class="info-row__label">${t('lead_detail.created')}</span>
                    <span class="info-row__value">${formatDate(lead.created_at)}</span>
                  </div>
                  ${lead.booking_time ? `
                    <div class="info-row">
                      <span class="info-row__label">${t('lead_detail.booking_time')}</span>
                      <span class="info-row__value">${formatDate(lead.booking_time)}</span>
                    </div>
                  ` : ''}
                  <div class="info-row">
                    <span class="info-row__label">${t('lead_detail.estimated_value')}</span>
                    <span class="info-row__value font-mono" style="color: var(--accent-success);">€${lead.estimated_value ? lead.estimated_value.toLocaleString('fi-FI') : '—'}</span>
                  </div>
                  <div class="info-row">
                    <span class="info-row__label">${t('lead_detail.call_count')}</span>
                    <span class="info-row__value">${lead.call_count}${lead.call_count > 1 ? ' 🔥' : ''}</span>
                  </div>
                  ${lead.satisfaction_score ? `
                    <div class="info-row">
                      <span class="info-row__label">${t('lead_detail.satisfaction')}</span>
                      <span class="info-row__value" style="color: var(--accent-primary);">${'★'.repeat(lead.satisfaction_score)}${'☆'.repeat(5 - lead.satisfaction_score)}</span>
                    </div>
                  ` : ''}
                  ${lead.called_during_after_hours ? `
                    <div class="info-row">
                      <span class="info-row__label">${t('lead_detail.after_hours')}</span>
                      <span class="info-row__value" style="color: var(--accent-danger);">Yes</span>
                    </div>
                  ` : ''}
                </div>
              </div>

              ${lead.issue_description ? `
                <div class="card">
                  <h2 style="margin-bottom: 0.5rem;">Issue</h2>
                  <p style="font-size: 0.875rem; color: var(--text-secondary); line-height: 1.5;">${lead.issue_description}</p>
                </div>
              ` : ''}

              ${lead.satisfaction_feedback ? `
                <div class="card" style="margin-top: 1rem;">
                  <h2 style="margin-bottom: 0.5rem;">Feedback</h2>
                  <p style="font-size: 0.875rem; color: var(--text-secondary); line-height: 1.5; font-style: italic;">"${lead.satisfaction_feedback}"</p>
                </div>
              ` : ''}
            </div>

            <!-- Right: Conversation -->
            <div class="card" style="padding: 0; overflow: hidden;">
              <div style="padding: 1rem 1.25rem; border-bottom: 1px solid var(--border-subtle);">
                <h2>${t('lead_detail.conversation')}</h2>
              </div>
              ${renderConversation(msgs)}
            </div>
          </div>
        </div>
      `;
    },

    mount() {
      // Mark complete button
      document.getElementById('btn-complete')?.addEventListener('click', () => {
        markLeadComplete(params.id);
        showToast('success', t('toast.lead_completed'));
        // Re-render
        const view = leadDetailView(params);
        const contentEl = document.getElementById('content');
        const result = view.render();
        contentEl.innerHTML = result;
        view.mount();
      });

      // Auto-scroll conversation to bottom
      const thread = document.getElementById('conversation-thread');
      if (thread) {
        thread.scrollTop = thread.scrollHeight;
      }
    },

    cleanup() {}
  };
}
