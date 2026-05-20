/**
 * Toast Notification System
 */

let toastCounter = 0;

/**
 * Show a toast notification
 * @param {'success' | 'error' | 'warning' | 'info'} type
 * @param {string} title
 * @param {string} [message]
 * @param {number} [duration=4000] - ms before auto-dismiss
 */
export function showToast(type, title, message = '', duration = 4000) {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const id = `toast-${++toastCounter}`;
  const icons = {
    success: '✓',
    error: '✕',
    warning: '⚠',
    info: 'ℹ',
  };

  const toast = document.createElement('div');
  toast.id = id;
  toast.className = `toast toast--${type}`;
  toast.innerHTML = `
    <span class="toast__icon">${icons[type] || 'ℹ'}</span>
    <div class="toast__content">
      <div class="toast__title">${title}</div>
      ${message ? `<div class="toast__message">${message}</div>` : ''}
    </div>
    <button class="toast__close" aria-label="Dismiss">✕</button>
  `;

  container.appendChild(toast);

  // Close button
  toast.querySelector('.toast__close').addEventListener('click', () => dismissToast(toast));

  // Auto-dismiss
  if (duration > 0) {
    setTimeout(() => dismissToast(toast), duration);
  }
}

function dismissToast(toast) {
  if (!toast || !toast.parentNode) return;
  toast.classList.add('toast--exiting');
  setTimeout(() => toast.remove(), 250);
}
