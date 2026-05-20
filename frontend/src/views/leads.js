/**
 * Leads View
 * Lead list with search, status filters, and cards
 */

import { t } from '../i18n.js';
import { getLeads, getLeadCounts, setFilter, getState } from '../store.js';
import { navigate } from '../router.js';
import { renderSidebar } from '../components/sidebar.js';

/**
 * Format relative time
 */
function timeAgo(dateStr) {
  const now = new Date();
  const date = new Date(dateStr);
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);
  const diffWeeks = Math.floor(diffDays / 7);

  if (diffMins < 1) return t('time.just_now');
  if (diffMins < 60) return t('time.minutes_ago', { count: diffMins });
  if (diffHours < 24) return t('time.hours_ago', { count: diffHours });
  if (diffDays < 7) return t('time.days_ago', { count: diffDays });
  return t('time.weeks_ago', { count: diffWeeks });
}

/**
 * Get status display text
 */
function statusText(status) {
  return t(`status.${status}`) || status;
}

/**
 * Get urgency display text
 */
function urgencyText(urgency) {
  return t(`urgency.${urgency}`) || urgency;
}

/**
 * Render pipeline dots
 */
function renderPipeline(status) {
  const stages = ['missed', 'contacted', 'booked', 'completed', 'followed_up'];
  const stageMap = {
    missed: 0, consent_sent: 0,
    opted_in: 1, qualifying: 1, booking_sent: 1, dnr_alert: 1,
    booked: 2,
    completed: 3,
    followed_up: 4,
    no_consent: -1,
  };

  const currentStage = stageMap[status] ?? -1;

  return `<div class="pipeline">${stages.map((s, i) => {
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
 * Render a single lead card
 */
function renderLeadCard(lead) {
  // Determine left border class
  let borderClass = '';
  if (['missed', 'consent_sent', 'dnr_alert'].includes(lead.status)) borderClass = 'lead-card--missed';
  else if (['opted_in', 'qualifying', 'booking_sent'].includes(lead.status)) borderClass = 'lead-card--active';
  else if (lead.status === 'booked') borderClass = 'lead-card--booked';

  // Emergency breathing animation
  const emergencyClass = lead.urgency === 'emergency' ? 'urgency--emergency' : '';

  return `
    <div class="card card--interactive lead-card ${borderClass} ${emergencyClass}" data-lead-id="${lead.id}" role="button" tabindex="0" aria-label="View lead ${lead.caller_name || lead.caller_phone}">
      <div class="lead-card__header">
        <span class="lead-card__phone">${lead.caller_phone}</span>
        <span class="lead-card__time">${timeAgo(lead.created_at)}</span>
      </div>
      ${lead.caller_name ? `<div class="lead-card__name">${lead.caller_name}</div>` : ''}
      ${lead.issue_description ? `<div class="lead-card__issue">"${lead.issue_description}"</div>` : '<div class="lead-card__issue" style="color: var(--text-tertiary); font-style: italic;">Waiting for response...</div>'}
      <div class="lead-card__footer">
        <span class="urgency-badge urgency-badge--${lead.urgency}">${urgencyText(lead.urgency)}</span>
        <span class="status-badge status-badge--${lead.status}"><span class="status-badge__dot"></span>${statusText(lead.status)}</span>
        ${lead.call_count > 1 ? `<span class="lead-card__call-count">📞 ${t('leads.called_times', { count: lead.call_count })}</span>` : ''}
      </div>
      <div style="margin-top: 0.75rem;">
        ${renderPipeline(lead.status)}
      </div>
    </div>
  `;
}

export function leadsView() {
  let searchTimeout;

  return {
    render() {
      renderSidebar();
      const leads = getLeads();
      const counts = getLeadCounts();
      const { filters } = getState();

      const filterButtons = [
        { key: 'all', label: t('leads.filter.all'), count: counts.all },
        { key: 'missed', label: t('leads.filter.missed'), count: counts.missed },
        { key: 'contacted', label: t('leads.filter.contacted'), count: counts.contacted },
        { key: 'booked', label: t('leads.filter.booked'), count: counts.booked },
        { key: 'completed', label: t('leads.filter.completed'), count: counts.completed },
      ];

      return `
        <div class="content__inner">
          <div class="content__header">
            <h1 class="content__title">${t('leads.title')}</h1>
          </div>

          <div class="search-bar" style="margin-bottom: 1.25rem;">
            <div class="search-bar__input-wrapper">
              <span class="search-bar__icon">🔍</span>
              <input class="input search-bar__input" type="search" id="leads-search" placeholder="${t('leads.search_placeholder')}" value="${filters.search}" />
            </div>
            <div class="search-bar__filters" id="filter-pills">
              ${filterButtons.map(f => `
                <button class="filter-pill${filters.status === f.key ? ' filter-pill--active' : ''}" data-filter="${f.key}">
                  ${f.label} <span style="opacity: 0.6; margin-left: 2px;">${f.count}</span>
                </button>
              `).join('')}
            </div>
          </div>

          <div class="leads-grid" id="leads-grid">
            ${leads.length > 0
              ? leads.map(renderLeadCard).join('')
              : `<div class="empty-state" style="grid-column: 1 / -1;">
                  <div class="empty-state__icon">📋</div>
                  <div class="empty-state__title">${filters.search || filters.status !== 'all' ? t('leads.no_results') : t('leads.empty_title')}</div>
                  <div class="empty-state__desc">${t('leads.empty_desc')}</div>
                </div>`
            }
          </div>
        </div>
      `;
    },

    mount() {
      // Search handler
      const searchInput = document.getElementById('leads-search');
      searchInput?.addEventListener('input', (e) => {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(() => {
          setFilter('search', e.target.value);
          this._reRenderGrid();
        }, 200);
      });

      // Filter pill handlers
      document.getElementById('filter-pills')?.addEventListener('click', (e) => {
        const pill = e.target.closest('.filter-pill');
        if (!pill) return;

        const filter = pill.dataset.filter;
        setFilter('status', filter);

        // Update active state
        document.querySelectorAll('.filter-pill').forEach(p => p.classList.remove('filter-pill--active'));
        pill.classList.add('filter-pill--active');

        this._reRenderGrid();
      });

      // Card click handlers
      this._attachCardListeners();
    },

    _reRenderGrid() {
      const grid = document.getElementById('leads-grid');
      if (!grid) return;

      const leads = getLeads();
      const { filters } = getState();

      grid.innerHTML = leads.length > 0
        ? leads.map(renderLeadCard).join('')
        : `<div class="empty-state" style="grid-column: 1 / -1;">
            <div class="empty-state__icon">📋</div>
            <div class="empty-state__title">${filters.search || filters.status !== 'all' ? t('leads.no_results') : t('leads.empty_title')}</div>
            <div class="empty-state__desc">${t('leads.empty_desc')}</div>
          </div>`;

      this._attachCardListeners();
    },

    _attachCardListeners() {
      document.querySelectorAll('.lead-card[data-lead-id]').forEach(card => {
        const handler = () => navigate(`/leads/${card.dataset.leadId}`);
        card.addEventListener('click', handler);
        card.addEventListener('keydown', (e) => { if (e.key === 'Enter') handler(); });
      });
    },

    cleanup() {
      clearTimeout(searchTimeout);
    }
  };
}
