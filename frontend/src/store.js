/**
 * Store — Reactive state management
 * Single abstraction point for data access.
 * In the next phase, swap mock imports for Supabase queries.
 */

import { contractor, leads, messages, generateRevenueData, getStats } from './data/mock.js';

// ── State ───────────────────────────────────────────────
const state = {
  contractor: { ...contractor },
  leads: [...leads],
  messages: { ...messages },
  revenueData: generateRevenueData(),
  filters: {
    status: 'all',
    search: '',
  },
  isAuthenticated: false,
};

// ── Subscribers ─────────────────────────────────────────
const subscribers = new Set();

export function subscribe(fn) {
  subscribers.add(fn);
  return () => subscribers.delete(fn);
}

function notify() {
  subscribers.forEach(fn => fn(state));
}

// ── Getters ─────────────────────────────────────────────
export function getState() {
  return state;
}

export function getContractor() {
  return state.contractor;
}

export function getLeads() {
  let filtered = [...state.leads];

  // Sort by created_at descending (newest first)
  filtered.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

  // Status filter
  if (state.filters.status !== 'all') {
    const statusMap = {
      missed: ['missed', 'consent_sent'],
      contacted: ['opted_in', 'qualifying', 'booking_sent', 'dnr_alert'],
      booked: ['booked'],
      completed: ['completed', 'followed_up'],
    };
    const statuses = statusMap[state.filters.status] || [state.filters.status];
    filtered = filtered.filter(l => statuses.includes(l.status));
  }

  // Search filter
  if (state.filters.search) {
    const q = state.filters.search.toLowerCase();
    filtered = filtered.filter(l =>
      (l.caller_name && l.caller_name.toLowerCase().includes(q)) ||
      l.caller_phone.replace(/\s/g, '').includes(q.replace(/\s/g, ''))
    );
  }

  return filtered;
}

export function getLead(id) {
  return state.leads.find(l => l.id === id) || null;
}

export function getMessages(leadId) {
  return state.messages[leadId] || [];
}

export function getRevenueData() {
  return state.revenueData;
}

export function getStatsData() {
  return getStats();
}

export function getLeadCounts() {
  const counts = { all: state.leads.length, missed: 0, contacted: 0, booked: 0, completed: 0 };
  state.leads.forEach(l => {
    if (['missed', 'consent_sent'].includes(l.status)) counts.missed++;
    else if (['opted_in', 'qualifying', 'booking_sent', 'dnr_alert'].includes(l.status)) counts.contacted++;
    else if (l.status === 'booked') counts.booked++;
    else if (['completed', 'followed_up'].includes(l.status)) counts.completed++;
  });
  return counts;
}

// ── Actions ─────────────────────────────────────────────
export function setFilter(key, value) {
  state.filters[key] = value;
  notify();
}

export function markLeadComplete(leadId) {
  const lead = state.leads.find(l => l.id === leadId);
  if (lead) {
    lead.status = 'completed';
    lead.updated_at = new Date().toISOString();
    notify();
  }
}

export function updateContractor(updates) {
  Object.assign(state.contractor, updates);
  notify();
}

export function login() {
  state.isAuthenticated = true;
  notify();
}

export function logout() {
  state.isAuthenticated = false;
  notify();
}

export function isAuthenticated() {
  return state.isAuthenticated;
}
