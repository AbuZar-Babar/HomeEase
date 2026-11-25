import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  AlertTriangle,
  Bell,
  Briefcase,
  CalendarDays,
  ChevronDown,
  Compass,
  Globe,
  Home,
  LayoutDashboard,
  LogOut,
  Moon,
  PlusCircle,
  RotateCcw,
  Scale,
  ScrollText,
  Shield,
  ShieldCheck,
  Sun,
  TrendingUp,
  UserCog,
  X,
} from 'lucide-react';
import { AdminDashboard, AdminTabId } from './components/AdminDashboard';
import { AuthScreen } from './components/AuthScreen';
import { BookingsAndAgreementViews } from './components/BookingAndAgreementViews';
import { OnboardingScreen, SplashScreen } from './components/EntryExperience';
import { HouseholdDiscoverView, HouseholdPostJobView } from './components/HouseholdViews';
import { WorkerAvatar } from './components/WorkerAvatar';
import {
  WorkerAvailabilityView,
  WorkerDashboardView,
  WorkerJobsFeedView,
  WorkerProfileBuilderView,
} from './components/WorkerViews';
import { DEMO_ACCOUNTS, generateDeterministicOtp } from './data/sampleData';
import { tr } from './services/localization';
import {
  clearPersistedState,
  loadPersistedState,
  savePersistedState,
} from './services/storage';
import {
  AppUser,
  Booking,
  EmergencyContact,
  JobApplication,
  JobPost,
  PersistedAppState,
  SafetyAlert,
  UserRole,
  WorkerProfile,
} from './types';

type ActiveTab =
  | 'discover'
  | 'post_job'
  | 'bookings'
  | 'worker_dashboard'
  | 'worker_gigs'
  | 'worker_availability'
  | 'worker_profile'
  | 'admin';

function defaultTabForRole(role: UserRole): ActiveTab {
  if (role === 'Worker') return 'worker_dashboard';
  if (role === 'Admin') return 'admin';
  return 'discover';
}

export default function App() {
  const [state, setState] = useState<PersistedAppState>(() => loadPersistedState());
  const [showSplash, setShowSplash] = useState(true);
  const [activeTab, setActiveTab] = useState<ActiveTab>(() =>
    state.currentUser ? defaultTabForRole(state.currentUser.role) : 'discover'
  );
  const [adminTab, setAdminTab] = useState<AdminTabId>('overview');
  const [quotaExceeded, setQuotaExceeded] = useState(false);
  const [quotaBannerDismissed, setQuotaBannerDismissed] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const [showNotifMenu, setShowNotifMenu] = useState(false);
  const [showAccountMenu, setShowAccountMenu] = useState(false);

  const accountMenuRef = useRef<HTMLDivElement | null>(null);
  const notifMenuRef = useRef<HTMLDivElement | null>(null);

  // Persist state to localStorage on every update
  useEffect(() => {
    savePersistedState(state);
  }, [state]);

  // Sync theme class & RTL direction on <html>
  useEffect(() => {
    const root = document.documentElement;
    root.classList.toggle('dark', state.theme === 'dark');
    root.dir = state.lang === 'ur' ? 'rtl' : 'ltr';
    root.lang = state.lang;
  }, [state.theme, state.lang]);

  // Listen for mandatory Google Maps Platform quota exceeded events
  useEffect(() => {
    const onQuotaExceeded = () => {
      setQuotaExceeded(true);
      setQuotaBannerDismissed(false);
    };
    window.addEventListener('gmp-quota-exceeded', onQuotaExceeded);
    return () => window.removeEventListener('gmp-quota-exceeded', onQuotaExceeded);
  }, []);

  // Close popovers on outside click
  useEffect(() => {
    const onDocClick = (e: MouseEvent) => {
      const target = e.target as Node;
      if (accountMenuRef.current && !accountMenuRef.current.contains(target)) {
        setShowAccountMenu(false);
      }
      if (notifMenuRef.current && !notifMenuRef.current.contains(target)) {
        setShowNotifMenu(false);
      }
    };
    document.addEventListener('mousedown', onDocClick);
    return () => document.removeEventListener('mousedown', onDocClick);
  }, []);

  const showToast = (msg: string) => {
    setToast(msg);
    window.setTimeout(() => {
      setToast((prev) => (prev === msg ? null : prev));
    }, 3400);
  };

  const toggleLang = () =>
    setState((prev) => ({ ...prev, lang: prev.lang === 'en' ? 'ur' : 'en' }));

  const toggleTheme = () =>
    setState((prev) => ({ ...prev, theme: prev.theme === 'dark' ? 'light' : 'dark' }));

  const handleLogin = (user: AppUser) => {
    setState((prev) => ({
      ...prev,
      currentUser: user,
      hasSeenOnboarding: true,
    }));
    setActiveTab(defaultTabForRole(user.role));
  };

  const handleSwitchRole = (role: UserRole) => {
    const acc = DEMO_ACCOUNTS[role];
    setState((prev) => ({
      ...prev,
      currentUser: {
        id: acc.id,
        fullName: acc.fullName,
        email: acc.email,
        phone: acc.phone,
        role: acc.role,
        area: acc.area,
      },
    }));
    setActiveTab(defaultTabForRole(role));
    setShowAccountMenu(false);
  };

  const handleResetDemoData = () => {
    const fresh = clearPersistedState();
    const preservedUser = state.currentUser;
    const preservedTheme = state.theme;
    const preservedLang = state.lang;
    setState({
      ...fresh,
      hasSeenOnboarding: true,
      theme: preservedTheme,
      lang: preservedLang,
      currentUser: preservedUser,
    });
    setShowAccountMenu(false);
    showToast(tr(state.lang, 'resetDemoConfirm'));
  };

  const handleReplayOnboarding = () => {
    setShowAccountMenu(false);
    setState((prev) => ({
      ...prev,
      hasSeenOnboarding: false,
      currentUser: null,
    }));
  };

  const handleSignOut = () => {
    setShowAccountMenu(false);
    setState((prev) => ({ ...prev, currentUser: null }));
  };

  // Domain mutations
  const handleCreateBooking = (payload: Omit<Booking, 'id' | 'createdAt' | 'arrivalOtp'>) => {
    const id = `bkg_${Math.floor(300 + Math.random() * 699)}`;
    const newBooking: Booking = {
      ...payload,
      id,
      createdAt: new Date().toISOString(),
      arrivalOtp: generateDeterministicOtp(id),
      emergencyContact: state.savedEmergencyContact,
    };

    setState((prev) => ({
      ...prev,
      bookings: [newBooking, ...prev.bookings],
      notifications: [
        {
          id: `notif_${Date.now()}`,
          title: 'Booking Requested',
          message: `Request sent to ${newBooking.workerName} for ${newBooking.bookingDate}.`,
          type: 'Booking',
          isRead: false,
          createdAt: new Date().toISOString(),
        },
        ...prev.notifications,
      ],
    }));

    setActiveTab('bookings');
    showToast(
      state.lang === 'ur'
        ? `${newBooking.workerName} کے ساتھ بکنگ کی درخواست بھیج دی گئی۔`
        : `Booking request sent to ${newBooking.workerName}.`
    );
  };

  const handleCreateJobPost = (job: Omit<JobPost, 'id' | 'createdAt' | 'status'>) => {
    const newJob: JobPost = {
      ...job,
      id: `job_${Date.now()}`,
      status: 'open',
      createdAt: new Date().toISOString(),
    };
    setState((prev) => ({
      ...prev,
      jobPosts: [newJob, ...prev.jobPosts],
    }));
    showToast(
      state.lang === 'ur'
        ? 'گھریلو کام کامیابی سے شائع ہو گیا۔'
        : `Published "${newJob.title}" to Abbottabad specialists.`
    );
  };

  const handleAcceptProposal = (app: JobApplication, job: JobPost) => {
    const bookingId = `bkg_${Math.floor(300 + Math.random() * 699)}`;
    const newBooking: Booking = {
      id: bookingId,
      householdId: job.householdId,
      householdName: job.householdName,
      workerId: app.workerId,
      workerName: app.workerName,
      serviceCategoryId: job.serviceCategory,
      bookingDate: job.requiredDate,
      startTime: '10:00',
      endTime: '13:00',
      address: `${job.area}, Abbottabad`,
      notes: `${job.title} — ${app.notes}`,
      agreedAmount: app.proposedRate,
      baseAmount: app.proposedRate,
      recurrence: 'one_time',
      discountPercent: 0,
      status: 'Accepted',
      paymentMethod: 'easypaisa',
      paymentStatus: 'unpaid',
      createdAt: new Date().toISOString(),
      arrivalOtp: generateDeterministicOtp(bookingId),
      emergencyContact: state.savedEmergencyContact,
    };

    setState((prev) => ({
      ...prev,
      jobPosts: prev.jobPosts.map((j) => (j.id === job.id ? { ...j, status: 'assigned' } : j)),
      applications: prev.applications.map((a) =>
        a.jobPostId === job.id
          ? { ...a, status: a.id === app.id ? 'accepted' : 'rejected' }
          : a
      ),
      bookings: [newBooking, ...prev.bookings],
    }));

    setActiveTab('bookings');
    showToast(`Accepted ${app.workerName}'s proposal. Agreement #${bookingId} created.`);
  };

  const handleUpdateBookingStatus = (bookingId: string, status: Booking['status']) => {
    setState((prev) => ({
      ...prev,
      bookings: prev.bookings.map((b) =>
        b.id === bookingId
          ? {
              ...b,
              status,
              sessionEndedAt: status === 'Completed' ? new Date().toISOString() : b.sessionEndedAt,
            }
          : b
      ),
    }));
    showToast(`Booking #${bookingId} marked ${status}.`);
  };

  const handleVerifyArrivalOtp = (bookingId: string) => {
    const now = new Date().toISOString();
    setState((prev) => ({
      ...prev,
      bookings: prev.bookings.map((b) =>
        b.id === bookingId
          ? {
              ...b,
              status: 'In Progress',
              sessionStartedAt: now,
              safetyCheckIns: [
                ...(b.safetyCheckIns ?? []),
                {
                  id: `chk_${Date.now()}`,
                  timestamp: now,
                  note: 'Arrival OTP verified — live job timer started',
                },
              ],
            }
          : b
      ),
    }));
    showToast(
      state.lang === 'ur'
        ? 'آمد کی تصدیق ہو گئی — لائیو سیشن ٹائمر شروع ہو گیا۔'
        : 'Arrival OTP verified — live session timer started.'
    );
  };

  const handleSafetyCheckIn = (bookingId: string, note: string) => {
    const now = new Date().toISOString();
    setState((prev) => ({
      ...prev,
      bookings: prev.bookings.map((b) =>
        b.id === bookingId
          ? {
              ...b,
              safetyCheckIns: [
                ...(b.safetyCheckIns ?? []),
                { id: `chk_${Date.now()}`, timestamp: now, note },
              ],
            }
          : b
      ),
    }));
    showToast(
      state.lang === 'ur' ? 'محفوظ چیک ان ریکارڈ ہو گیا۔' : 'Safety check-in recorded.'
    );
  };

  const handleSaveEmergencyContact = (contact: EmergencyContact, bookingId?: string) => {
    setState((prev) => ({
      ...prev,
      savedEmergencyContact: contact,
      bookings: bookingId
        ? prev.bookings.map((b) =>
            b.id === bookingId ? { ...b, emergencyContact: contact } : b
          )
        : prev.bookings,
    }));
    showToast(
      state.lang === 'ur' ? 'ہنگامی رابطہ محفوظ کر لیا گیا۔' : 'Emergency contact saved.'
    );
  };

  const handleTriggerSafetyAlert = (booking: Booking, contact: EmergencyContact) => {
    const now = new Date().toISOString();
    const alertId = `SOS-${Math.floor(100 + Math.random() * 899)}`;
    const newAlert: SafetyAlert = {
      id: alertId,
      bookingId: booking.id,
      householdName: booking.householdName,
      workerName: booking.workerName,
      address: booking.address,
      emergencyContactName: contact.name,
      emergencyContactPhone: contact.phone,
      triggeredAt: now,
      status: 'active',
    };

    setState((prev) => ({
      ...prev,
      bookings: prev.bookings.map((b) =>
        b.id === booking.id ? { ...b, sosTriggered: true } : b
      ),
      safetyAlerts: [newAlert, ...prev.safetyAlerts],
      auditLogs: [
        {
          id: `LOG-${Date.now()}`,
          timestamp: now,
          actionType: 'safety',
          title: `Urgent Safety Alert (${alertId})`,
          description: `Household ${booking.householdName} triggered a safety alert during active session #${booking.id} at ${booking.address}. Emergency contact: ${contact.name} (${contact.phone}).`,
          actor: booking.householdName,
          severity: 'danger',
        },
        ...prev.auditLogs,
      ],
      notifications: [
        {
          id: `notif_${Date.now()}`,
          title: 'Emergency Safety Alert Sent',
          message: `Alert ${alertId} dispatched to HomeEase Abbottabad Governance Desk.`,
          type: 'Safety',
          isRead: false,
          createdAt: now,
        },
        ...prev.notifications,
      ],
    }));

    showToast(tr(state.lang, 'safetyAlertSent'));
  };

  const handleSettlePayment = (bookingId: string, method: Booking['paymentMethod']) => {
    const txId = `HE-${method.slice(0, 2).toUpperCase()}-${Math.floor(100000 + Math.random() * 899999)}`;
    const target = state.bookings.find((b) => b.id === bookingId);
    setState((prev) => ({
      ...prev,
      bookings: prev.bookings.map((b) =>
        b.id === bookingId
          ? { ...b, paymentMethod: method, paymentStatus: 'confirmed', transactionId: txId }
          : b
      ),
      auditLogs: [
        {
          id: `LOG-${Date.now()}`,
          timestamp: new Date().toISOString(),
          actionType: 'payment',
          title: 'Escrow Payment Confirmed',
          description: `PKR ${target?.agreedAmount.toLocaleString() ?? ''} settled via ${method} (${txId}) for #${bookingId}.`,
          actor: state.currentUser?.fullName ?? 'Household',
          severity: 'success',
        },
        ...prev.auditLogs,
      ],
    }));
    showToast(`Escrow settled (${txId}).`);
  };

  const handleSubmitReview = (payload: {
    bookingId: string;
    workerId: string;
    rating: number;
    punctuality: number;
    behavior: number;
    comment: string;
  }) => {
    const authorName = state.currentUser?.fullName ?? 'Household';
    setState((prev) => ({
      ...prev,
      bookings: prev.bookings.map((b) =>
        b.id === payload.bookingId ? { ...b, rated: true } : b
      ),
      reviews: [
        {
          id: `rev_${Date.now()}`,
          bookingId: payload.bookingId,
          workerId: payload.workerId,
          authorName,
          rating: payload.rating,
          punctuality: payload.punctuality,
          behavior: payload.behavior,
          comment: payload.comment,
          createdAt: new Date().toISOString(),
        },
        ...prev.reviews,
      ],
      workers: prev.workers.map((w) => {
        if (w.id !== payload.workerId) return w;
        const newCount = w.reviewsCount + 1;
        const newRating = Number(((w.rating * w.reviewsCount + payload.rating) / newCount).toFixed(1));
        return { ...w, reviewsCount: newCount, rating: newRating };
      }),
    }));
    showToast(state.lang === 'ur' ? 'آپ کی رائے محفوظ کر لی گئی۔' : 'Thank you — review published.');
  };

  const handleFileDispute = (payload: {
    booking: Booking;
    category: string;
    description: string;
  }) => {
    const dispId = `DISP-${Math.floor(302 + Math.random() * 690)}`;
    const now = new Date().toISOString();
    setState((prev) => ({
      ...prev,
      bookings: prev.bookings.map((b) =>
        b.id === payload.booking.id ? { ...b, status: 'Disputed' } : b
      ),
      disputes: [
        {
          id: dispId,
          bookingId: payload.booking.id,
          complainantId: state.currentUser?.id ?? payload.booking.householdId,
          complainantName: state.currentUser?.fullName ?? payload.booking.householdName,
          respondentId: payload.booking.workerId,
          respondentName: payload.booking.workerName,
          category: payload.category,
          description: payload.description,
          status: 'open',
          createdAt: now,
        },
        ...prev.disputes,
      ],
      auditLogs: [
        {
          id: `LOG-${Date.now()}`,
          timestamp: now,
          actionType: 'dispute',
          title: `Dispute Opened (${dispId})`,
          description: `${payload.category} filed for booking #${payload.booking.id}.`,
          actor: state.currentUser?.fullName ?? 'User',
          severity: 'warning',
        },
        ...prev.auditLogs,
      ],
    }));
    showToast(`Dispute ${dispId} submitted for arbitration.`);
  };

  const handleSendMessage = (bookingId: string, text: string) => {
    if (!state.currentUser) return;
    const role: 'Household' | 'Worker' =
      state.currentUser.role === 'Worker' ? 'Worker' : 'Household';
    setState((prev) => ({
      ...prev,
      messages: [
        ...prev.messages,
        {
          id: `msg_${Date.now()}`,
          bookingId,
          senderId: state.currentUser!.id,
          senderName: state.currentUser!.fullName,
          senderRole: role,
          text,
          timestamp: new Date().toISOString(),
        },
      ],
    }));
  };

  const handleApplyForJob = (job: JobPost, proposedRate: number, notes: string) => {
    const activeWorker = currentWorkerProfile;
    if (!activeWorker) return;
    setState((prev) => ({
      ...prev,
      applications: [
        {
          id: `app_${Date.now()}`,
          jobPostId: job.id,
          workerId: activeWorker.id,
          workerName: activeWorker.name,
          workerRole: activeWorker.role,
          workerRating: activeWorker.rating,
          proposedRate,
          notes,
          status: 'pending',
          appliedAt: new Date().toISOString(),
        },
        ...prev.applications,
      ],
    }));
    showToast(`Proposal sent for "${job.title}".`);
  };

  const handleUpdateWorkerAvailability = (slots: string[], visible: boolean) => {
    const activeWorker = currentWorkerProfile;
    if (!activeWorker) return;
    setState((prev) => ({
      ...prev,
      workers: prev.workers.map((w) =>
        w.id === activeWorker.id
          ? {
              ...w,
              availabilitySlots: slots,
              availability: slots.length === 7 ? 'Mon - Sun' : slots.join(', '),
              profileVisibility: visible,
            }
          : w
      ),
    }));
    showToast('Availability updated.');
  };

  const handleSaveWorkerProfile = (
    patch: Partial<WorkerProfile>,
    submitForVerification: boolean
  ) => {
    const activeWorker = currentWorkerProfile;
    if (!activeWorker) return;
    const now = new Date().toISOString();

    setState((prev) => ({
      ...prev,
      workers: prev.workers.map((w) =>
        w.id === activeWorker.id
          ? {
              ...w,
              ...patch,
              verificationStatus: submitForVerification
                ? 'PendingVerification'
                : w.verificationStatus,
              highlight: submitForVerification ? 'Pending Verification' : w.highlight,
              verificationSubmittedAt: submitForVerification ? now : w.verificationSubmittedAt,
            }
          : w
      ),
      auditLogs: submitForVerification
        ? [
            {
              id: `LOG-${Date.now()}`,
              timestamp: now,
              actionType: 'verification',
              title: 'Worker Verification Documents Submitted',
              description: `${patch.name || activeWorker.name} uploaded verification credentials for Admin review.`,
              actor: patch.name || activeWorker.name,
              severity: 'info',
            },
            ...prev.auditLogs,
          ]
        : prev.auditLogs,
    }));
  };

  const handleApproveWorker = (workerId: string) => {
    const target = state.workers.find((w) => w.id === workerId);
    setState((prev) => ({
      ...prev,
      workers: prev.workers.map((w) =>
        w.id === workerId
          ? { ...w, verificationStatus: 'Verified', highlight: 'Verified' }
          : w
      ),
      auditLogs: [
        {
          id: `LOG-${Date.now()}`,
          timestamp: new Date().toISOString(),
          actionType: 'verification',
          title: 'Worker Verification Approved',
          description: `${target?.name ?? workerId} verified by Abbottabad Governance Desk.`,
          actor: state.currentUser?.email ?? 'Admin',
          severity: 'success',
        },
        ...prev.auditLogs,
      ],
    }));
    showToast(`${target?.name ?? 'Worker'} verified.`);
  };

  const handleRejectWorker = (workerId: string) => {
    const target = state.workers.find((w) => w.id === workerId);
    setState((prev) => ({
      ...prev,
      workers: prev.workers.map((w) =>
        w.id === workerId
          ? { ...w, verificationStatus: 'RejectedVerification', highlight: 'Rejected' }
          : w
      ),
      auditLogs: [
        {
          id: `LOG-${Date.now()}`,
          timestamp: new Date().toISOString(),
          actionType: 'verification',
          title: 'Worker Verification Rejected',
          description: `${target?.name ?? workerId} marked Rejected during credential review.`,
          actor: state.currentUser?.email ?? 'Admin',
          severity: 'warning',
        },
        ...prev.auditLogs,
      ],
    }));
    showToast(`${target?.name ?? 'Worker'} verification rejected.`);
  };

  const handleResolveDispute = (
    disputeId: string,
    resolution: 'resolved_refund' | 'resolved_payout' | 'dismissed'
  ) => {
    const now = new Date().toISOString();
    setState((prev) => ({
      ...prev,
      disputes: prev.disputes.map((d) =>
        d.id === disputeId ? { ...d, status: resolution, resolvedAt: now } : d
      ),
      auditLogs: [
        {
          id: `LOG-${Date.now()}`,
          timestamp: now,
          actionType: 'dispute',
          title: `Dispute ${disputeId} Resolved`,
          description: `Arbitration ruling: ${resolution.replace('_', ' ')}.`,
          actor: state.currentUser?.email ?? 'Admin',
          severity: 'success',
        },
        ...prev.auditLogs,
      ],
    }));
    showToast(`Dispute ${disputeId} resolved.`);
  };

  const handleUpdateSafetyAlert = (alertId: string, status: SafetyAlert['status']) => {
    setState((prev) => ({
      ...prev,
      safetyAlerts: prev.safetyAlerts.map((a) =>
        a.id === alertId ? { ...a, status } : a
      ),
      auditLogs: [
        {
          id: `LOG-${Date.now()}`,
          timestamp: new Date().toISOString(),
          actionType: 'safety',
          title: `Safety Alert ${alertId} ${status}`,
          description: `Governance desk marked alert ${alertId} as ${status}.`,
          actor: state.currentUser?.email ?? 'Admin',
          severity: status === 'resolved' ? 'success' : 'warning',
        },
        ...prev.auditLogs,
      ],
    }));
  };

  const currentWorkerProfile = useMemo(() => {
    if (!state.currentUser) return state.workers[0];
    return (
      state.workers.find((w) => w.id === state.currentUser?.id) ?? state.workers[0]
    );
  }, [state.workers, state.currentUser]);

  const unreadCount = useMemo(
    () => state.notifications.filter((n) => !n.isRead).length,
    [state.notifications]
  );

  // Entry Sequence: Splash -> First-time Onboarding -> Auth
  if (showSplash) {
    return <SplashScreen lang={state.lang} onComplete={() => setShowSplash(false)} />;
  }

  if (!state.hasSeenOnboarding) {
    return (
      <OnboardingScreen
        lang={state.lang}
        theme={state.theme}
        onToggleLang={toggleLang}
        onToggleTheme={toggleTheme}
        onFinish={() => setState((prev) => ({ ...prev, hasSeenOnboarding: true }))}
      />
    );
  }

  if (!state.currentUser) {
    return (
      <AuthScreen
        lang={state.lang}
        theme={state.theme}
        onToggleLang={toggleLang}
        onToggleTheme={toggleTheme}
        onReplayOnboarding={handleReplayOnboarding}
        onLogin={handleLogin}
      />
    );
  }

  const navItems: { id: ActiveTab; label: string }[] =
    state.currentUser.role === 'Household'
      ? [
          { id: 'discover', label: tr(state.lang, 'exploreWorkers') },
          { id: 'post_job', label: tr(state.lang, 'postAJob') },
          { id: 'bookings', label: tr(state.lang, 'myBookings') },
        ]
      : state.currentUser.role === 'Worker'
      ? [
          { id: 'worker_dashboard', label: tr(state.lang, 'workerDashboard') },
          { id: 'worker_gigs', label: tr(state.lang, 'browseJobs') },
          { id: 'worker_availability', label: tr(state.lang, 'availability') },
          { id: 'worker_profile', label: tr(state.lang, 'profileBuilder') },
        ]
      : [{ id: 'admin', label: tr(state.lang, 'adminDashboard') }];

  return (
    <div className="min-h-screen bg-[#FAFBF9] dark:bg-[#0B1011] text-[#0F172A] dark:text-[#F1F5F9] flex flex-col">
      {/* Mandatory Non-Intrusive Google Maps Platform Quota Exceeded Banner */}
      {quotaExceeded && !quotaBannerDismissed && (
        <div
          role="alert"
          className="sticky top-0 z-50 w-full bg-amber-50 dark:bg-amber-950/90 border-b border-amber-300 dark:border-amber-800 px-4 py-2.5 text-xs text-amber-950 dark:text-amber-100"
        >
          <div className="max-w-7xl mx-auto flex items-center justify-between gap-3">
            <div className="flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 shrink-0 text-amber-600 dark:text-amber-400" />
              <span>
                The Google Maps API key used by this app has exceeded its request quota. To resolve
                this, add your own API key from a Google Cloud project with billing enabled.{' '}
                <a
                  href="https://developers.google.com/maps/ai/ai-studio?utm_campaign=gmp_mcp_codeassist_v1_aistudio#quota_exceeded_errors"
                  target="_blank"
                  rel="noreferrer"
                  className="font-semibold underline"
                >
                  Learn more
                </a>
              </span>
            </div>
            <button
              type="button"
              onClick={() => setQuotaBannerDismissed(true)}
              aria-label="Dismiss notice"
              className="p-1 rounded hover:bg-amber-200/50 dark:hover:bg-amber-900/60"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      )}

      {/* Three-Zone Editorial Top Bar (compact 56px on phones, 64px on desktop) */}
      <header className="sticky top-0 z-40 pt-safe bg-[#FAFBF9]/95 dark:bg-[#0B1011]/95 backdrop-blur-md border-b border-slate-200 dark:border-slate-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 h-14 md:h-16 flex items-center justify-between gap-4">
          {/* Zone 1: Clean single-line Wordmark */}
          <button
            type="button"
            onClick={() => setActiveTab(defaultTabForRole(state.currentUser!.role))}
            className="flex items-center gap-2 shrink-0 min-h-[44px]"
          >
            <div className="w-8 h-8 rounded-lg bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E] flex items-center justify-center">
              <Home className="w-4 h-4" strokeWidth={2.2} />
            </div>
            <span className="font-display text-lg md:text-xl font-semibold tracking-tight text-slate-900 dark:text-white whitespace-nowrap">
              {tr(state.lang, 'appTitle')}
            </span>
          </button>

          {/* Zone 2: Clean Single-Line Nav Links */}
          <nav className="hidden md:flex items-center gap-6">
            {navItems.map((item) => {
              const active = activeTab === item.id;
              return (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => setActiveTab(item.id)}
                  className={`relative h-16 px-1 text-sm font-semibold whitespace-nowrap shrink-0 transition-colors flex items-center ${
                    active
                      ? 'text-[#0F594E] dark:text-[#5EEAD4]'
                      : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
                  }`}
                >
                  {item.label}
                  {active && (
                    <span className="absolute inset-x-0 bottom-0 h-[2px] bg-[#0F594E] dark:bg-[#14B8A6]" />
                  )}
                </button>
              );
            })}
          </nav>

          {/* Zone 3: Notifications + Account Utility Popover */}
          <div className="flex items-center gap-2 shrink-0">
            {/* Notifications Bell */}
            <div className="relative" ref={notifMenuRef}>
              <button
                type="button"
                aria-label={tr(state.lang, 'notifications')}
                onClick={() => {
                  setShowNotifMenu((v) => !v);
                  setShowAccountMenu(false);
                  setState((prev) => ({
                    ...prev,
                    notifications: prev.notifications.map((n) => ({ ...n, isRead: true })),
                  }));
                }}
                className="relative p-2 rounded-lg text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
              >
                <Bell className="w-4 h-4" />
                {unreadCount > 0 && (
                  <span className="absolute top-1.5 end-1.5 w-2 h-2 rounded-full bg-[#0F594E] dark:bg-[#14B8A6]" />
                )}
              </button>

              {showNotifMenu && (
                <div className="absolute end-0 mt-2 w-80 rounded-2xl bg-white dark:bg-[#141C1E] border border-slate-200 dark:border-slate-800 shadow-xl overflow-hidden z-50">
                  <div className="px-4 py-3 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
                    <span className="text-xs font-semibold text-slate-900 dark:text-white">
                      {tr(state.lang, 'notifications')}
                    </span>
                    <span className="font-mono-num text-[11px] text-slate-400">
                      {state.notifications.length}
                    </span>
                  </div>
                  <div className="divide-y divide-slate-100 dark:divide-slate-800 max-h-72 overflow-y-auto">
                    {state.notifications.slice(0, 6).map((n) => (
                      <div key={n.id} className="px-4 py-3">
                        <p className="text-xs font-semibold text-slate-900 dark:text-white">
                          {n.title}
                        </p>
                        <p className="mt-0.5 text-xs text-slate-500 dark:text-slate-400">
                          {n.message}
                        </p>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Account & Preferences Menu */}
            <div className="relative" ref={accountMenuRef}>
              <button
                type="button"
                onClick={() => {
                  setShowAccountMenu((v) => !v);
                  setShowNotifMenu(false);
                }}
                className="inline-flex items-center gap-2 ps-1.5 pe-2.5 py-1 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] hover:border-slate-300 dark:hover:border-slate-700 transition-colors"
              >
                <WorkerAvatar
                  name={state.currentUser.fullName}
                  avatarUrl={
                    state.currentUser.role === 'Worker'
                      ? currentWorkerProfile?.avatarUrl
                      : undefined
                  }
                  size="xs"
                />
                <span className="hidden sm:inline text-xs font-semibold text-slate-800 dark:text-slate-100 max-w-[110px] truncate">
                  {state.currentUser.fullName}
                </span>
                <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
              </button>

              {showAccountMenu && (
                <div className="absolute end-0 mt-2 w-64 rounded-2xl bg-white dark:bg-[#141C1E] border border-slate-200 dark:border-slate-800 shadow-xl p-2 z-50 space-y-1">
                  <div className="px-3 py-2 border-b border-slate-100 dark:border-slate-800">
                    <p className="text-xs font-semibold text-slate-900 dark:text-white truncate">
                      {state.currentUser.fullName}
                    </p>
                    <p className="text-[11px] text-slate-500 dark:text-slate-400 truncate">
                      {state.currentUser.role} · {state.currentUser.email}
                    </p>
                  </div>

                  {/* Theme & Language */}
                  <button
                    type="button"
                    onClick={toggleTheme}
                    className="w-full px-3 py-2 rounded-xl text-xs font-medium text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 flex items-center justify-between"
                  >
                    <span className="inline-flex items-center gap-2">
                      {state.theme === 'dark' ? (
                        <Sun className="w-3.5 h-3.5" />
                      ) : (
                        <Moon className="w-3.5 h-3.5" />
                      )}
                      {state.theme === 'dark'
                        ? tr(state.lang, 'themeLight')
                        : tr(state.lang, 'themeDark')}
                    </span>
                  </button>

                  <button
                    type="button"
                    onClick={toggleLang}
                    className="w-full px-3 py-2 rounded-xl text-xs font-medium text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 flex items-center justify-between"
                  >
                    <span className="inline-flex items-center gap-2">
                      <Globe className="w-3.5 h-3.5" />
                      {state.lang === 'en' ? 'Switch to اردو (RTL)' : 'Switch to English'}
                    </span>
                  </button>

                  {/* Demo Role Switcher */}
                  <div className="pt-1.5 mt-1.5 border-t border-slate-100 dark:border-slate-800">
                    <p className="px-3 py-1 text-[10px] font-semibold uppercase tracking-wider text-slate-400">
                      {tr(state.lang, 'switchRole')}
                    </p>
                    {(
                      [
                        { role: 'Household' as UserRole, icon: Home, label: tr(state.lang, 'householdRole') },
                        { role: 'Worker' as UserRole, icon: Briefcase, label: tr(state.lang, 'workerRole') },
                        { role: 'Admin' as UserRole, icon: Shield, label: tr(state.lang, 'adminRole') },
                      ] as const
                    ).map(({ role, icon: RIcon, label }) => (
                      <button
                        key={role}
                        type="button"
                        onClick={() => handleSwitchRole(role)}
                        className={`w-full px-3 py-1.5 rounded-lg text-xs font-medium flex items-center justify-between ${
                          state.currentUser?.role === role
                            ? 'text-[#0F594E] dark:text-[#5EEAD4] font-semibold bg-[#0F594E]/6 dark:bg-[#14B8A6]/12'
                            : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'
                        }`}
                      >
                        <span className="inline-flex items-center gap-2">
                          <RIcon className="w-3.5 h-3.5" />
                          {label}
                        </span>
                      </button>
                    ))}
                  </div>

                  {/* Demo Utilities */}
                  <div className="pt-1.5 mt-1.5 border-t border-slate-100 dark:border-slate-800 space-y-0.5">
                    <button
                      type="button"
                      onClick={handleReplayOnboarding}
                      className="w-full px-3 py-2 rounded-xl text-xs font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 flex items-center gap-2"
                    >
                      <RotateCcw className="w-3.5 h-3.5" />
                      {tr(state.lang, 'replayIntro')}
                    </button>
                    <button
                      type="button"
                      onClick={handleResetDemoData}
                      className="w-full px-3 py-2 rounded-xl text-xs font-medium text-amber-700 dark:text-amber-400 hover:bg-amber-50 dark:hover:bg-amber-950/40 flex items-center gap-2"
                    >
                      <RotateCcw className="w-3.5 h-3.5" />
                      {tr(state.lang, 'resetDemo')}
                    </button>
                    <button
                      type="button"
                      onClick={handleSignOut}
                      className="w-full px-3 py-2 rounded-xl text-xs font-medium text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/30 flex items-center gap-2"
                    >
                      <LogOut className="w-3.5 h-3.5" />
                      {tr(state.lang, 'signOut')}
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </header>

      {/* Main Content Workspace (extra bottom clearance for mobile bottom tab bar) */}
      <main className="flex-1 w-full max-w-7xl mx-auto px-4 sm:px-6 py-5 md:py-8 pb-24 md:pb-10">
        {state.currentUser.role === 'Household' && activeTab === 'discover' && (
          <HouseholdDiscoverView
            currentUser={state.currentUser}
            workers={state.workers}
            bookings={state.bookings}
            reviews={state.reviews}
            lang={state.lang}
            theme={state.theme}
            quotaExceeded={quotaExceeded}
            onCreateBooking={handleCreateBooking}
          />
        )}

        {state.currentUser.role === 'Household' && activeTab === 'post_job' && (
          <HouseholdPostJobView
            currentUser={state.currentUser}
            jobPosts={state.jobPosts}
            applications={state.applications}
            lang={state.lang}
            onCreateJobPost={handleCreateJobPost}
            onAcceptProposal={handleAcceptProposal}
          />
        )}

        {state.currentUser.role === 'Household' && activeTab === 'bookings' && (
          <BookingsAndAgreementViews
            currentUser={state.currentUser}
            bookings={state.bookings}
            workers={state.workers}
            messages={state.messages}
            savedEmergencyContact={state.savedEmergencyContact}
            lang={state.lang}
            onUpdateBookingStatus={handleUpdateBookingStatus}
            onVerifyArrivalOtp={handleVerifyArrivalOtp}
            onSafetyCheckIn={handleSafetyCheckIn}
            onSaveEmergencyContact={handleSaveEmergencyContact}
            onTriggerSafetyAlert={handleTriggerSafetyAlert}
            onSettlePayment={handleSettlePayment}
            onSubmitReview={handleSubmitReview}
            onFileDispute={handleFileDispute}
            onSendMessage={handleSendMessage}
          />
        )}

        {state.currentUser.role === 'Worker' && activeTab === 'worker_dashboard' && (
          <WorkerDashboardView
            currentUser={state.currentUser}
            workerProfile={currentWorkerProfile}
            bookings={state.bookings}
            lang={state.lang}
            onUpdateBookingStatus={handleUpdateBookingStatus}
            onVerifyArrivalOtp={handleVerifyArrivalOtp}
          />
        )}

        {state.currentUser.role === 'Worker' && activeTab === 'worker_gigs' && (
          <WorkerJobsFeedView
            workerProfile={currentWorkerProfile}
            jobPosts={state.jobPosts}
            applications={state.applications}
            lang={state.lang}
            onApplyForJob={handleApplyForJob}
          />
        )}

        {state.currentUser.role === 'Worker' && activeTab === 'worker_availability' && (
          <WorkerAvailabilityView
            workerProfile={currentWorkerProfile}
            lang={state.lang}
            onUpdateAvailability={handleUpdateWorkerAvailability}
          />
        )}

        {state.currentUser.role === 'Worker' && activeTab === 'worker_profile' && (
          <WorkerProfileBuilderView
            workerProfile={currentWorkerProfile}
            lang={state.lang}
            onSaveProfile={handleSaveWorkerProfile}
          />
        )}

        {state.currentUser.role === 'Admin' && (
          <AdminDashboard
            workers={state.workers}
            bookings={state.bookings}
            disputes={state.disputes}
            auditLogs={state.auditLogs}
            safetyAlerts={state.safetyAlerts}
            lang={state.lang}
            activeTab={adminTab}
            onTabChange={setAdminTab}
            onApproveWorker={handleApproveWorker}
            onRejectWorker={handleRejectWorker}
            onResolveDispute={handleResolveDispute}
            onUpdateSafetyAlert={handleUpdateSafetyAlert}
          />
        )}
      </main>

      {/* Fixed Native Bottom Tab Bar for Phones (Thumb-Zone Navigation) */}
      <nav
        aria-label="Mobile navigation"
        className="md:hidden fixed bottom-0 inset-x-0 z-40 bg-[#FAFBF9]/95 dark:bg-[#0B1011]/95 backdrop-blur-md border-t border-slate-200 dark:border-slate-800 pb-safe"
      >
        {state.currentUser.role === 'Household' && (
          <div className="grid grid-cols-3 h-16 items-center px-2">
            {(
              [
                { id: 'discover' as ActiveTab, label: tr(state.lang, 'exploreWorkers'), icon: Compass },
                { id: 'post_job' as ActiveTab, label: tr(state.lang, 'postAJob'), icon: PlusCircle },
                { id: 'bookings' as ActiveTab, label: tr(state.lang, 'myBookings'), icon: CalendarDays },
              ] as const
            ).map((item) => {
              const Icon = item.icon;
              const active = activeTab === item.id;
              return (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => setActiveTab(item.id)}
                  className={`min-h-[48px] flex flex-col items-center justify-center gap-1 rounded-xl active:scale-95 transition-all ${
                    active
                      ? 'text-[#0F594E] dark:text-[#5EEAD4]'
                      : 'text-slate-500 dark:text-slate-400'
                  }`}
                >
                  <Icon className="w-[22px] h-[22px]" strokeWidth={active ? 2.25 : 1.8} />
                  <span className="text-[11px] font-semibold tracking-tight leading-none truncate max-w-[92px]">
                    {item.label}
                  </span>
                </button>
              );
            })}
          </div>
        )}

        {state.currentUser.role === 'Worker' && (
          <div className="grid grid-cols-4 h-16 items-center px-1">
            {(
              [
                { id: 'worker_dashboard' as ActiveTab, label: tr(state.lang, 'workerDashboard'), icon: LayoutDashboard },
                { id: 'worker_gigs' as ActiveTab, label: tr(state.lang, 'browseJobs'), icon: Briefcase },
                { id: 'worker_availability' as ActiveTab, label: tr(state.lang, 'availability'), icon: CalendarDays },
                { id: 'worker_profile' as ActiveTab, label: tr(state.lang, 'profileBuilder'), icon: UserCog },
              ] as const
            ).map((item) => {
              const Icon = item.icon;
              const active = activeTab === item.id;
              return (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => setActiveTab(item.id)}
                  className={`min-h-[48px] flex flex-col items-center justify-center gap-1 rounded-xl active:scale-95 transition-all ${
                    active
                      ? 'text-[#0F594E] dark:text-[#5EEAD4]'
                      : 'text-slate-500 dark:text-slate-400'
                  }`}
                >
                  <Icon className="w-[22px] h-[22px]" strokeWidth={active ? 2.25 : 1.8} />
                  <span className="text-[10px] font-semibold tracking-tight leading-none truncate max-w-[78px]">
                    {item.label}
                  </span>
                </button>
              );
            })}
          </div>
        )}

        {state.currentUser.role === 'Admin' && (
          <div className="grid grid-cols-4 h-16 items-center px-1">
            {(
              [
                { id: 'overview' as AdminTabId, label: tr(state.lang, 'platformAnalytics'), icon: TrendingUp },
                { id: 'verification' as AdminTabId, label: tr(state.lang, 'workerVerificationDesk'), icon: ShieldCheck },
                { id: 'disputes' as AdminTabId, label: tr(state.lang, 'disputeResolutionDesk'), icon: Scale },
                { id: 'audit' as AdminTabId, label: tr(state.lang, 'systemAuditLogs'), icon: ScrollText },
              ] as const
            ).map((item) => {
              const Icon = item.icon;
              const active = adminTab === item.id;
              return (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => setAdminTab(item.id)}
                  className={`min-h-[48px] flex flex-col items-center justify-center gap-1 rounded-xl active:scale-95 transition-all ${
                    active
                      ? 'text-[#0F594E] dark:text-[#5EEAD4]'
                      : 'text-slate-500 dark:text-slate-400'
                  }`}
                >
                  <Icon className="w-[22px] h-[22px]" strokeWidth={active ? 2.25 : 1.8} />
                  <span className="text-[10px] font-semibold tracking-tight leading-none truncate max-w-[78px]">
                    {item.label}
                  </span>
                </button>
              );
            })}
          </div>
        )}
      </nav>

      {/* Subtle Toast Notification (lifted above bottom tab bar on mobile) */}
      {toast && (
        <div className="fixed bottom-20 md:bottom-5 inset-x-4 sm:inset-x-auto sm:end-5 z-50 sm:max-w-sm rounded-xl bg-slate-900 dark:bg-slate-100 text-white dark:text-slate-900 px-4 py-3 text-xs font-semibold shadow-lg text-center sm:text-start">
          {toast}
        </div>
      )}
    </div>
  );
}
