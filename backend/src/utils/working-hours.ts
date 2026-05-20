import { Contractor } from '../types';

/**
 * Returns true if the current time falls within the contractor's
 * configured working hours and working days.
 */
export function isWithinWorkingHours(contractor: Contractor): boolean {
  const now = new Date();

  // Convert current time to the contractor's timezone
  const formatter = new Intl.DateTimeFormat('en-US', {
    timeZone: contractor.timezone,
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
    weekday: 'short',
  });

  const parts = formatter.formatToParts(now);
  const hour = parseInt(parts.find((p) => p.type === 'hour')?.value || '0', 10);
  const minute = parseInt(parts.find((p) => p.type === 'minute')?.value || '0', 10);
  const weekdayStr = parts.find((p) => p.type === 'weekday')?.value || '';

  // Map weekday string to number (0=Sun..6=Sat)
  const weekdayMap: Record<string, number> = {
    Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6,
  };
  const currentDay = weekdayMap[weekdayStr] ?? -1;

  if (!contractor.working_days.includes(currentDay)) {
    return false;
  }

  const currentMinutes = hour * 60 + minute;

  const [startH, startM] = contractor.working_hours_start.split(':').map(Number);
  const [endH, endM] = contractor.working_hours_end.split(':').map(Number);
  const startMinutes = startH * 60 + startM;
  const endMinutes = endH * 60 + endM;

  return currentMinutes >= startMinutes && currentMinutes < endMinutes;
}
