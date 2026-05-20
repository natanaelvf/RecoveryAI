/**
 * Dashboard View
 * Revenue stats, chart, and recent wins
 */

import { t } from '../i18n.js';
import { getStatsData, getRevenueData, getLeads } from '../store.js';
import { renderSidebar } from '../components/sidebar.js';

/**
 * Animate a number counting up from 0
 */
function animateValue(el, target, prefix = '', suffix = '', duration = 1200) {
  const start = 0;
  const startTime = performance.now();

  function update(now) {
    const elapsed = now - startTime;
    const progress = Math.min(elapsed / duration, 1);
    // Ease out cubic
    const eased = 1 - Math.pow(1 - progress, 3);
    const current = Math.round(start + (target - start) * eased);
    el.textContent = prefix + current.toLocaleString('fi-FI') + suffix;
    if (progress < 1) requestAnimationFrame(update);
  }

  requestAnimationFrame(update);
}

/**
 * Draw revenue chart on canvas
 */
function drawChart(canvas, data) {
  const ctx = canvas.getContext('2d');
  const dpr = window.devicePixelRatio || 1;

  // Set canvas size
  const rect = canvas.parentElement.getBoundingClientRect();
  canvas.width = rect.width * dpr;
  canvas.height = 220 * dpr;
  canvas.style.height = '220px';
  ctx.scale(dpr, dpr);

  const width = rect.width;
  const height = 220;
  const padding = { top: 20, right: 16, bottom: 30, left: 16 };
  const chartW = width - padding.left - padding.right;
  const chartH = height - padding.top - padding.bottom;

  // Clear
  ctx.clearRect(0, 0, width, height);

  // Max value
  const maxRevenue = Math.max(...data.map(d => d.revenue), 100);

  // Bar dimensions
  const barCount = data.length;
  const barGap = 3;
  const barWidth = Math.max((chartW - barGap * barCount) / barCount, 4);

  // Draw bars with animation
  data.forEach((d, i) => {
    const barH = (d.revenue / maxRevenue) * chartH;
    const x = padding.left + i * (barWidth + barGap);
    const y = padding.top + chartH - barH;

    // Bar
    const gradient = ctx.createLinearGradient(x, y, x, y + barH);
    if (d.recovered > 0) {
      gradient.addColorStop(0, '#F59E0B');
      gradient.addColorStop(1, 'rgba(245, 158, 11, 0.4)');
    } else {
      gradient.addColorStop(0, 'rgba(30, 45, 61, 0.8)');
      gradient.addColorStop(1, 'rgba(30, 45, 61, 0.3)');
    }

    ctx.beginPath();
    ctx.roundRect(x, y, barWidth, barH, [3, 3, 0, 0]);
    ctx.fillStyle = gradient;
    ctx.fill();

    // X-axis label (every 5th day)
    if (i % 5 === 0 || i === barCount - 1) {
      ctx.fillStyle = '#556677';
      ctx.font = '10px "Barlow Condensed", sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText(d.label, x + barWidth / 2, height - 6);
    }
  });
}

export function dashboardView() {
  return {
    render() {
      renderSidebar();
      const stats = getStatsData();
      const leads = getLeads();
      const recentWins = leads
        .filter(l => ['completed', 'followed_up'].includes(l.status))
        .slice(0, 5);

      return `
        <div class="content__inner">
          <div class="content__header">
            <h1 class="content__title">${t('dashboard.title')}</h1>
          </div>

          <div class="stats-grid">
            <div class="card stat-card stat-card--animate" id="stat-revenue">
              <div class="stat-card__header">
                <span class="stat-card__label">${t('dashboard.recovered_revenue')}</span>
                <div class="stat-card__icon stat-card__icon--teal">💰</div>
              </div>
              <div class="stat-card__value" data-target="${stats.recoveredRevenue}" data-prefix="€" id="revenue-value">€0</div>
              <div class="stat-card__trend stat-card__trend--up">↑ 23% ${t('dashboard.trend_up')}</div>
            </div>

            <div class="card stat-card stat-card--animate" id="stat-leads">
              <div class="stat-card__header">
                <span class="stat-card__label">${t('dashboard.leads_recovered')}</span>
                <div class="stat-card__icon stat-card__icon--amber">📞</div>
              </div>
              <div class="stat-card__value" data-target="${stats.leadsRecovered}" id="leads-value">0</div>
              <div class="stat-card__trend stat-card__trend--up">↑ 12% ${t('dashboard.trend_up')}</div>
            </div>

            <div class="card stat-card stat-card--animate" id="stat-rate">
              <div class="stat-card__header">
                <span class="stat-card__label">${t('dashboard.recovery_rate')}</span>
                <div class="stat-card__icon stat-card__icon--blue">📈</div>
              </div>
              <div class="stat-card__value" data-target="${stats.recoveryRate}" data-suffix="%" id="rate-value">0%</div>
              <div class="stat-card__trend stat-card__trend--up">↑ 5% ${t('dashboard.trend_up')}</div>
            </div>

            <div class="card stat-card stat-card--animate" id="stat-response">
              <div class="stat-card__header">
                <span class="stat-card__label">${t('dashboard.avg_response_time')}</span>
                <div class="stat-card__icon stat-card__icon--coral">⚡</div>
              </div>
              <div class="stat-card__value">${stats.avgResponseTime}</div>
              <div class="stat-card__trend stat-card__trend--up">↓ 3min ${t('dashboard.trend_up')}</div>
            </div>
          </div>

          <div class="card" style="padding: 1.25rem; margin-bottom: 1.5rem;">
            <h2 style="margin-bottom: 1rem;">${t('dashboard.revenue_chart_title')}</h2>
            <div class="chart-container" id="chart-container">
              <canvas id="revenue-chart"></canvas>
            </div>
          </div>

          <div class="card" style="padding: 0;">
            <div style="padding: 1rem 1.25rem; border-bottom: 1px solid var(--border-subtle);">
              <h2>${t('dashboard.recent_wins')}</h2>
            </div>
            ${recentWins.length > 0 ? `
              <div class="wins-list">
                ${recentWins.map(lead => `
                  <div class="wins-list__item">
                    <span class="wins-list__name">${lead.caller_name || lead.caller_phone}</span>
                    <span class="wins-list__value">€${(lead.estimated_value || 350).toLocaleString('fi-FI')}</span>
                    <span class="wins-list__stars">${lead.satisfaction_score ? '★'.repeat(lead.satisfaction_score) + '☆'.repeat(5 - lead.satisfaction_score) : '—'}</span>
                  </div>
                `).join('')}
              </div>
            ` : `
              <div class="empty-state" style="padding: 2rem;">
                <div class="empty-state__icon">🏆</div>
                <div class="empty-state__title">${t('dashboard.no_wins_yet')}</div>
              </div>
            `}
          </div>
        </div>
      `;
    },

    mount() {
      // Animate stat values
      const revenueEl = document.getElementById('revenue-value');
      const leadsEl = document.getElementById('leads-value');
      const rateEl = document.getElementById('rate-value');

      if (revenueEl) {
        const target = parseInt(revenueEl.dataset.target) || 0;
        animateValue(revenueEl, target, '€', '', 1500);
      }
      if (leadsEl) {
        const target = parseInt(leadsEl.dataset.target) || 0;
        animateValue(leadsEl, target, '', '', 1000);
      }
      if (rateEl) {
        const target = parseInt(rateEl.dataset.target) || 0;
        animateValue(rateEl, target, '', '%', 1200);
      }

      // Draw chart
      const canvas = document.getElementById('revenue-chart');
      if (canvas) {
        const data = getRevenueData();
        // Delay slightly so container has dimensions
        requestAnimationFrame(() => drawChart(canvas, data));

        // Redraw on resize
        this._resizeHandler = () => drawChart(canvas, data);
        window.addEventListener('resize', this._resizeHandler);
      }
    },

    cleanup() {
      if (this._resizeHandler) {
        window.removeEventListener('resize', this._resizeHandler);
      }
    }
  };
}
