/**
 * Login View
 */

import { t } from '../i18n.js';
import { login } from '../store.js';
import { navigate } from '../router.js';

export function loginView() {
  return {
    render() {
      // Hide sidebar on login
      const sidebar = document.getElementById('sidebar');
      if (sidebar) sidebar.style.display = 'none';
      const toggle = document.getElementById('sidebar-toggle');
      if (toggle) toggle.style.display = 'none';

      return `
        <div class="login">
          <div class="login__bg"></div>
          <div class="login__noise"></div>
          <div class="login__card fade-in">
            <div class="login__logo">
              <svg width="48" height="48" viewBox="0 0 32 32" fill="none">
                <rect width="32" height="32" rx="6" fill="var(--accent-primary-muted)"/>
                <path d="M16 8a8 8 0 1 0 0 16 8 8 0 0 0 0-16Z" stroke="var(--accent-primary)" stroke-width="2" fill="none"/>
                <path d="M13 15c0-.83.67-1.5 1.5-1.5h3c.83 0 1.5.67 1.5 1.5 0 .62-.38 1.15-.92 1.38L16.5 17v1" stroke="var(--accent-primary)" stroke-width="1.5" stroke-linecap="round"/>
                <circle cx="16.5" cy="20.5" r=".8" fill="var(--accent-primary)"/>
              </svg>
              <h1 class="login__logo-title">${t('login.title')}<span>${t('login.title_highlight')}</span></h1>
              <p class="login__logo-subtitle">${t('login.subtitle')}</p>
            </div>
            <form class="login__form" id="login-form">
              <div class="form-group">
                <label class="label" for="login-email">${t('login.email_label')}</label>
                <input class="input" type="email" id="login-email" placeholder="${t('login.email_placeholder')}" value="jukka@virtanenlvi.fi" autocomplete="email" />
              </div>
              <div class="form-group">
                <label class="label" for="login-password">${t('login.password_label')}</label>
                <input class="input" type="password" id="login-password" placeholder="${t('login.password_placeholder')}" value="••••••••" autocomplete="current-password" />
              </div>
              <button type="submit" class="btn btn--primary btn--lg login__submit" id="login-submit">${t('login.submit')}</button>
              <p style="text-align: center; margin-top: 0.5rem;">
                <a href="#" style="font-size: 0.8125rem; color: var(--text-tertiary); transition: color 150ms;" onmouseover="this.style.color='var(--accent-primary)'" onmouseout="this.style.color='var(--text-tertiary)'">${t('login.forgot')}</a>
              </p>
            </form>
          </div>
        </div>
      `;
    },

    mount() {
      const form = document.getElementById('login-form');
      form?.addEventListener('submit', (e) => {
        e.preventDefault();
        const btn = document.getElementById('login-submit');
        btn.textContent = '...';
        btn.disabled = true;

        // Simulate brief auth delay
        setTimeout(() => {
          login();
          // Show sidebar
          const sidebar = document.getElementById('sidebar');
          if (sidebar) sidebar.style.display = '';
          const toggle = document.getElementById('sidebar-toggle');
          if (toggle) toggle.style.display = '';
          navigate('/dashboard');
        }, 600);
      });
    },

    cleanup() {
      // Restore sidebar visibility
      const sidebar = document.getElementById('sidebar');
      if (sidebar) sidebar.style.display = '';
    }
  };
}
