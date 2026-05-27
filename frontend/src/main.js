/**
 * Unmissed — Contractor Dashboard
 * Main entry point
 */

import './styles/index.css';
import './styles/layout.css';
import './styles/animations.css';
import './styles/components.css';

import { route, startRouter, navigate, getCurrentPath } from './router.js';
import { renderSidebar, initMobileToggle } from './components/sidebar.js';
import { isAuthenticated } from './store.js';

// Views
import { loginView } from './views/login.js';
import { dashboardView } from './views/dashboard.js';
import { leadsView } from './views/leads.js';
import { leadDetailView } from './views/lead-detail.js';
import { settingsView } from './views/settings.js';
import { privacyView } from './views/privacy.js';

// ── Register routes ─────────────────────────────────────

// Public routes (no auth required)
route('/login', () => loginView());
route('/privacy', () => privacyView());

route('/dashboard', () => {
  if (!isAuthenticated()) { navigate('/login'); return loginView(); }
  return dashboardView();
});

route('/leads', () => {
  if (!isAuthenticated()) { navigate('/login'); return loginView(); }
  return leadsView();
});

route('/leads/:id', (params) => {
  if (!isAuthenticated()) { navigate('/login'); return loginView(); }
  return leadDetailView(params);
});

route('/settings', () => {
  if (!isAuthenticated()) { navigate('/login'); return loginView(); }
  return settingsView();
});

// ── Bootstrap ───────────────────────────────────────────

// Initial sidebar render (will be hidden on login, shown after auth)
renderSidebar();
initMobileToggle();

// Start router
startRouter();

// If no hash, redirect to login
if (!window.location.hash || window.location.hash === '#') {
  navigate('/login');
}
