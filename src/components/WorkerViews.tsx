import React, { useMemo, useState } from 'react';
import {
  CheckCircle2,
  Eye,
  EyeOff,
  FileCheck2,
  MapPin,
  ShieldCheck,
  Trash2,
  Upload,
  X,
} from 'lucide-react';
import { ABBOTTABAD_AREAS, LOCALITY_COORDINATES, SERVICE_CATEGORIES } from '../data/sampleData';
import { tr } from '../services/localization';
import {
  AppUser,
  Booking,
  JobApplication,
  JobPost,
  LanguageCode,
  WorkerProfile,
} from '../types';
import { WorkerAvatar } from './WorkerAvatar';

interface WorkerDashboardViewProps {
  currentUser: AppUser;
  workerProfile: WorkerProfile;
  bookings: Booking[];
  lang: LanguageCode;
  onUpdateBookingStatus: (bookingId: string, status: Booking['status']) => void;
  onVerifyArrivalOtp: (bookingId: string) => void;
}

export const WorkerDashboardView: React.FC<WorkerDashboardViewProps> = ({
  workerProfile,
  bookings,
  lang,
  onUpdateBookingStatus,
  onVerifyArrivalOtp,
}) => {
  const [otpInputs, setOtpInputs] = useState<Record<string, string>>({});
  const myBookings = useMemo(
    () => bookings.filter((b) => b.workerId === workerProfile.id),
    [bookings, workerProfile.id]
  );

  const completed = myBookings.filter((b) => b.status === 'Completed');
  const grossEarnings = completed.reduce((sum, b) => sum + b.agreedAmount, 0);
  const averageYield = completed.length > 0 ? Math.round(grossEarnings / completed.length) : 0;

  return (
    <div className="space-y-8">
      <div className="flex flex-wrap items-end justify-between gap-4 pb-5 border-b border-slate-200 dark:border-slate-800">
        <div className="flex items-center gap-4">
          <WorkerAvatar
            name={workerProfile.name}
            role={workerProfile.role}
            avatarUrl={workerProfile.avatarUrl}
            size="lg"
          />
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.14em] text-[#0F594E] dark:text-[#5EEAD4]">
              {workerProfile.verificationStatus === 'Verified'
                ? tr(lang, 'verified')
                : workerProfile.verificationStatus === 'PendingVerification'
                ? tr(lang, 'pending')
                : tr(lang, 'rejected')}
            </p>
            <h1 className="font-display text-3xl font-semibold text-slate-900 dark:text-white">
              {workerProfile.name}
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              {workerProfile.role} · {workerProfile.area}, Abbottabad · ★{' '}
              {workerProfile.rating.toFixed(1)}
            </p>
          </div>
        </div>
      </div>

      {/* KPI Row */}
      <div className="grid sm:grid-cols-3 gap-5">
        <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-5">
          <p className="text-xs text-slate-500 dark:text-slate-400">{tr(lang, 'grossEarnings')}</p>
          <p className="mt-2 font-mono-num text-2xl font-semibold text-slate-900 dark:text-white">
            PKR {grossEarnings.toLocaleString()}
          </p>
        </div>
        <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-5">
          <p className="text-xs text-slate-500 dark:text-slate-400">{tr(lang, 'completedTasks')}</p>
          <p className="mt-2 font-mono-num text-2xl font-semibold text-slate-900 dark:text-white">
            {completed.length}
          </p>
        </div>
        <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-5">
          <p className="text-xs text-slate-500 dark:text-slate-400">{tr(lang, 'averageYield')}</p>
          <p className="mt-2 font-mono-num text-2xl font-semibold text-slate-900 dark:text-white">
            PKR {averageYield.toLocaleString()}
          </p>
        </div>
      </div>

      {/* Incoming & Active Bookings */}
      <section className="space-y-4">
        <h2 className="text-sm font-semibold text-slate-900 dark:text-white">
          {tr(lang, 'incomingRequests')} ({myBookings.length})
        </h2>

        <div className="divide-y divide-slate-100 dark:divide-slate-800 rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E]">
          {myBookings.map((booking) => (
            <div
              key={booking.id}
              className="p-5 flex flex-col md:flex-row md:items-center justify-between gap-4"
            >
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="font-semibold text-slate-900 dark:text-white">
                    {booking.householdName}
                  </h3>
                  <span className="text-xs font-semibold text-[#0F594E] dark:text-[#5EEAD4]">
                    · {booking.status}
                  </span>
                </div>
                <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
                  {booking.address} · <span className="font-mono-num">{booking.bookingDate}</span> ·{' '}
                  <span className="font-mono-num">
                    {booking.startTime}–{booking.endTime}
                  </span>
                </p>
                <p className="mt-1 text-sm text-slate-600 dark:text-slate-300">{booking.notes}</p>
              </div>

              <div className="flex flex-wrap items-center gap-2.5 shrink-0">
                <span className="font-mono-num text-sm font-semibold text-slate-900 dark:text-white me-2">
                  PKR {booking.agreedAmount.toLocaleString()}
                </span>

                {booking.status === 'Pending' && (
                  <>
                    <button
                      type="button"
                      onClick={() => onUpdateBookingStatus(booking.id, 'Accepted')}
                      className="px-3.5 py-2 rounded-lg text-xs font-semibold bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E]"
                    >
                      {lang === 'ur' ? 'قبول کریں' : 'Accept'}
                    </button>
                    <button
                      type="button"
                      onClick={() => onUpdateBookingStatus(booking.id, 'Rejected')}
                      className="px-3 py-2 rounded-lg text-xs font-semibold text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800"
                    >
                      {lang === 'ur' ? 'انکار' : 'Decline'}
                    </button>
                  </>
                )}

                {booking.status === 'Accepted' && (
                  <div className="flex items-center gap-2">
                    <input
                      type="text"
                      maxLength={4}
                      value={otpInputs[booking.id] ?? ''}
                      onChange={(e) =>
                        setOtpInputs((prev) => ({ ...prev, [booking.id]: e.target.value }))
                      }
                      placeholder={`OTP ${booking.arrivalOtp}`}
                      className="w-28 px-2.5 py-1.5 rounded-lg bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-xs font-mono-num text-center"
                    />
                    <button
                      type="button"
                      onClick={() => {
                        if ((otpInputs[booking.id] ?? '').trim() === booking.arrivalOtp) {
                          onVerifyArrivalOtp(booking.id);
                        }
                      }}
                      className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E]"
                    >
                      {lang === 'ur' ? 'شروع کریں' : 'Start Visit'}
                    </button>
                  </div>
                )}

                {booking.status === 'In Progress' && (
                  <button
                    type="button"
                    onClick={() => onUpdateBookingStatus(booking.id, 'Completed')}
                    className="px-3.5 py-2 rounded-lg text-xs font-semibold bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E]"
                  >
                    {tr(lang, 'markCompleted')}
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
};

interface WorkerJobsFeedViewProps {
  workerProfile: WorkerProfile;
  jobPosts: JobPost[];
  applications: JobApplication[];
  lang: LanguageCode;
  onApplyForJob: (job: JobPost, proposedRate: number, notes: string) => void;
}

export const WorkerJobsFeedView: React.FC<WorkerJobsFeedViewProps> = ({
  workerProfile,
  jobPosts,
  applications,
  lang,
  onApplyForJob,
}) => {
  const [applyingJob, setApplyingJob] = useState<JobPost | null>(null);
  const [proposedRate, setProposedRate] = useState('');
  const [notes, setNotes] = useState('');

  const openJobs = useMemo(() => jobPosts.filter((j) => j.status === 'open'), [jobPosts]);

  return (
    <div className="space-y-6">
      <div className="pb-5 border-b border-slate-200 dark:border-slate-800">
        <h1 className="font-display text-3xl font-semibold text-slate-900 dark:text-white">
          {tr(lang, 'availableJobsTitle')}
        </h1>
        <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
          {lang === 'ur'
            ? 'ایبٹ آباد کے گھروں کی تازہ ضروریات دیکھیں اور اپنی پیشکش بھیجیں۔'
            : 'Browse open household requests across Abbottabad and submit your proposal.'}
        </p>
      </div>

      <div className="grid md:grid-cols-2 gap-5">
        {openJobs.map((job) => {
          const alreadyApplied = applications.some(
            (a) => a.jobPostId === job.id && a.workerId === workerProfile.id
          );
          return (
            <article
              key={job.id}
              className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-5 flex flex-col justify-between gap-4"
            >
              <div>
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <h3 className="font-display text-lg font-semibold text-slate-900 dark:text-white">
                      {job.title}
                    </h3>
                    <p className="mt-0.5 text-xs text-slate-500 dark:text-slate-400">
                      {job.householdName} · {job.serviceCategory} · {job.area}
                    </p>
                  </div>
                  <span className="font-mono-num text-sm font-semibold text-[#0F594E] dark:text-[#5EEAD4] shrink-0">
                    PKR {job.budget.toLocaleString()}
                  </span>
                </div>
                <p className="mt-3 text-sm text-slate-600 dark:text-slate-300 leading-relaxed">
                  {job.description}
                </p>
              </div>

              <div className="pt-3 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between">
                <span className="font-mono-num text-xs text-slate-500 dark:text-slate-400 inline-flex items-center gap-1">
                  <MapPin className="w-3.5 h-3.5" />
                  {job.area} · {job.requiredDate}
                </span>

                {alreadyApplied ? (
                  <span className="text-xs font-semibold text-emerald-700 dark:text-emerald-400">
                    ✓ {lang === 'ur' ? 'درخواست بھیج دی گئی' : 'Proposal Sent'}
                  </span>
                ) : (
                  <button
                    type="button"
                    onClick={() => {
                      setApplyingJob(job);
                      setProposedRate(String(job.budget));
                      setNotes('');
                    }}
                    className="px-3.5 py-2 rounded-lg text-xs font-semibold bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E]"
                  >
                    {tr(lang, 'applyNow')}
                  </button>
                )}
              </div>
            </article>
          );
        })}
      </div>

      {applyingJob && (
        <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
          <form
            onSubmit={(e) => {
              e.preventDefault();
              onApplyForJob(
                applyingJob,
                Math.max(500, parseInt(proposedRate, 10) || applyingJob.budget),
                notes.trim() || `Experienced ${workerProfile.role} available in ${applyingJob.area}.`
              );
              setApplyingJob(null);
            }}
            className="w-full max-w-md rounded-t-3xl sm:rounded-2xl bg-white dark:bg-[#141C1E] border-t sm:border border-slate-200 dark:border-slate-800 p-6 pb-safe space-y-4 shadow-2xl animate-sheet-up"
          >
            <div className="w-10 h-1.5 bg-slate-300 dark:bg-slate-700 rounded-full mx-auto -mt-2 sm:hidden" />
            <div className="flex items-center justify-between">
              <h3 className="font-display text-xl font-semibold text-slate-900 dark:text-white">
                {tr(lang, 'applyNow')}
              </h3>
              <button
                type="button"
                onClick={() => setApplyingJob(null)}
                className="min-h-[40px] min-w-[40px] flex items-center justify-center rounded-xl text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              {applyingJob.title} · {applyingJob.area}
            </p>
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {lang === 'ur' ? 'مجوزہ معاوضہ (PKR)' : 'Proposed Rate (PKR)'}
              </label>
              <input
                type="number"
                min={500}
                required
                value={proposedRate}
                onChange={(e) => setProposedRate(e.target.value)}
                className="w-full min-h-[46px] px-3.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-base sm:text-sm font-mono-num"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {lang === 'ur' ? 'پیغام' : 'Short Introduction'}
              </label>
              <textarea
                rows={3}
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder={
                  lang === 'ur'
                    ? 'اپنے تجربے اور دستیابی کے بارے میں لکھیں...'
                    : 'Share relevant experience and availability...'
                }
                className="w-full px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-base sm:text-sm"
              />
            </div>
            <button
              type="submit"
              className="w-full min-h-[48px] rounded-xl bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E] text-sm font-semibold active:scale-[0.98] transition-all"
            >
              {tr(lang, 'applyNow')}
            </button>
          </form>
        </div>
      )}
    </div>
  );
};

interface WorkerAvailabilityViewProps {
  workerProfile: WorkerProfile;
  lang: LanguageCode;
  onUpdateAvailability: (slots: string[], visible: boolean) => void;
}

const ALL_DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] as const;

export const WorkerAvailabilityView: React.FC<WorkerAvailabilityViewProps> = ({
  workerProfile,
  lang,
  onUpdateAvailability,
}) => {
  const [slots, setSlots] = useState<string[]>(workerProfile.availabilitySlots);
  const [visible, setVisible] = useState<boolean>(workerProfile.profileVisibility);

  const toggleDay = (day: string) => {
    const next = slots.includes(day) ? slots.filter((d) => d !== day) : [...slots, day];
    setSlots(next);
    onUpdateAvailability(next, visible);
  };

  return (
    <div className="space-y-6 max-w-2xl">
      <div className="pb-5 border-b border-slate-200 dark:border-slate-800">
        <h1 className="font-display text-3xl font-semibold text-slate-900 dark:text-white">
          {tr(lang, 'availability')}
        </h1>
        <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
          {lang === 'ur'
            ? 'اپنے ہفتہ وار دستیاب دن اور پروفائل کی نمائش کنٹرول کریں۔'
            : 'Control which days households can book you and manage profile visibility.'}
        </p>
      </div>

      <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-6 space-y-6">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-slate-400 mb-3">
            {lang === 'ur' ? 'ہفتہ وار شیڈول' : 'Active Weekly Days'}
          </p>
          <div className="grid grid-cols-4 sm:grid-cols-7 gap-2">
            {ALL_DAYS.map((day) => {
              const active = slots.includes(day);
              return (
                <button
                  key={day}
                  type="button"
                  onClick={() => toggleDay(day)}
                  className={`py-3 rounded-xl text-xs font-semibold border transition-colors ${
                    active
                      ? 'bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E] border-[#0F594E] dark:border-[#14B8A6]'
                      : 'border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300'
                  }`}
                >
                  {day}
                </button>
              );
            })}
          </div>
        </div>

        <div className="pt-5 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between gap-4">
          <div>
            <p className="text-sm font-semibold text-slate-900 dark:text-white">
              {lang === 'ur' ? 'تلاش اور نقشے میں پروفائل دکھائیں' : 'Show Profile in Search & Map'}
            </p>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              {lang === 'ur'
                ? 'بند کرنے پر آپ کی پروفائل عارضی طور پر چھپ جائے گی۔'
                : 'Pause visibility anytime without affecting existing confirmed visits.'}
            </p>
          </div>
          <button
            type="button"
            onClick={() => {
              const next = !visible;
              setVisible(next);
              onUpdateAvailability(slots, next);
            }}
            className={`inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-semibold border transition-colors ${
              visible
                ? 'bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E] border-[#0F594E] dark:border-[#14B8A6]'
                : 'border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300'
            }`}
          >
            {visible ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
            {visible
              ? lang === 'ur'
                ? 'ظاہر ہے'
                : 'Visible'
              : lang === 'ur'
              ? 'مخفی'
              : 'Paused'}
          </button>
        </div>
      </div>
    </div>
  );
};

interface WorkerProfileBuilderViewProps {
  workerProfile: WorkerProfile;
  lang: LanguageCode;
  onSaveProfile: (updated: Partial<WorkerProfile>, submitForVerification: boolean) => void;
}

export const WorkerProfileBuilderView: React.FC<WorkerProfileBuilderViewProps> = ({
  workerProfile,
  lang,
  onSaveProfile,
}) => {
  const [name, setName] = useState(workerProfile.name);
  const [role, setRole] = useState(workerProfile.role);
  const [area, setArea] = useState(workerProfile.area);
  const [numericRate, setNumericRate] = useState(String(workerProfile.numericRate));
  const [experienceYears, setExperienceYears] = useState(String(workerProfile.experienceYears));
  const [cnic, setCnic] = useState(workerProfile.cnic);
  const [phone, setPhone] = useState(workerProfile.phone);
  const [bio, setBio] = useState(workerProfile.bio);
  const [skillsText, setSkillsText] = useState(workerProfile.skillTags.join(', '));

  const [cnicPreview, setCnicPreview] = useState<string | undefined>(workerProfile.cnicDocPreview);
  const [cnicDocName, setCnicDocName] = useState<string | undefined>(workerProfile.cnicDocName);
  const [policePreview, setPolicePreview] = useState<string | undefined>(
    workerProfile.policeCertPreview
  );
  const [policeDocName, setPoliceDocName] = useState<string | undefined>(
    workerProfile.policeCertName
  );
  const [savedNotice, setSavedNotice] = useState<string | null>(null);

  const handleFileUpload = (
    file: File | undefined,
    target: 'cnic' | 'police'
  ) => {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      const dataUrl = typeof reader.result === 'string' ? reader.result : undefined;
      if (!dataUrl) return;
      if (target === 'cnic') {
        setCnicPreview(dataUrl);
        setCnicDocName(file.name);
      } else {
        setPolicePreview(dataUrl);
        setPoliceDocName(file.name);
      }
    };
    reader.readAsDataURL(file);
  };

  const buildPatch = (): Partial<WorkerProfile> => {
    const rateNum = Math.max(500, parseInt(numericRate, 10) || workerProfile.numericRate);
    const expNum = Math.max(1, parseInt(experienceYears, 10) || workerProfile.experienceYears);
    const coords = LOCALITY_COORDINATES[area] ?? LOCALITY_COORDINATES.Mandian;
    const parsedTags = skillsText
      .split(',')
      .map((t) => t.trim())
      .filter(Boolean);

    return {
      name: name.trim() || workerProfile.name,
      role,
      area,
      location: area,
      latitude: coords.lat,
      longitude: coords.lon,
      numericRate: rateNum,
      rate: `PKR ${rateNum.toLocaleString()} / visit`,
      experienceYears: expNum,
      experience: `${expNum} years`,
      cnic: cnic.trim(),
      phone: phone.trim(),
      bio: bio.trim(),
      description: bio.trim().slice(0, 120),
      skillTags: parsedTags.length > 0 ? parsedTags : workerProfile.skillTags,
      cnicDocPreview: cnicPreview,
      cnicDocName,
      policeCertPreview: policePreview,
      policeCertName: policeDocName,
    };
  };

  const handleSave = (submitForVerification: boolean) => {
    onSaveProfile(buildPatch(), submitForVerification);
    setSavedNotice(
      submitForVerification
        ? lang === 'ur'
          ? 'دستاویزات ایڈمن تصدیقی ڈیسک کو بھیج دی گئیں۔'
          : 'Profile & documents submitted to Admin Verification Desk.'
        : lang === 'ur'
        ? 'پروفائل محفوظ کر لی گئی۔'
        : 'Profile changes saved.'
    );
    window.setTimeout(() => setSavedNotice(null), 4000);
  };

  return (
    <div className="space-y-8">
      <div className="flex flex-wrap items-end justify-between gap-4 pb-5 border-b border-slate-200 dark:border-slate-800">
        <div>
          <h1 className="font-display text-3xl font-semibold text-slate-900 dark:text-white">
            {tr(lang, 'editProfileTitle')}
          </h1>
          <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
            {lang === 'ur'
              ? 'اپنا پیشہ ورانہ تعارف اپ ڈیٹ کریں اور نادرا شناختی کارڈ یا پولیس سرٹیفکیٹ کی تصویر اپ لوڈ کریں۔'
              : 'Keep your trade profile current and upload NADRA CNIC & Police Character Certificate previews for Admin verification.'}
          </p>
        </div>

        <div className="text-xs font-semibold text-[#0F594E] dark:text-[#5EEAD4] inline-flex items-center gap-1.5">
          <ShieldCheck className="w-4 h-4" />
          {workerProfile.verificationStatus === 'Verified'
            ? tr(lang, 'verified')
            : workerProfile.verificationStatus === 'PendingVerification'
            ? tr(lang, 'pending')
            : tr(lang, 'rejected')}
        </div>
      </div>

      {savedNotice && (
        <div className="rounded-xl px-4 py-3 bg-[#0F594E]/10 dark:bg-[#14B8A6]/15 border border-[#0F594E]/25 dark:border-[#14B8A6]/30 text-xs font-semibold text-[#0F594E] dark:text-[#5EEAD4] flex items-center gap-2">
          <CheckCircle2 className="w-4 h-4 shrink-0" />
          {savedNotice}
        </div>
      )}

      <div className="grid lg:grid-cols-12 gap-8 items-start">
        {/* Left: Trade Profile Details */}
        <div className="lg:col-span-7 rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-6 space-y-4">
          <div className="grid sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {tr(lang, 'fullName')}
              </label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {tr(lang, 'selectCategory')}
              </label>
              <select
                value={role}
                onChange={(e) => setRole(e.target.value)}
                className="w-full px-3 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm"
              >
                {SERVICE_CATEGORIES.filter((c) => c !== 'All').map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="grid sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {tr(lang, 'selectArea')}
              </label>
              <select
                value={area}
                onChange={(e) => setArea(e.target.value)}
                className="w-full px-3 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm"
              >
                {ABBOTTABAD_AREAS.map((a) => (
                  <option key={a} value={a}>
                    {a}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {lang === 'ur' ? 'فی وزٹ ریٹ (PKR)' : 'Rate per Visit (PKR)'}
              </label>
              <input
                type="number"
                min={500}
                step={100}
                value={numericRate}
                onChange={(e) => setNumericRate(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm font-mono-num"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {lang === 'ur' ? 'تجربہ (سال)' : 'Experience (Years)'}
              </label>
              <input
                type="number"
                min={1}
                max={40}
                value={experienceYears}
                onChange={(e) => setExperienceYears(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm font-mono-num"
              />
            </div>
          </div>

          <div className="grid sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                NADRA CNIC
              </label>
              <input
                type="text"
                value={cnic}
                onChange={(e) => setCnic(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm font-mono-num"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {tr(lang, 'phoneNumber')}
              </label>
              <input
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm font-mono-num"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
              {lang === 'ur' ? 'پیشہ ورانہ تعارف' : 'Professional Bio'}
            </label>
            <textarea
              rows={3}
              value={bio}
              onChange={(e) => setBio(e.target.value)}
              className="w-full px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
              {lang === 'ur' ? 'مہارتیں (کاما سے الگ کریں)' : 'Specialties (comma-separated)'}
            </label>
            <input
              type="text"
              value={skillsText}
              onChange={(e) => setSkillsText(e.target.value)}
              className="w-full px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm"
            />
          </div>

          <div className="pt-2 flex flex-col sm:flex-row items-stretch sm:items-center gap-2.5">
            <button
              type="button"
              onClick={() => handleSave(false)}
              className="min-h-[48px] px-5 rounded-xl text-sm sm:text-xs font-semibold bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E] active:scale-[0.98] transition-all"
            >
              {tr(lang, 'saveProfile')}
            </button>
            <button
              type="button"
              onClick={() => handleSave(true)}
              className="min-h-[48px] px-5 rounded-xl text-sm sm:text-xs font-semibold text-[#0F594E] dark:text-[#5EEAD4] border border-[#0F594E]/35 dark:border-[#14B8A6]/40 hover:bg-[#0F594E]/5 active:scale-[0.98] transition-all"
            >
              {tr(lang, 'submitVerification')}
            </button>
          </div>
        </div>

        {/* Right: Document Upload & Live Preview */}
        <div className="lg:col-span-5 rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-6 space-y-6">
          <div>
            <h2 className="font-display text-xl font-semibold text-slate-900 dark:text-white">
              {lang === 'ur' ? 'تصدیقی دستاویزات' : 'Verification Documents'}
            </h2>
            <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
              {lang === 'ur'
                ? 'اپ لوڈ کردہ تصاویر براہ راست ایڈمن تصدیقی ڈیسک پر نظر آتی ہیں۔'
                : 'Uploaded document previews sync immediately to the Admin Verification Desk.'}
            </p>
          </div>

          {/* NADRA CNIC Upload */}
          <DocumentUploadBox
            label={tr(lang, 'uploadCnic')}
            preview={cnicPreview}
            fileName={cnicDocName}
            lang={lang}
            onUpload={(file) => handleFileUpload(file, 'cnic')}
            onClear={() => {
              setCnicPreview(undefined);
              setCnicDocName(undefined);
            }}
          />

          {/* Police Character Certificate Upload */}
          <DocumentUploadBox
            label={tr(lang, 'uploadPoliceCert')}
            preview={policePreview}
            fileName={policeDocName}
            lang={lang}
            onUpload={(file) => handleFileUpload(file, 'police')}
            onClear={() => {
              setPolicePreview(undefined);
              setPoliceDocName(undefined);
            }}
          />
        </div>
      </div>
    </div>
  );
};

const DocumentUploadBox: React.FC<{
  label: string;
  preview?: string;
  fileName?: string;
  lang: LanguageCode;
  onUpload: (file?: File) => void;
  onClear: () => void;
}> = ({ label, preview, fileName, lang, onUpload, onClear }) => {
  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <span className="text-xs font-semibold text-slate-700 dark:text-slate-300">{label}</span>
        {preview && (
          <button
            type="button"
            onClick={onClear}
            className="text-xs text-red-600 dark:text-red-400 inline-flex items-center gap-1 hover:underline"
          >
            <Trash2 className="w-3 h-3" />
            {lang === 'ur' ? 'ہٹائیں' : 'Remove'}
          </button>
        )}
      </div>

      {preview ? (
        <div className="rounded-xl overflow-hidden border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-[#0F1618]">
          <img
            src={preview}
            alt={label}
            className="w-full h-40 object-cover"
          />
          <div className="px-3 py-2 flex items-center justify-between text-xs text-slate-600 dark:text-slate-300">
            <span className="inline-flex items-center gap-1.5 truncate">
              <FileCheck2 className="w-3.5 h-3.5 text-[#0F594E] dark:text-[#14B8A6] shrink-0" />
              <span className="truncate">{fileName || 'Document preview'}</span>
            </span>
            <label className="text-[#0F594E] dark:text-[#5EEAD4] font-semibold cursor-pointer shrink-0 ms-2">
              {lang === 'ur' ? 'تبدیل کریں' : 'Replace'}
              <input
                type="file"
                accept="image/*"
                className="hidden"
                onChange={(e) => onUpload(e.target.files?.[0])}
              />
            </label>
          </div>
        </div>
      ) : (
        <label className="flex flex-col items-center justify-center h-32 rounded-xl border border-dashed border-slate-300 dark:border-slate-700 bg-slate-50/70 dark:bg-[#0F1618] hover:border-[#0F594E] dark:hover:border-[#14B8A6] cursor-pointer transition-colors px-4 text-center">
          <Upload className="w-5 h-5 text-slate-400 mb-2" />
          <span className="text-xs font-semibold text-slate-700 dark:text-slate-300">{label}</span>
          <span className="mt-0.5 text-[11px] text-slate-400">PNG, JPG up to 5MB</span>
          <input
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => onUpload(e.target.files?.[0])}
          />
        </label>
      )}
    </div>
  );
};
