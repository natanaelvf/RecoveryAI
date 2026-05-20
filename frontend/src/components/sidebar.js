/**
 * Sidebar Component
 * Navigation with route highlighting, user info, collapse toggle, and mobile toggle
 */

import { t } from '../i18n.js';
import { getContractor, getLeadCounts, logout } from '../store.js';
import { navigate } from '../router.js';

// SVG icons (inline for zero dependencies)
const icons = {
  dashboard: `<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="7" height="7" rx="1.5"/><rect x="11" y="2" width="7" height="4" rx="1.5"/><rect x="2" y="11" width="7" height="4" rx="1.5"/><rect x="11" y="8" width="7" height="7" rx="1.5"/></svg>`,
  leads: `<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M15 2H5a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2Z"/><path d="M7 7h6M7 10h6M7 13h3"/></svg>`,
  settings: `<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="10" cy="10" r="3"/><path d="M10 2v2M10 16v2M3.5 6.5l1.4 1.4M15.1 15.1l1.4 1.4M2 10h2M16 10h2M3.5 13.5l1.4-1.4M15.1 4.9l1.4-1.4"/></svg>`,
  logout: `<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M7 17H4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h3M13 14l4-4-4-4M17 10H7"/></svg>`,
  menu: `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 7h16M4 12h16M4 17h16"/></svg>`,
  close: `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M18 6 6 18M6 6l12 12"/></svg>`,
  logo: `<svg width="32" height="32" viewBox="0 0 32 32" fill="none"><rect width="32" height="32" rx="6" fill="var(--accent-primary-muted)"/><path d="M16 8a8 8 0 1 0 0 16 8 8 0 0 0 0-16Z" stroke="var(--accent-primary)" stroke-width="2" fill="none"/><path d="M13 15c0-.83.67-1.5 1.5-1.5h3c.83 0 1.5.67 1.5 1.5 0 .62-.38 1.15-.92 1.38L16.5 17v1" stroke="var(--accent-primary)" stroke-width="1.5" stroke-linecap="round"/><circle cx="16.5" cy="20.5" r=".8" fill="var(--accent-primary)"/></svg>`,
  collapse: `<svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4L6 9l5 5"/></svg>`,
};

// Track sidebar collapsed state
let isCollapsed = false;

export function renderSidebar() {
  const sidebar = document.getElementById('sidebar');
  if (!sidebar) return;

  const c = getContractor();
  const counts = getLeadCounts();
  const missedCount = counts.missed;
  const initials = c.contact_name.split(' ').map(n => n[0]).join('').toUpperCase();

  sidebar.innerHTML = `
    <div class="sidebar__logo">
      <div class="sidebar__logo-icon">${icons.logo}</div>
      <div class="sidebar__logo-text">${t('app.name')}<span>${t('app.name_highlight')}</span></div>
      <button class="sidebar__collapse-btn" id="sidebar-collapse" aria-label="Collapse sidebar" title="Collapse sidebar">
        ${icons.collapse}
      </button>
    </div>

    <nav class="sidebar__nav">
      <a href="#/dashboard" data-route="/dashboard" class="sidebar__link" id="nav-dashboard">
        <span class="sidebar__link-icon">${icons.dashboard}</span>
        <span class="sidebar__link-label">${t('nav.dashboard')}</span>
      </a>
      <a href="#/leads" data-route="/leads" class="sidebar__link" id="nav-leads">
        <span class="sidebar__link-icon">${icons.leads}</span>
        <span class="sidebar__link-label">${t('nav.leads')}</span>
        ${missedCount > 0 ? `<span class="sidebar__link-badge">${missedCount}</span>` : ''}
      </a>
      <a href="#/settings" data-route="/settings" class="sidebar__link" id="nav-settings">
        <span class="sidebar__link-icon">${icons.settings}</span>
        <span class="sidebar__link-label">${t('nav.settings')}</span>
      </a>
    </nav>

    <div class="sidebar__footer">
      <button class="sidebar__user" id="sidebar-logout" title="Sign out">
        <div class="sidebar__avatar">${initials}</div>
        <div class="sidebar__user-info">
          <div class="sidebar__user-name">${c.contact_name}</div>
          <div class="sidebar__user-tier">${c.tier} plan</div>
        </div>
      </button>
    </div>
  `;

  // Restore collapsed state
  if (isCollapsed) {
    sidebar.classList.add('sidebar--collapsed');
  }

  // Collapse toggle handler
  document.getElementById('sidebar-collapse')?.addEventListener('click', (e) => {
    e.preventDefault();
    e.stopPropagation();
    isCollapsed = !isCollapsed;
    sidebar.classList.toggle('sidebar--collapsed', isCollapsed);
  });

  // Logout handler
  document.getElementById('sidebar-logout')?.addEventListener('click', () => {
    logout();
    navigate('/login');
  });

  // Navigation link handlers — use event delegation on nav
  const nav = sidebar.querySelector('.sidebar__nav');
  if (nav) {
    nav.addEventListener('click', (e) => {
      const link = e.target.closest('.sidebar__link');
      if (!link) return;

      e.preventDefault();
      const route = link.getAttribute('data-route');
      if (route) {
        navigate(route);
      }

      // Mobile: close sidebar on link click
      sidebar.classList.remove('sidebar--open');
      document.querySelector('.sidebar__overlay')?.remove();
    });
  }
}

export function initMobileToggle() {
  // Create toggle button if not exists
  if (!document.getElementById('sidebar-toggle')) {
    const toggle = document.createElement('button');
    toggle.id = 'sidebar-toggle';
    toggle.className = 'sidebar__toggle';
    toggle.innerHTML = icons.menu;
    toggle.setAttribute('aria-label', 'Toggle navigation');
    document.body.appendChild(toggle);

    toggle.addEventListener('click', () => {
      const sidebar = document.getElementById('sidebar');
      const isOpen = sidebar.classList.toggle('sidebar--open');

      toggle.innerHTML = isOpen ? icons.close : icons.menu;

      // Overlay
      let overlay = document.querySelector('.sidebar__overlay');
      if (isOpen && !overlay) {
        overlay = document.createElement('div');
        overlay.className = 'sidebar__overlay';
        overlay.addEventListener('click', () => {
          sidebar.classList.remove('sidebar--open');
          toggle.innerHTML = icons.menu;
          overlay.remove();
        });
        document.body.appendChild(overlay);
      } else if (!isOpen && overlay) {
        overlay.remove();
      }
    });
  }
}
