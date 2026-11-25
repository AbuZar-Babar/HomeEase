import {
  DEFAULT_EMERGENCY_CONTACT,
  INITIAL_AUDIT_LOGS,
  INITIAL_BOOKINGS,
  INITIAL_DISPUTES,
  INITIAL_JOB_APPLICATIONS,
  INITIAL_JOB_POSTS,
  INITIAL_MESSAGES,
  INITIAL_NOTIFICATIONS,
  INITIAL_REVIEWS,
  INITIAL_SAFETY_ALERTS,
  INITIAL_WORKERS,
} from '../data/sampleData';
import { PersistedAppState } from '../types';

const STORAGE_KEY = 'homeease_abbottabad_state_v2';
const SCHEMA_VERSION = 2;

export function createDefaultState(): PersistedAppState {
  return {
    version: SCHEMA_VERSION,
    hasSeenOnboarding: false,
    theme: 'light',
    lang: 'en',
    currentUser: null,
    savedEmergencyContact: DEFAULT_EMERGENCY_CONTACT,
    workers: INITIAL_WORKERS,
    bookings: INITIAL_BOOKINGS,
    jobPosts: INITIAL_JOB_POSTS,
    applications: INITIAL_JOB_APPLICATIONS,
    disputes: INITIAL_DISPUTES,
    auditLogs: INITIAL_AUDIT_LOGS,
    notifications: INITIAL_NOTIFICATIONS,
    reviews: INITIAL_REVIEWS,
    messages: INITIAL_MESSAGES,
    safetyAlerts: INITIAL_SAFETY_ALERTS,
  };
}

export function loadPersistedState(): PersistedAppState {
  const defaults = createDefaultState();
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return defaults;
    const parsed = JSON.parse(raw) as Partial<PersistedAppState>;
    if (!parsed || parsed.version !== SCHEMA_VERSION) {
      return defaults;
    }

    // Re-attach fresh bundled portrait URLs in case build asset hashes changed
    const defaultPortraits = new Map(INITIAL_WORKERS.map((w) => [w.id, w.avatarUrl]));
    const hydratedWorkers = (parsed.workers ?? defaults.workers).map((w) => ({
      ...w,
      avatarUrl: w.avatarUrl && w.avatarUrl.startsWith('data:')
        ? w.avatarUrl
        : defaultPortraits.get(w.id) ?? w.avatarUrl,
    }));

    return {
      ...defaults,
      ...parsed,
      workers: hydratedWorkers,
      savedEmergencyContact: parsed.savedEmergencyContact ?? defaults.savedEmergencyContact,
      safetyAlerts: parsed.safetyAlerts ?? defaults.safetyAlerts,
    };
  } catch {
    return defaults;
  }
}

export function savePersistedState(state: PersistedAppState): void {
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch {
    // Ignore storage quota errors gracefully (e.g., very large uploaded images)
  }
}

export function clearPersistedState(): PersistedAppState {
  try {
    window.localStorage.removeItem(STORAGE_KEY);
  } catch {
    // ignore
  }
  return createDefaultState();
}
