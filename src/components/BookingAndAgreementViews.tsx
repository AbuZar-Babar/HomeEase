import React, { useEffect, useMemo, useState } from 'react';
import {
  AlertOctagon,
  ArrowLeft,
  CheckCircle2,
  ChevronRight,
  CreditCard,
  FileText,
  KeyRound,
  MessageSquare,
  PhoneCall,
  Repeat,
  Send,
  Share2,
  ShieldCheck,
  Star,
  Timer,
  X,
} from 'lucide-react';
import { tr } from '../services/localization';
import {
  AppUser,
  Booking,
  ChatMessage,
  EmergencyContact,
  LanguageCode,
  WorkerProfile,
} from '../types';
import { WorkerAvatar } from './WorkerAvatar';

interface BookingsViewProps {
  currentUser: AppUser;
  bookings: Booking[];
  workers: WorkerProfile[];
  messages: ChatMessage[];
  savedEmergencyContact: EmergencyContact;
  lang: LanguageCode;
  onUpdateBookingStatus: (bookingId: string, status: Booking['status']) => void;
  onVerifyArrivalOtp: (bookingId: string) => void;
  onSafetyCheckIn: (bookingId: string, note: string) => void;
  onSaveEmergencyContact: (contact: EmergencyContact, bookingId?: string) => void;
  onTriggerSafetyAlert: (booking: Booking, contact: EmergencyContact) => void;
  onSettlePayment: (bookingId: string, method: Booking['paymentMethod']) => void;
  onSubmitReview: (payload: {
    bookingId: string;
    workerId: string;
    rating: number;
    punctuality: number;
    behavior: number;
    comment: string;
  }) => void;
  onFileDispute: (payload: {
    booking: Booking;
    category: string;
    description: string;
  }) => void;
  onSendMessage: (bookingId: string, text: string) => void;
}

function formatDuration(seconds: number): string {
  const safe = Math.max(0, Math.floor(seconds));
  const hrs = Math.floor(safe / 3600);
  const mins = Math.floor((safe % 3600) / 60);
  const secs = safe % 60;
  return [hrs, mins, secs].map((v) => String(v).padStart(2, '0')).join(':');
}

const LiveSessionTimer: React.FC<{ startedAt: string }> = ({ startedAt }) => {
  const [elapsedSec, setElapsedSec] = useState(() =>
    Math.max(0, Math.floor((Date.now() - new Date(startedAt).getTime()) / 1000))
  );

  useEffect(() => {
    const interval = window.setInterval(() => {
      setElapsedSec(Math.max(0, Math.floor((Date.now() - new Date(startedAt).getTime()) / 1000)));
    }, 1000);
    return () => window.clearInterval(interval);
  }, [startedAt]);

  return (
    <span className="font-mono-num text-2xl sm:text-3xl font-semibold tracking-tight text-slate-900 dark:text-white">
      {formatDuration(elapsedSec)}
    </span>
  );
};

export const BookingsAndAgreementViews: React.FC<BookingsViewProps> = ({
  currentUser,
  bookings,
  workers,
  messages,
  savedEmergencyContact,
  lang,
  onUpdateBookingStatus,
  onVerifyArrivalOtp,
  onSafetyCheckIn,
  onSaveEmergencyContact,
  onTriggerSafetyAlert,
  onSettlePayment,
  onSubmitReview,
  onFileDispute,
  onSendMessage,
}) => {
  const [filter, setFilter] = useState<'all' | 'active' | 'completed' | 'disputed'>('all');
  const [selectedBookingId, setSelectedBookingId] = useState<string | null>(null);
  const [mobileShowDetail, setMobileShowDetail] = useState(false);
  const [otpInput, setOtpInput] = useState('');
  const [otpError, setOtpError] = useState<string | null>(null);

  // Modals
  const [chatBookingId, setChatBookingId] = useState<string | null>(null);
  const [chatText, setChatText] = useState('');
  const [payBooking, setPayBooking] = useState<Booking | null>(null);
  const [receiptBooking, setReceiptBooking] = useState<Booking | null>(null);
  const [reviewBooking, setReviewBooking] = useState<Booking | null>(null);
  const [disputeBooking, setDisputeBooking] = useState<Booking | null>(null);

  // Safety console state
  const [editingContact, setEditingContact] = useState(false);
  const [contactDraft, setContactDraft] = useState<EmergencyContact>(savedEmergencyContact);
  const [shareCopied, setShareCopied] = useState(false);
  const [confirmingSos, setConfirmingSos] = useState(false);

  const myBookings = useMemo(() => {
    const owned = bookings.filter((b) =>
      currentUser.role === 'Household'
        ? b.householdId === currentUser.id
        : currentUser.role === 'Worker'
        ? b.workerId === currentUser.id
        : true
    );
    if (filter === 'active') {
      return owned.filter((b) => ['Pending', 'Accepted', 'In Progress'].includes(b.status));
    }
    if (filter === 'completed') {
      return owned.filter((b) => b.status === 'Completed');
    }
    if (filter === 'disputed') {
      return owned.filter((b) => b.status === 'Disputed');
    }
    return owned;
  }, [bookings, currentUser, filter]);

  const activeBooking = useMemo(
    () =>
      bookings.find((b) => b.id === selectedBookingId) ??
      myBookings.find((b) => b.status === 'In Progress') ??
      myBookings[0] ??
      null,
    [bookings, myBookings, selectedBookingId]
  );

  const workerMap = useMemo(() => new Map(workers.map((w) => [w.id, w])), [workers]);

  const handleOtpSubmit = (booking: Booking) => {
    setOtpError(null);
    if (otpInput.trim() !== booking.arrivalOtp) {
      setOtpError(
        lang === 'ur'
          ? 'غلط OTP کوڈ۔ براہ کرم 4 ہندسوں کا درست کوڈ درج کریں۔'
          : 'Incorrect OTP code. Please enter the 4-digit arrival code.'
      );
      return;
    }
    onVerifyArrivalOtp(booking.id);
    setOtpInput('');
  };

  const handleShareLiveVisit = (booking: Booking) => {
    const worker = workerMap.get(booking.workerId);
    const contact = booking.emergencyContact ?? savedEmergencyContact;
    const summary = [
      `HomeEase Live Visit Safety Summary`,
      `Household: ${booking.householdName}`,
      `Specialist: ${booking.workerName} (${booking.serviceCategoryId})`,
      worker ? `CNIC Verified: ${worker.cnic.slice(0, 6)}•••••${worker.cnic.slice(-2)}` : '',
      `Address: ${booking.address}`,
      `Window: ${booking.bookingDate} · ${booking.startTime}–${booking.endTime}`,
      `Emergency Contact: ${contact.name} (${contact.phone})`,
      `Status: ${booking.status} (Arrival OTP Verified)`,
    ]
      .filter(Boolean)
      .join('\n');

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(summary).catch(() => {});
    }
    setShareCopied(true);
    window.setTimeout(() => setShareCopied(false), 3000);
  };

  const statusTone = (status: Booking['status']) => {
    switch (status) {
      case 'In Progress':
        return 'text-[#0F594E] dark:text-[#5EEAD4]';
      case 'Completed':
        return 'text-emerald-700 dark:text-emerald-400';
      case 'Accepted':
        return 'text-sky-700 dark:text-sky-400';
      case 'Disputed':
      case 'Rejected':
      case 'Cancelled':
        return 'text-red-600 dark:text-red-400';
      default:
        return 'text-amber-700 dark:text-amber-400';
    }
  };

  return (
    <div className="space-y-8">
      {/* Header & Filter Strip */}
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 pb-5 border-b border-slate-200 dark:border-slate-800">
        <div>
          <h1 className="font-display text-3xl font-semibold text-slate-900 dark:text-white">
            {tr(lang, 'myBookings')}
          </h1>
          <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
            {lang === 'ur'
              ? 'باہمی معاہدے، آمد کا کوڈ، لائیو ٹائمر، حفاظتی چیک ان اور ایسکرو ادائیگیاں۔'
              : 'Track service agreements, verify arrival OTPs, monitor active timers, and settle via escrow.'}
          </p>
        </div>

        <div className="flex items-center gap-1.5">
          {(
            [
              { id: 'all', label: lang === 'ur' ? 'تمام' : 'All' },
              { id: 'active', label: lang === 'ur' ? 'جاری' : 'Active' },
              { id: 'completed', label: lang === 'ur' ? 'مکمل' : 'Completed' },
              { id: 'disputed', label: lang === 'ur' ? 'تنازعات' : 'Disputed' },
            ] as const
          ).map((tab) => (
            <button
              key={tab.id}
              type="button"
              onClick={() => setFilter(tab.id)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
                filter === tab.id
                  ? 'bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E]'
                  : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {myBookings.length === 0 ? (
        <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-12 text-center text-sm text-slate-500 dark:text-slate-400">
          {lang === 'ur' ? 'کوئی بکنگ موجود نہیں ہے۔' : 'No bookings in this view.'}
        </div>
      ) : (
        <div className="grid lg:grid-cols-12 gap-6 items-start">
          {/* Left Bookings Ledger (hidden on mobile when inspecting detail) */}
          <div
            className={`lg:col-span-5 rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] divide-y divide-slate-100 dark:divide-slate-800 overflow-hidden ${
              mobileShowDetail ? 'hidden lg:block' : 'block'
            }`}
          >
            {myBookings.map((booking) => {
              const worker = workerMap.get(booking.workerId);
              const isSelected = activeBooking?.id === booking.id;
              return (
                <button
                  key={booking.id}
                  type="button"
                  onClick={() => {
                    setSelectedBookingId(booking.id);
                    setMobileShowDetail(true);
                    setOtpError(null);
                    setConfirmingSos(false);
                  }}
                  className={`w-full min-h-[76px] p-4 text-start transition-colors flex items-center gap-3 active:bg-slate-100 dark:active:bg-slate-800/70 ${
                    isSelected
                      ? 'bg-[#0F594E]/6 dark:bg-[#14B8A6]/10'
                      : 'hover:bg-slate-50 dark:hover:bg-slate-800/40'
                  }`}
                >
                  <WorkerAvatar
                    name={
                      currentUser.role === 'Worker' ? booking.householdName : booking.workerName
                    }
                    role={booking.serviceCategoryId}
                    avatarUrl={currentUser.role === 'Worker' ? undefined : worker?.avatarUrl}
                    size="md"
                  />
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center justify-between gap-2">
                      <p className="text-sm font-semibold text-slate-900 dark:text-white truncate">
                        {currentUser.role === 'Worker'
                          ? booking.householdName
                          : booking.workerName}
                      </p>
                      <span className={`text-xs font-semibold shrink-0 ${statusTone(booking.status)}`}>
                        {booking.status}
                      </span>
                    </div>
                    <p className="mt-0.5 text-xs text-slate-500 dark:text-slate-400">
                      {booking.serviceCategoryId} ·{' '}
                      <span className="font-mono-num">{booking.bookingDate}</span> ·{' '}
                      <span className="font-mono-num">
                        {booking.startTime}–{booking.endTime}
                      </span>
                    </p>
                    <div className="mt-1.5 flex items-center justify-between text-xs">
                      <span className="font-mono-num font-semibold text-slate-800 dark:text-slate-200">
                        PKR {booking.agreedAmount.toLocaleString()}
                      </span>
                      {booking.recurrence !== 'one_time' && (
                        <span className="inline-flex items-center gap-1 text-[11px] font-medium text-[#0F594E] dark:text-[#5EEAD4]">
                          <Repeat className="w-3 h-3" />
                          {booking.recurrence}
                        </span>
                      )}
                    </div>
                  </div>
                  <ChevronRight
                    className={`w-4 h-4 text-slate-400 shrink-0 lg:hidden ${
                      lang === 'ur' ? 'rotate-180' : ''
                    }`}
                  />
                </button>
              );
            })}
          </div>

          {/* Right Service Agreement & Active Safety Console (full width detail on mobile) */}
          {activeBooking && (
            <div
              className={`lg:col-span-7 space-y-5 ${
                mobileShowDetail ? 'block' : 'hidden lg:block'
              }`}
            >
              {/* Mobile Back Button */}
              <button
                type="button"
                onClick={() => setMobileShowDetail(false)}
                className="lg:hidden min-h-[44px] inline-flex items-center gap-2 px-3 -ms-2 rounded-xl text-sm font-semibold text-[#0F594E] dark:text-[#5EEAD4] hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
              >
                <ArrowLeft className={`w-4 h-4 ${lang === 'ur' ? 'rotate-180' : ''}`} />
                {lang === 'ur' ? 'بکنگز کی فہرست پر واپس جائیں' : 'Back to Bookings'}
              </button>
              {/* Active Session Safety Console when In Progress */}
              {activeBooking.status === 'In Progress' && (
                <section className="rounded-2xl border border-[#0F594E]/30 dark:border-[#14B8A6]/35 bg-white dark:bg-[#141C1E] p-6 space-y-5">
                  <div className="flex flex-wrap items-center justify-between gap-4 pb-4 border-b border-slate-100 dark:border-slate-800">
                    <div>
                      <p className="text-xs font-semibold uppercase tracking-[0.14em] text-[#0F594E] dark:text-[#5EEAD4]">
                        {tr(lang, 'liveSessionConsole')}
                      </p>
                      <div className="mt-1.5 flex items-center gap-2.5">
                        <Timer className="w-5 h-5 text-[#0F594E] dark:text-[#14B8A6]" />
                        <LiveSessionTimer
                          startedAt={activeBooking.sessionStartedAt || activeBooking.createdAt}
                        />
                        <span className="text-xs text-slate-500 dark:text-slate-400">
                          {tr(lang, 'liveElapsed')}
                        </span>
                      </div>
                    </div>

                    <div className="flex flex-wrap items-center gap-2">
                      <button
                        type="button"
                        onClick={() =>
                          onSafetyCheckIn(
                            activeBooking.id,
                            lang === 'ur'
                              ? 'گھریلو صارف نے محفوظ چیک ان کی تصدیق کی'
                              : 'Household confirmed everything is safe and on track'
                          )
                        }
                        className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E] transition-colors"
                      >
                        <ShieldCheck className="w-4 h-4" />
                        {tr(lang, 'checkInSafe')}
                      </button>

                      <button
                        type="button"
                        onClick={() => handleShareLiveVisit(activeBooking)}
                        className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
                      >
                        <Share2 className="w-3.5 h-3.5" />
                        {tr(lang, 'shareLiveVisit')}
                      </button>
                    </div>
                  </div>

                  {shareCopied && (
                    <p className="text-xs font-semibold text-[#0F594E] dark:text-[#5EEAD4]">
                      ✓ {tr(lang, 'visitSummaryCopied')}
                    </p>
                  )}

                  {/* Emergency Contact + Check-In History */}
                  <div className="grid sm:grid-cols-2 gap-5">
                    <div className="space-y-2">
                      <div className="flex items-center justify-between">
                        <span className="text-xs font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">
                          {tr(lang, 'emergencyContact')}
                        </span>
                        <button
                          type="button"
                          onClick={() => {
                            setContactDraft(
                              activeBooking.emergencyContact ?? savedEmergencyContact
                            );
                            setEditingContact((v) => !v);
                          }}
                          className="text-xs font-semibold text-[#0F594E] dark:text-[#5EEAD4] hover:underline"
                        >
                          {editingContact
                            ? lang === 'ur'
                              ? 'بند کریں'
                              : 'Cancel'
                            : lang === 'ur'
                            ? 'ترمیم'
                            : 'Edit'}
                        </button>
                      </div>

                      {editingContact ? (
                        <div className="space-y-2">
                          <input
                            type="text"
                            value={contactDraft.name}
                            onChange={(e) =>
                              setContactDraft((c) => ({ ...c, name: e.target.value }))
                            }
                            placeholder="Contact name"
                            className="w-full px-3 py-1.5 rounded-lg bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-xs"
                          />
                          <div className="grid grid-cols-2 gap-2">
                            <input
                              type="text"
                              value={contactDraft.relation}
                              onChange={(e) =>
                                setContactDraft((c) => ({ ...c, relation: e.target.value }))
                              }
                              placeholder="Relation"
                              className="w-full px-3 py-1.5 rounded-lg bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-xs"
                            />
                            <input
                              type="tel"
                              value={contactDraft.phone}
                              onChange={(e) =>
                                setContactDraft((c) => ({ ...c, phone: e.target.value }))
                              }
                              placeholder="0300-XXXXXXX"
                              className="w-full px-3 py-1.5 rounded-lg bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-xs font-mono-num"
                            />
                          </div>
                          <button
                            type="button"
                            onClick={() => {
                              onSaveEmergencyContact(contactDraft, activeBooking.id);
                              setEditingContact(false);
                            }}
                            className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E]"
                          >
                            {tr(lang, 'saveContact')}
                          </button>
                        </div>
                      ) : (
                        <div className="text-xs text-slate-600 dark:text-slate-300 space-y-0.5">
                          <p className="font-semibold text-slate-900 dark:text-white">
                            {(activeBooking.emergencyContact ?? savedEmergencyContact).name} ·{' '}
                            <span className="font-normal text-slate-500 dark:text-slate-400">
                              {(activeBooking.emergencyContact ?? savedEmergencyContact).relation}
                            </span>
                          </p>
                          <p className="font-mono-num inline-flex items-center gap-1.5 text-slate-600 dark:text-slate-400">
                            <PhoneCall className="w-3 h-3" />
                            {(activeBooking.emergencyContact ?? savedEmergencyContact).phone}
                          </p>
                        </div>
                      )}
                    </div>

                    {/* Check-in Log */}
                    <div className="space-y-2">
                      <span className="text-xs font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500 block">
                        {lang === 'ur' ? 'حفاظتی چیک ان لاگ' : 'Check-In Timeline'}
                      </span>
                      <div className="space-y-1.5 max-h-24 overflow-y-auto">
                        {(activeBooking.safetyCheckIns ?? []).map((chk) => (
                          <p key={chk.id} className="text-xs text-slate-600 dark:text-slate-300">
                            <span className="font-mono-num text-[11px] text-slate-400 me-1.5">
                              {new Date(chk.timestamp).toLocaleTimeString([], {
                                hour: '2-digit',
                                minute: '2-digit',
                              })}
                            </span>
                            {chk.note}
                          </p>
                        ))}
                      </div>
                    </div>
                  </div>

                  {/* Guarded Emergency Alert Row */}
                  <div className="pt-4 border-t border-slate-100 dark:border-slate-800 flex flex-wrap items-center justify-between gap-3">
                    {activeBooking.sosTriggered ? (
                      <span className="text-xs font-semibold text-red-600 dark:text-red-400 inline-flex items-center gap-1.5">
                        <AlertOctagon className="w-4 h-4" />
                        {tr(lang, 'safetyAlertSent')}
                      </span>
                    ) : confirmingSos ? (
                      <div className="flex flex-wrap items-center gap-2 w-full justify-between">
                        <span className="text-xs font-medium text-red-700 dark:text-red-300">
                          {lang === 'ur'
                            ? 'کیا آپ واقعی ایبٹ آباد ایڈمن ڈیسک کو ہنگامی الرٹ بھیجنا چاہتے ہیں؟'
                            : 'Dispatch urgent safety alert to HomeEase Abbottabad Governance Desk?'}
                        </span>
                        <div className="flex items-center gap-2">
                          <button
                            type="button"
                            onClick={() => setConfirmingSos(false)}
                            className="px-3 py-1.5 rounded-lg text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
                          >
                            {lang === 'ur' ? 'منسوخ' : 'Cancel'}
                          </button>
                          <button
                            type="button"
                            onClick={() => {
                              onTriggerSafetyAlert(
                                activeBooking,
                                activeBooking.emergencyContact ?? savedEmergencyContact
                              );
                              setConfirmingSos(false);
                            }}
                            className="px-3.5 py-1.5 rounded-lg text-xs font-semibold bg-red-600 hover:bg-red-700 text-white transition-colors"
                          >
                            {tr(lang, 'confirmSafetyAlert')}
                          </button>
                        </div>
                      </div>
                    ) : (
                      <>
                        <span className="text-xs text-slate-500 dark:text-slate-400">
                          {lang === 'ur'
                            ? 'کسی ہنگامی صورت میں فوری طور پر ایڈمن کو مطلع کریں۔'
                            : 'Need immediate assistance? Alert our Abbottabad support desk.'}
                        </span>
                        <button
                          type="button"
                          onClick={() => setConfirmingSos(true)}
                          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold text-red-600 dark:text-red-400 border border-red-200 dark:border-red-900 hover:bg-red-50 dark:hover:bg-red-950/40 transition-colors"
                        >
                          <AlertOctagon className="w-3.5 h-3.5" />
                          {tr(lang, 'triggerSafetyAlert')}
                        </button>
                      </>
                    )}
                  </div>
                </section>
              )}

              {/* Service Agreement Detail Card */}
              <section className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-6 space-y-5">
                <div className="flex flex-wrap items-start justify-between gap-4 pb-4 border-b border-slate-100 dark:border-slate-800">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500 font-mono-num">
                      {tr(lang, 'serviceAgreement')} · #{activeBooking.id}
                    </p>
                    <h2 className="mt-1 font-display text-2xl font-semibold text-slate-900 dark:text-white">
                      {activeBooking.serviceCategoryId} — {activeBooking.workerName}
                    </h2>
                    <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
                      {activeBooking.address}
                    </p>
                  </div>
                  <div className="text-end">
                    <p className="font-mono-num text-xl font-semibold text-slate-900 dark:text-white">
                      PKR {activeBooking.agreedAmount.toLocaleString()}
                    </p>
                    <p className={`text-xs font-semibold ${statusTone(activeBooking.status)}`}>
                      {activeBooking.status} · {activeBooking.paymentStatus}
                    </p>
                  </div>
                </div>

                {/* Metadata Grid */}
                <div className="grid sm:grid-cols-3 gap-4 text-xs">
                  <div>
                    <p className="text-slate-400 dark:text-slate-500">
                      {lang === 'ur' ? 'تاریخ اور وقت' : 'Date & Window'}
                    </p>
                    <p className="mt-1 font-mono-num font-semibold text-slate-900 dark:text-white">
                      {activeBooking.bookingDate}
                    </p>
                    <p className="font-mono-num text-slate-600 dark:text-slate-400">
                      {activeBooking.startTime} – {activeBooking.endTime}
                    </p>
                  </div>
                  <div>
                    <p className="text-slate-400 dark:text-slate-500">
                      {tr(lang, 'bookingCadence')}
                    </p>
                    <p className="mt-1 font-semibold capitalize text-slate-900 dark:text-white">
                      {activeBooking.recurrence.replace('_', ' ')}
                      {activeBooking.discountPercent ? ` (-${activeBooking.discountPercent}%)` : ''}
                    </p>
                    {activeBooking.recurringDays && (
                      <p className="text-slate-600 dark:text-slate-400">
                        {activeBooking.recurringDays.join(', ')}
                      </p>
                    )}
                  </div>
                  <div>
                    <p className="text-slate-400 dark:text-slate-500">
                      {tr(lang, 'arrivalOtp')}
                    </p>
                    <p className="mt-1 font-mono-num text-base font-bold tracking-[0.2em] text-[#0F594E] dark:text-[#5EEAD4]">
                      {activeBooking.arrivalOtp}
                    </p>
                    <p className="text-slate-500 dark:text-slate-400">
                      {lang === 'ur' ? 'آمد پر شیئر کریں' : 'Share upon arrival'}
                    </p>
                  </div>
                </div>

                <p className="text-sm text-slate-600 dark:text-slate-300 leading-relaxed pt-3 border-t border-slate-100 dark:border-slate-800">
                  {activeBooking.notes}
                </p>

                {/* Arrival OTP Verification Bar for Accepted Bookings */}
                {activeBooking.status === 'Accepted' && (
                  <div className="pt-4 border-t border-slate-100 dark:border-slate-800 space-y-2.5">
                    <label className="flex items-center gap-1.5 text-xs font-semibold text-slate-700 dark:text-slate-300">
                      <KeyRound className="w-3.5 h-3.5 text-[#0F594E] dark:text-[#14B8A6]" />
                      {tr(lang, 'verifyArrival')}
                    </label>
                    <div className="flex flex-wrap items-center gap-2">
                      <input
                        type="text"
                        maxLength={4}
                        value={otpInput}
                        onChange={(e) => setOtpInput(e.target.value)}
                        placeholder={activeBooking.arrivalOtp}
                        className="w-36 px-3.5 py-2 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm font-mono-num tracking-[0.25em] text-center text-slate-900 dark:text-white"
                      />
                      <button
                        type="button"
                        onClick={() => handleOtpSubmit(activeBooking)}
                        className="px-4 py-2 rounded-xl text-xs font-semibold bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E] transition-colors"
                      >
                        {tr(lang, 'verifyArrival')}
                      </button>
                    </div>
                    {otpError && (
                      <p className="text-xs font-medium text-red-600 dark:text-red-400">
                        {otpError}
                      </p>
                    )}
                  </div>
                )}

                {/* Action Bar */}
                <div className="pt-4 border-t border-slate-100 dark:border-slate-800 flex flex-wrap items-center gap-2.5">
                  <button
                    type="button"
                    onClick={() => setChatBookingId(activeBooking.id)}
                    className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
                  >
                    <MessageSquare className="w-3.5 h-3.5" />
                    {tr(lang, 'directChat')}
                  </button>

                  {activeBooking.status === 'In Progress' && (
                    <button
                      type="button"
                      onClick={() => onUpdateBookingStatus(activeBooking.id, 'Completed')}
                      className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E] transition-colors"
                    >
                      <CheckCircle2 className="w-3.5 h-3.5" />
                      {tr(lang, 'markCompleted')}
                    </button>
                  )}

                  {currentUser.role === 'Household' &&
                    activeBooking.status === 'Completed' &&
                    activeBooking.paymentStatus !== 'confirmed' && (
                      <button
                        type="button"
                        onClick={() => setPayBooking(activeBooking)}
                        className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E] transition-colors"
                      >
                        <CreditCard className="w-3.5 h-3.5" />
                        {tr(lang, 'payViaGateway')}
                      </button>
                    )}

                  {activeBooking.paymentStatus === 'confirmed' && (
                    <button
                      type="button"
                      onClick={() => setReceiptBooking(activeBooking)}
                      className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold text-[#0F594E] dark:text-[#5EEAD4] border border-[#0F594E]/30 dark:border-[#14B8A6]/40 hover:bg-[#0F594E]/5 transition-colors"
                    >
                      <FileText className="w-3.5 h-3.5" />
                      {tr(lang, 'viewReceipt')}
                    </button>
                  )}

                  {currentUser.role === 'Household' &&
                    activeBooking.status === 'Completed' &&
                    !activeBooking.rated && (
                      <button
                        type="button"
                        onClick={() => setReviewBooking(activeBooking)}
                        className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold text-amber-700 dark:text-amber-300 border border-amber-300/70 dark:border-amber-700 hover:bg-amber-50 dark:hover:bg-amber-950/30 transition-colors"
                      >
                        <Star className="w-3.5 h-3.5" />
                        {tr(lang, 'rateWorker')}
                      </button>
                    )}

                  {activeBooking.status !== 'Disputed' && activeBooking.status !== 'Cancelled' && (
                    <button
                      type="button"
                      onClick={() => setDisputeBooking(activeBooking)}
                      className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold text-slate-500 dark:text-slate-400 hover:text-red-600 dark:hover:text-red-400 transition-colors ms-auto"
                    >
                      {tr(lang, 'dispute')}
                    </button>
                  )}
                </div>
              </section>
            </div>
          )}
        </div>
      )}

      {/* Direct Chat Bottom Sheet */}
      {chatBookingId && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
          <div className="w-full max-w-lg rounded-t-3xl sm:rounded-2xl bg-white dark:bg-[#141C1E] border-t sm:border border-slate-200 dark:border-slate-800 shadow-2xl flex flex-col max-h-[88dvh] animate-sheet-up overflow-hidden">
            <div className="w-10 h-1.5 bg-slate-300 dark:bg-slate-700 rounded-full mx-auto mt-3 sm:hidden shrink-0" />
            <div className="p-4 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
              <h3 className="font-display text-lg font-semibold text-slate-900 dark:text-white">
                {tr(lang, 'directChat')} · #{chatBookingId}
              </h3>
              <button
                type="button"
                onClick={() => setChatBookingId(null)}
                className="min-h-[40px] min-w-[40px] flex items-center justify-center rounded-xl text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="flex-1 p-4 space-y-3 overflow-y-auto min-h-[240px]">
              {messages
                .filter((m) => m.bookingId === chatBookingId)
                .map((m) => {
                  const mine = m.senderId === currentUser.id;
                  return (
                    <div
                      key={m.id}
                      className={`flex flex-col ${mine ? 'items-end' : 'items-start'}`}
                    >
                      <span className="text-[11px] text-slate-400 mb-0.5">{m.senderName}</span>
                      <div
                        className={`max-w-[82%] px-3.5 py-2.5 rounded-2xl text-sm ${
                          mine
                            ? 'bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E]'
                            : 'bg-slate-100 dark:bg-[#1D282A] text-slate-800 dark:text-slate-100'
                        }`}
                      >
                        {m.text}
                      </div>
                    </div>
                  );
                })}
            </div>
            <form
              onSubmit={(e) => {
                e.preventDefault();
                if (!chatText.trim()) return;
                onSendMessage(chatBookingId, chatText.trim());
                setChatText('');
              }}
              className="p-3 pb-safe border-t border-slate-100 dark:border-slate-800 flex items-center gap-2"
            >
              <input
                type="text"
                value={chatText}
                onChange={(e) => setChatText(e.target.value)}
                placeholder={lang === 'ur' ? 'پیغام لکھیں...' : 'Write a message...'}
                className="flex-1 min-h-[44px] px-3.5 rounded-xl bg-slate-50 dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-base sm:text-sm text-slate-900 dark:text-white"
              />
              <button
                type="submit"
                className="min-h-[44px] min-w-[44px] flex items-center justify-center rounded-xl bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E]"
              >
                <Send className="w-4 h-4" />
              </button>
            </form>
          </div>
        </div>
      )}

      {/* Escrow Payment Modal */}
      {payBooking && (
        <EscrowPaymentModal
          booking={payBooking}
          lang={lang}
          onClose={() => setPayBooking(null)}
          onPay={(method) => {
            onSettlePayment(payBooking.id, method);
            setPayBooking(null);
          }}
        />
      )}

      {/* Digital Receipt Bottom Sheet */}
      {receiptBooking && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
          <div className="w-full max-w-md rounded-t-3xl sm:rounded-2xl bg-white dark:bg-[#141C1E] border-t sm:border border-slate-200 dark:border-slate-800 p-6 pb-safe space-y-4 shadow-2xl animate-sheet-up">
            <div className="w-10 h-1.5 bg-slate-300 dark:bg-slate-700 rounded-full mx-auto -mt-2 sm:hidden" />
            <div className="flex items-center justify-between">
              <h3 className="font-display text-xl font-semibold text-slate-900 dark:text-white">
                {tr(lang, 'viewReceipt')}
              </h3>
              <button
                type="button"
                onClick={() => setReceiptBooking(null)}
                className="min-h-[40px] min-w-[40px] flex items-center justify-center rounded-xl text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="space-y-2.5 text-xs border-y border-slate-100 dark:border-slate-800 py-4">
              <div className="flex justify-between">
                <span className="text-slate-500">Transaction ID</span>
                <span className="font-mono-num font-semibold text-slate-900 dark:text-white">
                  {receiptBooking.transactionId || `HE-${receiptBooking.id.toUpperCase()}`}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Specialist</span>
                <span className="font-semibold text-slate-900 dark:text-white">
                  {receiptBooking.workerName}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Date</span>
                <span className="font-mono-num text-slate-900 dark:text-white">
                  {receiptBooking.bookingDate}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Method</span>
                <span className="uppercase font-semibold text-slate-900 dark:text-white">
                  {receiptBooking.paymentMethod}
                </span>
              </div>
              <div className="flex justify-between pt-2 border-t border-slate-100 dark:border-slate-800 text-sm">
                <span className="font-semibold text-slate-900 dark:text-white">Settled Total</span>
                <span className="font-mono-num font-bold text-[#0F594E] dark:text-[#5EEAD4]">
                  PKR {receiptBooking.agreedAmount.toLocaleString()}
                </span>
              </div>
            </div>
            <button
              type="button"
              onClick={() => setReceiptBooking(null)}
              className="w-full min-h-[48px] rounded-xl bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E] text-sm font-semibold active:scale-[0.98] transition-all"
            >
              {lang === 'ur' ? 'بند کریں' : 'Close Receipt'}
            </button>
          </div>
        </div>
      )}

      {/* Review Modal */}
      {reviewBooking && (
        <ReviewModal
          booking={reviewBooking}
          lang={lang}
          onClose={() => setReviewBooking(null)}
          onSubmit={(data) => {
            onSubmitReview({
              bookingId: reviewBooking.id,
              workerId: reviewBooking.workerId,
              ...data,
            });
            setReviewBooking(null);
          }}
        />
      )}

      {/* Dispute Modal */}
      {disputeBooking && (
        <DisputeModal
          booking={disputeBooking}
          lang={lang}
          onClose={() => setDisputeBooking(null)}
          onSubmit={(category, description) => {
            onFileDispute({ booking: disputeBooking, category, description });
            setDisputeBooking(null);
          }}
        />
      )}
    </div>
  );
};

const EscrowPaymentModal: React.FC<{
  booking: Booking;
  lang: LanguageCode;
  onClose: () => void;
  onPay: (method: Booking['paymentMethod']) => void;
}> = ({ booking, lang, onClose, onPay }) => {
  const [method, setMethod] = useState<Booking['paymentMethod']>(booking.paymentMethod);

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="w-full max-w-md rounded-t-3xl sm:rounded-2xl bg-white dark:bg-[#141C1E] border-t sm:border border-slate-200 dark:border-slate-800 p-6 pb-safe space-y-5 shadow-2xl animate-sheet-up">
        <div className="w-10 h-1.5 bg-slate-300 dark:bg-slate-700 rounded-full mx-auto -mt-2 sm:hidden" />
        <div className="flex items-center justify-between">
          <h3 className="font-display text-xl font-semibold text-slate-900 dark:text-white">
            {tr(lang, 'payViaGateway')}
          </h3>
          <button
            type="button"
            onClick={onClose}
            className="min-h-[40px] min-w-[40px] flex items-center justify-center rounded-xl text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="text-center py-3 border-y border-slate-100 dark:border-slate-800">
          <p className="text-xs text-slate-500 dark:text-slate-400">{booking.workerName}</p>
          <p className="mt-1 font-mono-num text-3xl font-semibold text-slate-900 dark:text-white">
            PKR {booking.agreedAmount.toLocaleString()}
          </p>
        </div>

        <div className="grid grid-cols-2 gap-2.5">
          {(
            [
              { id: 'easypaisa', label: 'Easypaisa' },
              { id: 'jazzcash', label: 'JazzCash' },
              { id: 'card', label: 'Debit / Credit Card' },
              { id: 'cash', label: 'Cash on Delivery' },
            ] as const
          ).map((item) => (
            <button
              key={item.id}
              type="button"
              onClick={() => setMethod(item.id)}
              className={`min-h-[46px] p-3 rounded-xl border text-xs font-semibold transition-colors ${
                method === item.id
                  ? 'border-[#0F594E] dark:border-[#14B8A6] bg-[#0F594E]/8 dark:bg-[#14B8A6]/15 text-[#0F594E] dark:text-[#5EEAD4]'
                  : 'border-slate-200 dark:border-slate-800 text-slate-700 dark:text-slate-300'
              }`}
            >
              {item.label}
            </button>
          ))}
        </div>

        <button
          type="button"
          onClick={() => onPay(method)}
          className="w-full min-h-[48px] rounded-xl bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E] text-sm font-semibold active:scale-[0.98] transition-all"
        >
          {lang === 'ur' ? 'ادائیگی کی تصدیق کریں' : 'Confirm Escrow Settlement'}
        </button>
      </div>
    </div>
  );
};

const ReviewModal: React.FC<{
  booking: Booking;
  lang: LanguageCode;
  onClose: () => void;
  onSubmit: (data: {
    rating: number;
    punctuality: number;
    behavior: number;
    comment: string;
  }) => void;
}> = ({ booking, lang, onClose, onSubmit }) => {
  const [rating, setRating] = useState(5);
  const [comment, setComment] = useState('');

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
      <form
        onSubmit={(e) => {
          e.preventDefault();
          onSubmit({
            rating,
            punctuality: rating,
            behavior: rating,
            comment: comment.trim() || 'Punctual, courteous, and thorough household service.',
          });
        }}
        className="w-full max-w-md rounded-t-3xl sm:rounded-2xl bg-white dark:bg-[#141C1E] border-t sm:border border-slate-200 dark:border-slate-800 p-6 pb-safe space-y-4 shadow-2xl animate-sheet-up"
      >
        <div className="w-10 h-1.5 bg-slate-300 dark:bg-slate-700 rounded-full mx-auto -mt-2 sm:hidden" />
        <div className="flex items-center justify-between">
          <h3 className="font-display text-xl font-semibold text-slate-900 dark:text-white">
            {tr(lang, 'rateWorker')}
          </h3>
          <button
            type="button"
            onClick={onClose}
            className="min-h-[40px] min-w-[40px] flex items-center justify-center rounded-xl text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        <p className="text-xs text-slate-500 dark:text-slate-400">
          {booking.workerName} · {booking.serviceCategoryId}
        </p>
        <div className="flex items-center gap-1.5">
          {[1, 2, 3, 4, 5].map((n) => (
            <button
              key={n}
              type="button"
              onClick={() => setRating(n)}
              className="min-h-[44px] min-w-[44px] flex items-center justify-center"
              aria-label={`${n} stars`}
            >
              <Star
                className={`w-7 h-7 ${
                  n <= rating ? 'fill-amber-500 text-amber-500' : 'text-slate-300 dark:text-slate-700'
                }`}
              />
            </button>
          ))}
        </div>
        <textarea
          rows={3}
          value={comment}
          onChange={(e) => setComment(e.target.value)}
          placeholder={lang === 'ur' ? 'اپنی رائے لکھیں...' : 'Share your experience...'}
          className="w-full px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-base sm:text-sm text-slate-900 dark:text-white"
        />
        <button
          type="submit"
          className="w-full min-h-[48px] rounded-xl bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E] text-sm font-semibold active:scale-[0.98] transition-all"
        >
          {lang === 'ur' ? 'رائے جمع کروائیں' : 'Submit Review'}
        </button>
      </form>
    </div>
  );
};

const DisputeModal: React.FC<{
  booking: Booking;
  lang: LanguageCode;
  onClose: () => void;
  onSubmit: (category: string, description: string) => void;
}> = ({ booking, lang, onClose, onSubmit }) => {
  const [category, setCategory] = useState('Service Quality');
  const [description, setDescription] = useState('');

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
      <form
        onSubmit={(e) => {
          e.preventDefault();
          if (!description.trim()) return;
          onSubmit(category, description.trim());
        }}
        className="w-full max-w-md rounded-t-3xl sm:rounded-2xl bg-white dark:bg-[#141C1E] border-t sm:border border-slate-200 dark:border-slate-800 p-6 pb-safe space-y-4 shadow-2xl animate-sheet-up"
      >
        <div className="w-10 h-1.5 bg-slate-300 dark:bg-slate-700 rounded-full mx-auto -mt-2 sm:hidden" />
        <div className="flex items-center justify-between">
          <h3 className="font-display text-xl font-semibold text-slate-900 dark:text-white">
            {tr(lang, 'dispute')}
          </h3>
          <button
            type="button"
            onClick={onClose}
            className="min-h-[40px] min-w-[40px] flex items-center justify-center rounded-xl text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        <p className="text-xs text-slate-500 dark:text-slate-400">
          #{booking.id} · {booking.workerName}
        </p>
        <select
          value={category}
          onChange={(e) => setCategory(e.target.value)}
          className="w-full min-h-[46px] px-3.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-base sm:text-sm text-slate-900 dark:text-white"
        >
          <option value="Service Quality">Service Quality</option>
          <option value="Payment Discrepancy">Payment Discrepancy</option>
          <option value="Late Arrival / No Show">Late Arrival / No Show</option>
          <option value="Conduct & Safety">Conduct & Safety</option>
        </select>
        <textarea
          rows={3}
          required
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder={
            lang === 'ur' ? 'مسئلے کی تفصیل لکھیں...' : 'Describe what occurred for our arbitration officer...'
          }
          className="w-full px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-base sm:text-sm text-slate-900 dark:text-white"
        />
        <button
          type="submit"
          className="w-full min-h-[48px] rounded-xl bg-red-600 hover:bg-red-700 text-white text-sm font-semibold active:scale-[0.98] transition-all"
        >
          {lang === 'ur' ? 'شکایت درج کریں' : 'Submit Dispute'}
        </button>
      </form>
    </div>
  );
};
