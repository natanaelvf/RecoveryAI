/**
 * Lightweight i18n module
 * Loads locale JSON files and provides string interpolation.
 * Usage: t('leads.called_times', { count: 3 }) → "Called 3x"
 */

import en from './locales/en.json';
import fi from './locales/fi.json';

const locales = { en, fi };
let currentLocale = 'en';

/**
 * Set the active locale
 * @param {'en' | 'fi'} locale
 */
export function setLocale(locale) {
  if (locales[locale]) {
    currentLocale = locale;
    // Dispatch event so views can re-render if needed
    window.dispatchEvent(new CustomEvent('locale-changed', { detail: { locale } }));
  }
}

/**
 * Get the current locale
 * @returns {string}
 */
export function getLocale() {
  return currentLocale;
}

/**
 * Translate a key with optional variable interpolation
 * Falls back to English if the Finnish translation is empty
 * @param {string} key - dot-notation key like 'leads.title'
 * @param {Record<string, string|number>} [vars] - variables to interpolate
 * @returns {string}
 */
export function t(key, vars = {}) {
  // Try current locale first, fall back to English
  let str = locales[currentLocale]?.[key];

  // If empty string or missing, fall back to English
  if (!str && str !== 0) {
    str = locales.en?.[key];
  }

  // If still nothing, return the key itself (makes missing translations visible)
  if (!str && str !== 0) {
    return key;
  }

  // Interpolate {{variable}} patterns
  if (vars && typeof str === 'string') {
    str = str.replace(/\{\{(\w+)\}\}/g, (_, varName) => {
      return vars[varName] !== undefined ? String(vars[varName]) : `{{${varName}}}`;
    });
  }

  return str;
}
