export type UserRole = 'Household' | 'Worker' | 'Admin';

export type LanguageCode = 'en' | 'ur';

export type ThemeMode = 'light' | 'dark';

export type RecurrenceCadence = 'one_time' | 'weekly' | 'biweekly' | 'monthly';

export interface AppUser {
  id: string;
  fullName: string;
  email: string;
  phone: string;
  role: UserRole;
  area?: string;
}

export interface EmergencyContact {
  name: string;
  relation: string;
  phone: string;
}

export interface SafetyCheckIn {
  id: string;
  timestamp: string;
  note: string;
}

export interface SafetyAlert {
  id: string;
  bookingId: string;
  householdName: string;
  workerName: string;
  address: string;
  emergencyContactName: string;
  emergencyContactPhone: string;
  triggeredAt: string;
  status: 'active' | 'acknowledged' | 'resolved';
  notes?: string;
}

export interface WorkerProfile {
  id: string;
  name: string;
  role: string;
  rating: number;
  rate: string;
  numericRate: number;
  experience: string;
  experienceYears: number;
  availability: string;
  availabilityStatus: string;
  availabilitySlots: string[];
  location: string;
  city: string;
  area: string;
  description: string;
  bio: string;
  highlight: string;
  verificationStatus: 'Verified' | 'PendingVerification' | 'RejectedVerification';
  profileVisibility: boolean;
  latitude: number;
  longitude: number;
  skillTags: string[];
  reviewsCount: number;
  cnic: string;
  phone: string;
  avatarUrl?: string;
  cnicDocPreview?: string;
  cnicDocName?: string;
  policeCertPreview?: string;
  policeCertName?: string;
  verificationSubmittedAt?: string;
}

export interface AIRecommendationResult {
  worker: WorkerProfile;
  compositeScore: number;
  matchPercentage: number;
  distanceKm: number;
  xaiBadge: string;
  matchReasons: string[];
  skillScore: number;
  geoScore: number;
  ratingScore: number;
}

export type BookingStatus =
  | 'Pending'
  | 'Accepted'
  | 'In Progress'
  | 'Completed'
  | 'Rejected'
  | 'Cancelled'
  | 'Disputed';

export interface Booking {
  id: string;
  householdId: string;
  householdName: string;
  workerId: string;
  workerName: string;
  serviceCategoryId: string;
  bookingDate: string; // YYYY-MM-DD
  startTime: string; // HH:MM
  endTime: string; // HH:MM
  address: string;
  notes: string;
  agreedAmount: number;
  baseAmount?: number;
  recurrence: RecurrenceCadence;
  recurringDays?: string[];
  discountPercent?: number;
  status: BookingStatus;
  paymentMethod: 'cash' | 'easypaisa' | 'jazzcash' | 'card' | 'p2p_transfer';
  paymentStatus: 'unpaid' | 'payment_sent' | 'confirmed' | 'refunded';
  createdAt: string;
  transactionId?: string;
  arrivalOtp: string;
  rated?: boolean;
  sessionStartedAt?: string;
  sessionEndedAt?: string;
  safetyCheckIns?: SafetyCheckIn[];
  emergencyContact?: EmergencyContact;
  sosTriggered?: boolean;
}

export interface JobPost {
  id: string;
  householdId: string;
  householdName: string;
  title: string;
  serviceCategory: string;
  description: string;
  city: string;
  area: string;
  latitude: number;
  longitude: number;
  budget: number;
  requiredDate: string; // YYYY-MM-DD
  status: 'open' | 'assigned' | 'completed' | 'cancelled';
  createdAt: string;
}

export interface JobApplication {
  id: string;
  jobPostId: string;
  workerId: string;
  workerName: string;
  workerRole: string;
  workerRating: number;
  proposedRate: number;
  notes: string;
  status: 'pending' | 'accepted' | 'rejected';
  appliedAt: string;
}

export interface ChatMessage {
  id: string;
  bookingId: string;
  senderId: string;
  senderName: string;
  senderRole: 'Household' | 'Worker';
  text: string;
  timestamp: string;
  isVoiceNote?: boolean;
}

export interface Dispute {
  id: string;
  bookingId: string;
  complainantId: string;
  complainantName: string;
  respondentId: string;
  respondentName: string;
  category: string;
  description: string;
  evidencePath?: string;
  status: 'open' | 'under_review' | 'resolved_refund' | 'resolved_payout' | 'dismissed';
  resolutionNotes?: string;
  createdAt: string;
  resolvedAt?: string;
}

export interface AuditLogEntry {
  id: string;
  timestamp: string;
  actionType: 'auth' | 'verification' | 'dispute' | 'payment' | 'safety' | 'system';
  title: string;
  description: string;
  actor: string;
  severity: 'info' | 'success' | 'warning' | 'danger';
}

export interface AppNotification {
  id: string;
  title: string;
  message: string;
  type: 'Booking' | 'Payment' | 'Dispute' | 'Verification' | 'Job' | 'Safety';
  isRead: boolean;
  createdAt: string;
}

export interface ReviewItem {
  id: string;
  bookingId: string;
  workerId: string;
  authorName: string;
  rating: number;
  punctuality: number;
  behavior: number;
  comment: string;
  createdAt: string;
}

export interface PersistedAppState {
  version: number;
  hasSeenOnboarding: boolean;
  theme: ThemeMode;
  lang: LanguageCode;
  currentUser: AppUser | null;
  savedEmergencyContact: EmergencyContact;
  workers: WorkerProfile[];
  bookings: Booking[];
  jobPosts: JobPost[];
  applications: JobApplication[];
  disputes: Dispute[];
  auditLogs: AuditLogEntry[];
  notifications: AppNotification[];
  reviews: ReviewItem[];
  messages: ChatMessage[];
  safetyAlerts: SafetyAlert[];
}
