import React, { useMemo, useState } from 'react';
import {
  AlertTriangle,
  Calendar,
  CheckCircle2,
  Clock,
  LayoutGrid,
  Map as MapIcon,
  MapPin,
  Plus,
  Repeat,
  Search,
  Star,
  X,
} from 'lucide-react';
import {
  ABBOTTABAD_AREAS,
  LOCALITY_COORDINATES,
  RECURRENCE_PLANS,
  SERVICE_CATEGORIES,
} from '../data/sampleData';
import {
  calculateRecurringPricing,
  checkBookingConflict,
  recommendWorkers,
} from '../services/engines';
import { tr } from '../services/localization';
import {
  AIRecommendationResult,
  AppUser,
  Booking,
  JobApplication,
  JobPost,
  LanguageCode,
  RecurrenceCadence,
  ReviewItem,
  ThemeMode,
  WorkerProfile,
} from '../types';
import { AbbottabadWorkerMap } from './AbbottabadWorkerMap';
import { WorkerAvatar } from './WorkerAvatar';

interface HouseholdDiscoverViewProps {
  currentUser: AppUser;
  workers: WorkerProfile[];
  bookings: Booking[];
  reviews: ReviewItem[];
  lang: LanguageCode;
  theme: ThemeMode;
  quotaExceeded: boolean;
  onCreateBooking: (booking: Omit<Booking, 'id' | 'createdAt' | 'arrivalOtp'>) => void;
}

const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] as const;

export const HouseholdDiscoverView: React.FC<HouseholdDiscoverViewProps> = ({
  currentUser,
  workers,
  bookings,
  reviews,
  lang,
  theme,
  quotaExceeded,
  onCreateBooking,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [selectedArea, setSelectedArea] = useState<string>(currentUser.area || 'Mandian');
  const [viewMode, setViewMode] = useState<'grid' | 'map'>('grid');
  const [detailWorker, setDetailWorker] = useState<WorkerProfile | null>(null);
  const [bookingWorker, setBookingWorker] = useState<WorkerProfile | null>(null);

  const recommendations = useMemo(
    () =>
      recommendWorkers({
        workers,
        targetCategory: selectedCategory,
        targetArea: selectedArea,
        searchQuery,
      }),
    [workers, selectedCategory, selectedArea, searchQuery]
  );

  const detailRec = useMemo(
    () =>
      detailWorker
        ? recommendations.find((r) => r.worker.id === detailWorker.id) ?? null
        : null,
    [detailWorker, recommendations]
  );

  return (
    <div className="space-y-6 sm:space-y-8">
      {/* Editorial Header */}
      <section className="flex flex-col lg:flex-row lg:items-end justify-between gap-4 sm:gap-6 pb-5 sm:pb-6 border-b border-slate-200 dark:border-slate-800">
        <div className="max-w-2xl">
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-[#0F594E] dark:text-[#5EEAD4]">
            {lang === 'ur' ? `ایبٹ آباد · ${selectedArea}` : `Abbottabad · ${selectedArea}`}
          </p>
          <h1 className="mt-1.5 font-display text-2xl sm:text-4xl font-semibold tracking-tight text-slate-900 dark:text-white leading-tight">
            {tr(lang, 'findHelp')}
          </h1>
          <p className="mt-1.5 text-sm text-slate-600 dark:text-slate-400 leading-relaxed">
            {tr(lang, 'findHelpSubtitle')}
          </p>
        </div>

        {/* View Mode Switcher */}
        <div className="grid grid-cols-2 sm:inline-flex p-1 rounded-xl bg-slate-100 dark:bg-[#141C1E] border border-slate-200 dark:border-slate-800 w-full sm:w-auto">
          <button
            type="button"
            onClick={() => setViewMode('grid')}
            className={`min-h-[42px] inline-flex items-center justify-center gap-1.5 px-3.5 rounded-lg text-xs font-semibold transition-colors ${
              viewMode === 'grid'
                ? 'bg-white dark:bg-[#1E292C] text-slate-900 dark:text-white shadow-xs'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            <LayoutGrid className="w-4 h-4" />
            {tr(lang, 'viewGrid')}
          </button>
          <button
            type="button"
            onClick={() => setViewMode('map')}
            className={`min-h-[42px] inline-flex items-center justify-center gap-1.5 px-3.5 rounded-lg text-xs font-semibold transition-colors ${
              viewMode === 'map'
                ? 'bg-white dark:bg-[#1E292C] text-slate-900 dark:text-white shadow-xs'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            <MapIcon className="w-4 h-4" />
            {tr(lang, 'viewMap')}
          </button>
        </div>
      </section>

      {/* Search & Filter Toolbar */}
      <section className="space-y-3.5">
        <div className="grid sm:grid-cols-12 gap-2.5 sm:gap-3">
          <div className="sm:col-span-8 relative">
            <Search className="w-4 h-4 text-slate-400 absolute start-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder={tr(lang, 'searchPlaceholder')}
              className="w-full min-h-[46px] ps-10 pe-4 rounded-xl bg-white dark:bg-[#141C1E] border border-slate-200 dark:border-slate-800 text-base sm:text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0F594E]/20 dark:focus:ring-[#14B8A6]/25 focus:border-[#0F594E] dark:focus:border-[#14B8A6]"
            />
          </div>
          <div className="sm:col-span-4 relative">
            <MapPin className="w-4 h-4 text-slate-400 absolute start-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            <select
              value={selectedArea}
              onChange={(e) => setSelectedArea(e.target.value)}
              aria-label={tr(lang, 'selectArea')}
              className="w-full min-h-[46px] ps-10 pe-4 rounded-xl bg-white dark:bg-[#141C1E] border border-slate-200 dark:border-slate-800 text-base sm:text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-[#0F594E]/20 dark:focus:ring-[#14B8A6]/25 focus:border-[#0F594E] dark:focus:border-[#14B8A6]"
            >
              {ABBOTTABAD_AREAS.map((area) => (
                <option key={area} value={area}>
                  {area}, Abbottabad
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Category Filter Tabs (Interactive controls only — zero decorative pills) */}
        <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar pb-1 -mx-4 px-4 sm:mx-0 sm:px-0">
          {SERVICE_CATEGORIES.map((category) => {
            const active = selectedCategory === category;
            return (
              <button
                key={category}
                type="button"
                onClick={() => setSelectedCategory(category)}
                className={`min-h-[40px] px-3.5 rounded-xl text-xs font-semibold whitespace-nowrap shrink-0 active:scale-[0.98] transition-all ${
                  active
                    ? 'bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E]'
                    : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800/70 hover:text-slate-900 dark:hover:text-slate-100'
                }`}
              >
                {category}
              </button>
            );
          })}
        </div>
      </section>

      {/* Main Content: Grid or Interactive Abbottabad Map */}
      {viewMode === 'map' ? (
        <AbbottabadWorkerMap
          recommendations={recommendations}
          selectedArea={selectedArea}
          onSelectArea={setSelectedArea}
          onSelectWorker={setDetailWorker}
          onBookWorker={setBookingWorker}
          lang={lang}
          theme={theme}
          quotaExceeded={quotaExceeded}
        />
      ) : (
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-semibold text-slate-900 dark:text-white">
              {tr(lang, 'aiRecommendations')}
            </h2>
            <span className="font-mono-num text-xs text-slate-500 dark:text-slate-400">
              {recommendations.length} {lang === 'ur' ? 'ماہرین' : 'specialists'}
            </span>
          </div>

          {recommendations.length === 0 ? (
            <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-12 text-center">
              <p className="text-sm font-medium text-slate-700 dark:text-slate-300">
                {lang === 'ur'
                  ? 'آپ کی تلاش کے مطابق کوئی ورکر نہیں ملا۔'
                  : 'No specialists match your search criteria.'}
              </p>
              <button
                type="button"
                onClick={() => {
                  setSearchQuery('');
                  setSelectedCategory('All');
                }}
                className="mt-4 px-4 py-2 rounded-lg text-xs font-semibold text-[#0F594E] dark:text-[#5EEAD4] border border-[#0F594E]/30 dark:border-[#14B8A6]/40 hover:bg-[#0F594E]/5 transition-colors"
              >
                {lang === 'ur' ? 'فلٹرز صاف کریں' : 'Clear filters'}
              </button>
            </div>
          ) : (
            <div className="grid md:grid-cols-2 xl:grid-cols-3 gap-5">
              {recommendations.map((rec) => (
                <WorkerEditorialCard
                  key={rec.worker.id}
                  rec={rec}
                  lang={lang}
                  onViewProfile={() => setDetailWorker(rec.worker)}
                  onBook={() => setBookingWorker(rec.worker)}
                />
              ))}
            </div>
          )}
        </section>
      )}

      {/* Worker Profile Modal */}
      {detailWorker && (
        <WorkerDetailModal
          worker={detailWorker}
          rec={detailRec}
          reviews={reviews.filter((r) => r.workerId === detailWorker.id)}
          lang={lang}
          onClose={() => setDetailWorker(null)}
          onBook={() => {
            const target = detailWorker;
            setDetailWorker(null);
            setBookingWorker(target);
          }}
        />
      )}

      {/* Recurring & Conflict-Aware Booking Modal */}
      {bookingWorker && (
        <BookingModal
          worker={bookingWorker}
          currentUser={currentUser}
          existingBookings={bookings}
          lang={lang}
          onClose={() => setBookingWorker(null)}
          onConfirm={(payload) => {
            onCreateBooking(payload);
            setBookingWorker(null);
          }}
        />
      )}
    </div>
  );
};

const WorkerEditorialCard: React.FC<{
  rec: AIRecommendationResult;
  lang: LanguageCode;
  onViewProfile: () => void;
  onBook: () => void;
}> = ({ rec, lang, onViewProfile, onBook }) => {
  const { worker } = rec;

  return (
    <article className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-5 flex flex-col justify-between hover:border-slate-300 dark:hover:border-slate-700 transition-colors">
      <div>
        {/* Portrait + Name + Match */}
        <div className="flex items-start gap-3.5">
          <WorkerAvatar
            name={worker.name}
            role={worker.role}
            avatarUrl={worker.avatarUrl}
            size="lg"
          />
          <div className="min-w-0 flex-1">
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-1.5 min-w-0">
                <h3 className="font-display text-lg font-semibold text-slate-900 dark:text-white truncate">
                  {worker.name}
                </h3>
                {worker.verificationStatus === 'Verified' && (
                  <CheckCircle2
                    aria-label={tr(lang, 'verified')}
                    className="w-4 h-4 text-[#0F594E] dark:text-[#14B8A6] shrink-0"
                  />
                )}
              </div>
              <span className="font-mono-num text-xs font-semibold text-[#0F594E] dark:text-[#5EEAD4] shrink-0">
                {rec.matchPercentage}%
              </span>
            </div>

            {/* Unboxed inline metadata line (Zero-Pill Discipline) */}
            <p className="mt-0.5 text-xs text-slate-500 dark:text-slate-400">
              {worker.role} · {worker.experience} · {worker.area}
            </p>

            {/* Rating + Distance inline */}
            <div className="mt-1.5 flex items-center gap-2 text-xs text-slate-600 dark:text-slate-300 font-mono-num">
              <span className="inline-flex items-center gap-1 font-semibold text-slate-900 dark:text-slate-100">
                <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
                {worker.rating.toFixed(1)}
              </span>
              <span className="text-slate-400">({worker.reviewsCount})</span>
              <span className="text-slate-300 dark:text-slate-700">·</span>
              <span>{rec.distanceKm.toFixed(1)} km</span>
              <span className="text-slate-300 dark:text-slate-700">·</span>
              <span className="text-slate-500 dark:text-slate-400 font-sans">
                {worker.availability}
              </span>
            </div>
          </div>
        </div>

        {/* Clean description */}
        <p className="mt-4 text-sm text-slate-600 dark:text-slate-300 leading-relaxed line-clamp-2">
          {worker.description}
        </p>

        {/* Quiet XAI rationale line */}
        <p className="mt-3 text-xs text-slate-500 dark:text-slate-400">
          {rec.matchReasons.slice(0, 2).join(' · ')}
        </p>
      </div>

      {/* Price & Actions Footer */}
      <div className="mt-5 pt-4 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between gap-3">
        <div>
          <span className="font-mono-num text-base font-semibold text-slate-900 dark:text-white">
            PKR {worker.numericRate.toLocaleString()}
          </span>
          <span className="text-xs text-slate-500 dark:text-slate-400 ms-1">/ visit</span>
        </div>

        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={onViewProfile}
            className="min-h-[42px] px-3.5 rounded-xl text-xs font-semibold text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 active:scale-[0.98] transition-all"
          >
            {tr(lang, 'viewProfile')}
          </button>
          <button
            type="button"
            onClick={onBook}
            className="min-h-[42px] px-4 rounded-xl text-xs font-semibold bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E] active:scale-[0.98] transition-all"
          >
            {tr(lang, 'bookNow')}
          </button>
        </div>
      </div>
    </article>
  );
};

const WorkerDetailModal: React.FC<{
  worker: WorkerProfile;
  rec: AIRecommendationResult | null;
  reviews: ReviewItem[];
  lang: LanguageCode;
  onClose: () => void;
  onBook: () => void;
}> = ({ worker, rec, reviews, lang, onClose, onBook }) => {
  return (
    <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="w-full max-w-2xl max-h-[92dvh] flex flex-col rounded-t-3xl sm:rounded-2xl bg-white dark:bg-[#141C1E] border-t sm:border border-slate-200 dark:border-slate-800 shadow-2xl animate-sheet-up overflow-hidden">
        <div className="w-10 h-1.5 bg-slate-300 dark:bg-slate-700 rounded-full mx-auto mt-3 sm:hidden shrink-0" />
        {/* Header */}
        <div className="p-5 sm:p-6 border-b border-slate-100 dark:border-slate-800 flex items-start justify-between gap-4 shrink-0">
          <div className="flex items-start gap-4">
            <WorkerAvatar
              name={worker.name}
              role={worker.role}
              avatarUrl={worker.avatarUrl}
              size="xl"
            />
            <div>
              <div className="flex items-center gap-2">
                <h2 className="font-display text-2xl font-semibold text-slate-900 dark:text-white">
                  {worker.name}
                </h2>
                {worker.verificationStatus === 'Verified' && (
                  <CheckCircle2 className="w-5 h-5 text-[#0F594E] dark:text-[#14B8A6]" />
                )}
              </div>
              <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                {worker.role} · {worker.experience} · {worker.area}, {worker.city}
              </p>
              <p className="mt-1 text-xs text-slate-500 dark:text-slate-400 font-mono-num">
                ★ {worker.rating.toFixed(1)} ({worker.reviewsCount}) · CNIC{' '}
                {worker.cnic.slice(0, 6)}•••••{worker.cnic.slice(-2)} · {worker.availability}
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close"
            className="p-2 rounded-lg text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Body */}
        <div className="p-5 sm:p-6 space-y-6 overflow-y-auto flex-1">
          <div>
            <h3 className="text-xs font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">
              {lang === 'ur' ? 'تعارف اور مہارت' : 'About & Specialties'}
            </h3>
            <p className="mt-2 text-sm text-slate-700 dark:text-slate-300 leading-relaxed">
              {worker.bio}
            </p>
            <p className="mt-3 text-xs font-medium text-slate-600 dark:text-slate-400">
              {worker.skillTags.join(' · ')}
            </p>
          </div>

          {rec && (
            <div className="pt-5 border-t border-slate-100 dark:border-slate-800">
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-xs font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">
                  {lang === 'ur' ? 'شفاف اے آئی مطابقت' : 'Explainable Match Breakdown'}
                </h3>
                <span className="font-mono-num text-xs font-semibold text-[#0F594E] dark:text-[#5EEAD4]">
                  {rec.matchPercentage}% {tr(lang, 'aiMatch')}
                </span>
              </div>
              <div className="grid sm:grid-cols-3 gap-4">
                {[
                  {
                    label: lang === 'ur' ? 'مہارت (50%)' : 'Skill Fit (50%)',
                    value: rec.skillScore,
                  },
                  {
                    label: lang === 'ur' ? 'قربت (35%)' : 'Proximity (35%)',
                    value: rec.geoScore,
                  },
                  {
                    label: lang === 'ur' ? 'درجہ بندی (15%)' : 'Rating (15%)',
                    value: rec.ratingScore,
                  },
                ].map((bar) => (
                  <div key={bar.label}>
                    <div className="flex items-center justify-between text-xs mb-1.5">
                      <span className="text-slate-600 dark:text-slate-400">{bar.label}</span>
                      <span className="font-mono-num font-semibold text-slate-900 dark:text-white">
                        {bar.value}%
                      </span>
                    </div>
                    <div className="h-1.5 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                      <div
                        className="h-full bg-[#0F594E] dark:bg-[#14B8A6] rounded-full"
                        style={{ width: `${bar.value}%` }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Reviews */}
          <div className="pt-5 border-t border-slate-100 dark:border-slate-800">
            <h3 className="text-xs font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500 mb-3">
              {lang === 'ur' ? 'تصدیق شدہ گھریلو آراء' : 'Verified Household Reviews'}
            </h3>
            {reviews.length === 0 ? (
              <p className="text-xs text-slate-500 dark:text-slate-400">
                {lang === 'ur'
                  ? 'ابھی تک کوئی تحریری تبصرہ نہیں ہے۔'
                  : 'No written reviews submitted yet.'}
              </p>
            ) : (
              <div className="divide-y divide-slate-100 dark:divide-slate-800">
                {reviews.map((rev) => (
                  <div key={rev.id} className="py-3 first:pt-0 last:pb-0">
                    <div className="flex items-center justify-between text-xs">
                      <span className="font-semibold text-slate-900 dark:text-white">
                        {rev.authorName}
                      </span>
                      <span className="font-mono-num text-amber-600 dark:text-amber-400 font-semibold">
                        ★ {rev.rating.toFixed(1)}
                      </span>
                    </div>
                    <p className="mt-1 text-sm text-slate-600 dark:text-slate-300">
                      {rev.comment}
                    </p>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 sm:p-6 pb-safe border-t border-slate-100 dark:border-slate-800 flex items-center justify-between gap-4 shrink-0 bg-white dark:bg-[#141C1E]">
          <div>
            <p className="font-mono-num text-lg sm:text-xl font-semibold text-slate-900 dark:text-white">
              PKR {worker.numericRate.toLocaleString()}
            </p>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              {lang === 'ur' ? 'ہفتہ وار پلان پر 15% تک بچت' : 'Save up to 15% on recurring plans'}
            </p>
          </div>
          <button
            type="button"
            onClick={onBook}
            className="min-h-[48px] px-6 rounded-xl text-sm font-semibold bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E] active:scale-[0.98] transition-all shrink-0"
          >
            {tr(lang, 'bookNow')}
          </button>
        </div>
      </div>
    </div>
  );
};

const BookingModal: React.FC<{
  worker: WorkerProfile;
  currentUser: AppUser;
  existingBookings: Booking[];
  lang: LanguageCode;
  onClose: () => void;
  onConfirm: (booking: Omit<Booking, 'id' | 'createdAt' | 'arrivalOtp'>) => void;
}> = ({ worker, currentUser, existingBookings, lang, onClose, onConfirm }) => {
  const defaultDate = new Date(Date.now() + 86400 * 1000).toISOString().split('T')[0];
  const [date, setDate] = useState(defaultDate);
  const [startTime, setStartTime] = useState('10:00');
  const [endTime, setEndTime] = useState('13:00');
  const [cadence, setCadence] = useState<RecurrenceCadence>('one_time');
  const [recurringDays, setRecurringDays] = useState<string[]>(['Mon', 'Thu']);
  const [address, setAddress] = useState(
    `House 14, Lane 2, ${currentUser.area || 'Mandian'}, Abbottabad`
  );
  const [notes, setNotes] = useState('');
  const [paymentMethod, setPaymentMethod] = useState<Booking['paymentMethod']>('easypaisa');

  const pricing = useMemo(
    () => calculateRecurringPricing(worker.numericRate, cadence, recurringDays.length),
    [worker.numericRate, cadence, recurringDays.length]
  );

  const conflict = useMemo(
    () =>
      checkBookingConflict({
        workerId: worker.id,
        date,
        startTime,
        endTime,
        existingBookings,
      }),
    [worker.id, date, startTime, endTime, existingBookings]
  );

  const toggleDay = (day: string) => {
    setRecurringDays((prev) =>
      prev.includes(day)
        ? prev.length > 1
          ? prev.filter((d) => d !== day)
          : prev
        : [...prev, day]
    );
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (conflict.hasConflict) return;

    onConfirm({
      householdId: currentUser.id,
      householdName: currentUser.fullName,
      workerId: worker.id,
      workerName: worker.name,
      serviceCategoryId: worker.role,
      bookingDate: date,
      startTime,
      endTime,
      address: address.trim() || `${currentUser.area || 'Mandian'}, Abbottabad`,
      notes: notes.trim() || `${worker.role} service booking`,
      agreedAmount: pricing.perVisitAmount,
      baseAmount: pricing.baseAmount,
      recurrence: cadence,
      recurringDays: cadence === 'one_time' ? undefined : recurringDays,
      discountPercent: pricing.discountPercent,
      status: 'Pending',
      paymentMethod,
      paymentStatus: 'unpaid',
    });
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/60 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4">
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-xl max-h-[92dvh] flex flex-col rounded-t-3xl sm:rounded-2xl bg-white dark:bg-[#141C1E] border-t sm:border border-slate-200 dark:border-slate-800 shadow-2xl animate-sheet-up overflow-hidden"
      >
        <div className="w-10 h-1.5 bg-slate-300 dark:bg-slate-700 rounded-full mx-auto mt-3 sm:hidden shrink-0" />
        <div className="p-5 sm:p-6 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-3">
            <WorkerAvatar
              name={worker.name}
              role={worker.role}
              avatarUrl={worker.avatarUrl}
              size="md"
            />
            <div>
              <h2 className="font-display text-xl font-semibold text-slate-900 dark:text-white">
                {worker.name}
              </h2>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                {worker.role} · {worker.area} · PKR {worker.numericRate.toLocaleString()} base
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="min-h-[40px] min-w-[40px] flex items-center justify-center rounded-xl text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-5 sm:p-6 space-y-5 overflow-y-auto flex-1">
          {/* Recurring Plan Cadence */}
          <div>
            <label className="flex items-center gap-1.5 text-xs font-semibold text-slate-700 dark:text-slate-300 mb-2">
              <Repeat className="w-3.5 h-3.5 text-[#0F594E] dark:text-[#14B8A6]" />
              {tr(lang, 'bookingCadence')}
            </label>
            <div className="grid grid-cols-2 gap-2">
              {RECURRENCE_PLANS.map((plan) => {
                const active = cadence === plan.id;
                return (
                  <button
                    key={plan.id}
                    type="button"
                    onClick={() => setCadence(plan.id)}
                    className={`p-3 rounded-xl border text-start transition-colors ${
                      active
                        ? 'border-[#0F594E] dark:border-[#14B8A6] bg-[#0F594E]/6 dark:bg-[#14B8A6]/12'
                        : 'border-slate-200 dark:border-slate-800 hover:border-slate-300 dark:hover:border-slate-700'
                    }`}
                  >
                    <div className="flex items-center justify-between gap-1">
                      <span className="text-xs font-semibold text-slate-900 dark:text-white">
                        {lang === 'ur' ? plan.labelUr : plan.labelEn}
                      </span>
                      {plan.discountPercent > 0 && (
                        <span className="font-mono-num text-[11px] font-semibold text-[#0F594E] dark:text-[#5EEAD4]">
                          -{plan.discountPercent}%
                        </span>
                      )}
                    </div>
                    <p className="mt-0.5 text-[11px] text-slate-500 dark:text-slate-400">
                      {lang === 'ur' ? plan.summaryUr : plan.summaryEn}
                    </p>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Preferred Weekly Days if recurring */}
          {cadence !== 'one_time' && (
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-2">
                {tr(lang, 'preferredDays')}
              </label>
              <div className="flex flex-wrap gap-1.5">
                {WEEKDAYS.map((day) => {
                  const selected = recurringDays.includes(day);
                  return (
                    <button
                      key={day}
                      type="button"
                      onClick={() => toggleDay(day)}
                      className={`px-3 py-1.5 rounded-lg text-xs font-semibold border transition-colors ${
                        selected
                          ? 'bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E] border-[#0F594E] dark:border-[#14B8A6]'
                          : 'bg-white dark:bg-[#0F1618] text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-800'
                      }`}
                    >
                      {day}
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Date & Time Window */}
          <div className="grid sm:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {lang === 'ur' ? 'تاریخ' : 'Start Date'}
              </label>
              <input
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                required
                className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-xs font-mono-num text-slate-900 dark:text-slate-100"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {lang === 'ur' ? 'آغاز وقت' : 'Start Time'}
              </label>
              <input
                type="time"
                value={startTime}
                onChange={(e) => setStartTime(e.target.value)}
                required
                className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-xs font-mono-num text-slate-900 dark:text-slate-100"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {lang === 'ur' ? 'اختتام وقت' : 'End Time'}
              </label>
              <input
                type="time"
                value={endTime}
                onChange={(e) => setEndTime(e.target.value)}
                required
                className="w-full px-3 py-2 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-xs font-mono-num text-slate-900 dark:text-slate-100"
              />
            </div>
          </div>

          {/* Mathematical Conflict Guard */}
          {conflict.hasConflict && (
            <div className="rounded-xl p-3.5 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900 flex items-start gap-2.5 text-xs text-red-700 dark:text-red-300">
              <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
              <div>
                <p className="font-semibold">{tr(lang, 'scheduleConflict')}</p>
                <p className="mt-0.5">{conflict.error}</p>
              </div>
            </div>
          )}

          {/* Address & Notes */}
          <div>
            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
              {lang === 'ur' ? 'گھر کا پتہ' : 'Abbottabad Residence Address'}
            </label>
            <input
              type="text"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              required
              className="w-full px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm text-slate-900 dark:text-slate-100"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
              {lang === 'ur' ? 'خصوصی ہدایات' : 'Household Instructions'}
            </label>
            <textarea
              rows={2}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder={
                lang === 'ur'
                  ? 'مثلاً کھانے کا مینو یا صفائی کے کمرے...'
                  : 'e.g. Gate instructions, menu preferences, or priority rooms...'
              }
              className="w-full px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm text-slate-900 dark:text-slate-100"
            />
          </div>

          {/* Payment Method */}
          <div>
            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-2">
              {lang === 'ur' ? 'ادائیگی کا طریقہ' : 'Preferred Escrow Settlement'}
            </label>
            <div className="grid grid-cols-4 gap-2">
              {(
                [
                  { id: 'easypaisa', label: 'Easypaisa' },
                  { id: 'jazzcash', label: 'JazzCash' },
                  { id: 'card', label: 'Card' },
                  { id: 'cash', label: 'Cash' },
                ] as const
              ).map((m) => (
                <button
                  key={m.id}
                  type="button"
                  onClick={() => setPaymentMethod(m.id)}
                  className={`py-2 rounded-lg text-xs font-semibold border transition-colors ${
                    paymentMethod === m.id
                      ? 'bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E] border-[#0F594E] dark:border-[#14B8A6]'
                      : 'border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300'
                  }`}
                >
                  {m.label}
                </button>
              ))}
            </div>
          </div>

          {/* Pricing Breakdown */}
          <div className="pt-4 border-t border-slate-100 dark:border-slate-800 space-y-1.5 text-xs">
            <div className="flex justify-between text-slate-600 dark:text-slate-400">
              <span>{tr(lang, 'perVisit')}</span>
              <span className="font-mono-num font-semibold text-slate-900 dark:text-white">
                PKR {pricing.perVisitAmount.toLocaleString()}
              </span>
            </div>
            {pricing.discountPercent > 0 && (
              <div className="flex justify-between text-[#0F594E] dark:text-[#5EEAD4]">
                <span>
                  {tr(lang, 'savingsApplied')} ({pricing.discountPercent}%)
                </span>
                <span className="font-mono-num font-semibold">
                  -PKR {pricing.savingsPerVisit.toLocaleString()} / visit
                </span>
              </div>
            )}
            {cadence !== 'one_time' && (
              <div className="flex justify-between text-slate-600 dark:text-slate-400">
                <span>
                  {tr(lang, 'estMonthly')} ({pricing.estimatedMonthlyVisits} visits)
                </span>
                <span className="font-mono-num font-semibold text-slate-900 dark:text-white">
                  PKR {pricing.estimatedMonthlyTotal.toLocaleString()}
                </span>
              </div>
            )}
          </div>
        </div>

        <div className="p-4 sm:p-6 pb-safe border-t border-slate-100 dark:border-slate-800 flex items-center justify-end gap-2.5 shrink-0 bg-white dark:bg-[#141C1E]">
          <button
            type="button"
            onClick={onClose}
            className="min-h-[48px] px-4 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            {lang === 'ur' ? 'منسوخ' : 'Cancel'}
          </button>
          <button
            type="submit"
            disabled={conflict.hasConflict}
            className="flex-1 sm:flex-initial min-h-[48px] px-6 rounded-xl text-sm font-semibold bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E] disabled:opacity-45 disabled:cursor-not-allowed active:scale-[0.98] transition-all"
          >
            {tr(lang, 'confirmBooking')}
          </button>
        </div>
      </form>
    </div>
  );
};

interface HouseholdPostJobViewProps {
  currentUser: AppUser;
  jobPosts: JobPost[];
  applications: JobApplication[];
  lang: LanguageCode;
  onCreateJobPost: (job: Omit<JobPost, 'id' | 'createdAt' | 'status'>) => void;
  onAcceptProposal: (application: JobApplication, job: JobPost) => void;
}

export const HouseholdPostJobView: React.FC<HouseholdPostJobViewProps> = ({
  currentUser,
  jobPosts,
  applications,
  lang,
  onCreateJobPost,
  onAcceptProposal,
}) => {
  const [title, setTitle] = useState('');
  const [category, setCategory] = useState<string>('Cook');
  const [area, setArea] = useState<string>(currentUser.area || 'Mandian');
  const [budget, setBudget] = useState<string>('3000');
  const [requiredDate, setRequiredDate] = useState(
    new Date(Date.now() + 2 * 86400 * 1000).toISOString().split('T')[0]
  );
  const [description, setDescription] = useState('');

  const myJobs = useMemo(
    () => jobPosts.filter((j) => j.householdId === currentUser.id),
    [jobPosts, currentUser.id]
  );

  const handlePublish = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !description.trim()) return;
    const coords = LOCALITY_COORDINATES[area] ?? LOCALITY_COORDINATES.Mandian;

    onCreateJobPost({
      householdId: currentUser.id,
      householdName: currentUser.fullName,
      title: title.trim(),
      serviceCategory: category,
      description: description.trim(),
      city: 'Abbottabad',
      area,
      latitude: coords.lat,
      longitude: coords.lon,
      budget: Math.max(500, parseInt(budget, 10) || 2500),
      requiredDate,
    });

    setTitle('');
    setDescription('');
  };

  return (
    <div className="space-y-8">
      <div className="pb-5 border-b border-slate-200 dark:border-slate-800">
        <h1 className="font-display text-3xl font-semibold text-slate-900 dark:text-white">
          {tr(lang, 'postGigTitle')}
        </h1>
        <p className="mt-1.5 text-sm text-slate-600 dark:text-slate-400">
          {lang === 'ur'
            ? 'اپنی گھریلو ضرورت شائع کریں اور ایبٹ آباد کے تصدیق شدہ ورکرز کی تجاویز کا موازنہ کریں۔'
            : 'Describe your household need and compare proposals from verified Abbottabad specialists.'}
        </p>
      </div>

      <div className="grid lg:grid-cols-12 gap-8 items-start">
        {/* Publish Job Form */}
        <form
          onSubmit={handlePublish}
          className="lg:col-span-5 rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-6 space-y-4"
        >
          <h2 className="font-display text-xl font-semibold text-slate-900 dark:text-white">
            {tr(lang, 'postAJob')}
          </h2>

          <div>
            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
              {tr(lang, 'jobTitle')}
            </label>
            <input
              type="text"
              required
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder={
                lang === 'ur' ? 'مثلاً فیملی ڈنر کے لیے باورچی' : 'e.g. Weekend Deep Kitchen Cleaning'
              }
              className="w-full px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm text-slate-900 dark:text-slate-100"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {tr(lang, 'selectCategory')}
              </label>
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="w-full px-3 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm text-slate-900 dark:text-slate-100"
              >
                {SERVICE_CATEGORIES.filter((c) => c !== 'All').map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {tr(lang, 'selectArea')}
              </label>
              <select
                value={area}
                onChange={(e) => setArea(e.target.value)}
                className="w-full px-3 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm text-slate-900 dark:text-slate-100"
              >
                {ABBOTTABAD_AREAS.map((a) => (
                  <option key={a} value={a}>
                    {a}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {tr(lang, 'budget')}
              </label>
              <input
                type="number"
                min={500}
                step={100}
                required
                value={budget}
                onChange={(e) => setBudget(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm font-mono-num text-slate-900 dark:text-slate-100"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {lang === 'ur' ? 'مطلوبہ تاریخ' : 'Required Date'}
              </label>
              <input
                type="date"
                required
                value={requiredDate}
                onChange={(e) => setRequiredDate(e.target.value)}
                className="w-full px-3 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm font-mono-num text-slate-900 dark:text-slate-100"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
              {lang === 'ur' ? 'تفصیلات' : 'Scope & Expectations'}
            </label>
            <textarea
              rows={3}
              required
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder={
                lang === 'ur'
                  ? 'کام کی نوعیت، اوقات کار اور ضروری معلومات لکھیں...'
                  : 'Outline number of rooms, meal count, or special care requirements...'
              }
              className="w-full px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#0F1618] border border-slate-200 dark:border-slate-800 text-sm text-slate-900 dark:text-slate-100"
            />
          </div>

          <button
            type="submit"
            className="w-full py-2.5 px-4 rounded-xl bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E] text-sm font-semibold inline-flex items-center justify-center gap-2 transition-colors"
          >
            <Plus className="w-4 h-4" />
            {tr(lang, 'submitPost')}
          </button>
        </form>

        {/* Active Posted Jobs & Bids */}
        <div className="lg:col-span-7 space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-semibold text-slate-900 dark:text-white">
              {tr(lang, 'proposalsReceived')}
            </h2>
            <span className="font-mono-num text-xs text-slate-500 dark:text-slate-400">
              {myJobs.length} {lang === 'ur' ? 'پوسٹس' : 'posts'}
            </span>
          </div>

          {myJobs.length === 0 ? (
            <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-10 text-center text-sm text-slate-500 dark:text-slate-400">
              {lang === 'ur'
                ? 'آپ نے ابھی تک کوئی کام پوسٹ نہیں کیا۔'
                : 'You have not posted any household jobs yet.'}
            </div>
          ) : (
            myJobs.map((job) => {
              const jobApps = applications.filter((a) => a.jobPostId === job.id);
              return (
                <article
                  key={job.id}
                  className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-5 space-y-4"
                >
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <h3 className="font-display text-lg font-semibold text-slate-900 dark:text-white">
                        {job.title}
                      </h3>
                      <p className="mt-0.5 text-xs text-slate-500 dark:text-slate-400">
                        {job.serviceCategory} · {job.area} ·{' '}
                        <span className="font-mono-num">{job.requiredDate}</span> ·{' '}
                        <span className="capitalize font-medium text-[#0F594E] dark:text-[#5EEAD4]">
                          {job.status}
                        </span>
                      </p>
                    </div>
                    <span className="font-mono-num text-sm font-semibold text-slate-900 dark:text-white shrink-0">
                      PKR {job.budget.toLocaleString()}
                    </span>
                  </div>

                  <p className="text-sm text-slate-600 dark:text-slate-300 leading-relaxed">
                    {job.description}
                  </p>

                  {/* Proposals Divider List (single elevation) */}
                  <div className="pt-3 border-t border-slate-100 dark:border-slate-800 space-y-3">
                    <div className="flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
                      <span className="font-semibold">
                        {tr(lang, 'proposalsReceived')} ({jobApps.length})
                      </span>
                      <span className="inline-flex items-center gap-1">
                        <Calendar className="w-3.5 h-3.5" />
                        {job.requiredDate}
                      </span>
                    </div>

                    {jobApps.length === 0 ? (
                      <p className="text-xs text-slate-400 dark:text-slate-500">
                        {lang === 'ur'
                          ? 'ورکرز کی تجاویز کا انتظار ہے...'
                          : 'Awaiting worker proposals...'}
                      </p>
                    ) : (
                      <div className="divide-y divide-slate-100 dark:divide-slate-800">
                        {jobApps.map((app) => (
                          <div
                            key={app.id}
                            className="py-3 first:pt-0 last:pb-0 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
                          >
                            <div className="min-w-0">
                              <p className="text-sm font-semibold text-slate-900 dark:text-white">
                                {app.workerName}{' '}
                                <span className="font-normal text-xs text-slate-500 dark:text-slate-400 font-mono-num">
                                  · ★ {app.workerRating.toFixed(1)} · PKR{' '}
                                  {app.proposedRate.toLocaleString()}
                                </span>
                              </p>
                              <p className="mt-0.5 text-xs text-slate-600 dark:text-slate-300">
                                {app.notes}
                              </p>
                            </div>

                            {job.status === 'open' && app.status === 'pending' ? (
                              <button
                                type="button"
                                onClick={() => onAcceptProposal(app, job)}
                                className="px-3.5 py-2 rounded-lg text-xs font-semibold bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E] shrink-0 transition-colors"
                              >
                                {tr(lang, 'acceptProposal')}
                              </button>
                            ) : (
                              <span className="text-xs font-semibold capitalize text-slate-500 dark:text-slate-400 shrink-0">
                                <Clock className="w-3.5 h-3.5 inline me-1" />
                                {app.status}
                              </span>
                            )}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </article>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
};
