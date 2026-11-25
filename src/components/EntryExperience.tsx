import React, { useEffect, useState } from 'react';
import {
  ArrowLeft,
  ArrowRight,
  CalendarClock,
  Check,
  Globe,
  Home,
  MapPin,
  Moon,
  ShieldCheck,
  Sun,
} from 'lucide-react';
import { EDITORIAL_ASSETS } from '../data/sampleData';
import { tr } from '../services/localization';
import { LanguageCode, ThemeMode } from '../types';

interface SplashScreenProps {
  lang: LanguageCode;
  onComplete: () => void;
}

export const SplashScreen: React.FC<SplashScreenProps> = ({ lang, onComplete }) => {
  useEffect(() => {
    const timer = window.setTimeout(() => {
      onComplete();
    }, 1350);
    return () => window.clearTimeout(timer);
  }, [onComplete]);

  return (
    <div
      onClick={onComplete}
      role="button"
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') onComplete();
      }}
      className="min-h-[100dvh] w-full flex flex-col items-center justify-center bg-[#0B3B34] dark:bg-[#071917] text-white px-6 pb-safe pt-safe cursor-pointer select-none"
    >
      <div className="flex flex-col items-center max-w-sm text-center animate-fade-up">
        <div className="w-16 h-16 rounded-2xl bg-white/10 border border-white/15 flex items-center justify-center mb-6 shadow-lg">
          <Home className="w-8 h-8 text-[#5EEAD4]" strokeWidth={1.75} />
        </div>
        <h1 className="font-display text-4xl sm:text-5xl font-semibold tracking-tight text-white">
          {tr(lang, 'appTitle')}
        </h1>
        <p className="mt-3 text-sm text-teal-100/80 tracking-wide">
          {tr(lang, 'splashSubtitle')}
        </p>

        <div className="mt-8 w-44 h-[2px] bg-white/15 rounded-full overflow-hidden">
          <div className="h-full w-full bg-[#5EEAD4] animate-splash-bar" />
        </div>
      </div>
    </div>
  );
};

interface OnboardingScreenProps {
  lang: LanguageCode;
  theme: ThemeMode;
  onToggleLang: () => void;
  onToggleTheme: () => void;
  onFinish: () => void;
}

export const OnboardingScreen: React.FC<OnboardingScreenProps> = ({
  lang,
  theme,
  onToggleLang,
  onToggleTheme,
  onFinish,
}) => {
  const [step, setStep] = useState(0);
  const isRtl = lang === 'ur';

  const slides = [
    {
      indexLabel: '01 / 03',
      title: tr(lang, 'onboardingStep1Title'),
      body: tr(lang, 'onboardingStep1Body'),
      image: EDITORIAL_ASSETS.heroHome,
      imageAlt: 'Sunlit Abbottabad family living room overlooking Himalayan pines',
      highlights:
        lang === 'ur'
          ? ['نادرا CNIC تصدیق شدہ پروفائلز', 'ایبٹ آباد کے 5 مرکزی محلے', 'تصدیق شدہ صارفین کے جائزے']
          : ['NADRA CNIC-vetted specialists', 'All 5 core Abbottabad neighborhoods', 'Verified household reviews'],
      icon: ShieldCheck,
    },
    {
      indexLabel: '02 / 03',
      title: tr(lang, 'onboardingStep2Title'),
      body: tr(lang, 'onboardingStep2Body'),
      image: EDITORIAL_ASSETS.portraitCook,
      imageAlt: 'Verified Abbottabad domestic cook portrait',
      highlights:
        lang === 'ur'
          ? ['مہارت اور فاصلے کا شفاف اسکور', 'ایبٹ آباد انٹرایکٹو گوگل نقشہ', 'فوری بکنگ یا کام پوسٹ کریں']
          : ['Explainable skill & Haversine match score', 'Interactive Abbottabad Google Map', 'Direct booking or open household bids'],
      icon: MapPin,
    },
    {
      indexLabel: '03 / 03',
      title: tr(lang, 'onboardingStep3Title'),
      body: tr(lang, 'onboardingStep3Body'),
      image: EDITORIAL_ASSETS.portraitNanny,
      imageAlt: 'Verified Abbottabad caregiver and nanny portrait',
      highlights:
        lang === 'ur'
          ? ['ہفتہ وار اور ماہانہ پلان پر 15% تک بچت', '4 ہندسوں کا آمد کوڈ اور لائیو ٹائمر', 'محفوظ چیک ان اور ایسکرو ادائیگی']
          : ['Save up to 15% on weekly & monthly plans', '4-digit Arrival OTP & live job timer', 'Safety check-ins & Escrow settlement'],
      icon: CalendarClock,
    },
  ];

  const current = slides[step];
  const Icon = current.icon;

  return (
    <div
      dir={isRtl ? 'rtl' : 'ltr'}
      className="min-h-[100dvh] bg-[#FAFBF9] dark:bg-[#0B1011] text-[#0F172A] dark:text-[#F1F5F9] flex flex-col pt-safe"
    >
      {/* Compact Mobile-Friendly Top Bar */}
      <header className="w-full max-w-6xl mx-auto px-4 sm:px-6 h-14 sm:h-16 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E] flex items-center justify-center">
            <Home className="w-4 h-4" strokeWidth={2} />
          </div>
          <span className="font-display text-lg sm:text-xl font-semibold tracking-tight">
            {tr(lang, 'appTitle')}
          </span>
        </div>

        <div className="flex items-center gap-1.5">
          <button
            type="button"
            onClick={onToggleLang}
            className="inline-flex items-center justify-center gap-1.5 min-h-[40px] px-3 rounded-xl text-xs font-semibold text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800 active:scale-[0.98] transition-all"
          >
            <Globe className="w-3.5 h-3.5" />
            {tr(lang, 'languageToggle')}
          </button>
          <button
            type="button"
            onClick={onToggleTheme}
            aria-label={theme === 'dark' ? tr(lang, 'themeLight') : tr(lang, 'themeDark')}
            className="min-h-[40px] min-w-[40px] flex items-center justify-center rounded-xl text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800 active:scale-[0.98] transition-all"
          >
            {theme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
          </button>
          <button
            type="button"
            onClick={onFinish}
            className="min-h-[40px] px-2.5 text-xs font-semibold text-slate-500 dark:text-slate-400 hover:text-[#0F594E] dark:hover:text-[#5EEAD4] transition-colors"
          >
            {tr(lang, 'skipIntro')}
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 w-full max-w-6xl mx-auto px-4 sm:px-6 pt-2 pb-6 lg:py-10 flex flex-col lg:justify-center">
        <div
          key={step}
          className="w-full flex-1 lg:flex-initial grid lg:grid-cols-12 gap-6 lg:gap-14 items-start lg:items-center animate-fade-up"
        >
          {/* Visual */}
          <div className="lg:col-span-6">
            <div className="relative rounded-2xl overflow-hidden border border-slate-200 dark:border-slate-800 bg-slate-100 dark:bg-slate-900 aspect-[16/10] sm:aspect-[4/3]">
              <img
                src={current.image}
                alt={current.imageAlt}
                referrerPolicy="no-referrer"
                className="w-full h-full object-cover object-center"
              />
              <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-slate-950/80 via-slate-950/35 to-transparent p-4 sm:p-6">
                <div className="flex items-center justify-between text-white">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-lg bg-white/15 backdrop-blur-sm flex items-center justify-center">
                      <Icon className="w-4 h-4 text-[#5EEAD4]" />
                    </div>
                    <span className="text-xs font-medium text-slate-100">
                      {lang === 'ur' ? 'ایبٹ آباد · خیبر پختونخوا' : 'Abbottabad · Khyber Pakhtunkhwa'}
                    </span>
                  </div>
                  <span className="font-mono-num text-xs text-teal-200">
                    {current.indexLabel}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Copy + Thumb-Zone Controls */}
          <div className="lg:col-span-6 flex flex-col flex-1 justify-between">
            <div>
              <span className="font-mono-num text-xs font-semibold uppercase tracking-[0.16em] text-[#0F594E] dark:text-[#5EEAD4]">
                {current.indexLabel}
              </span>

              <h2 className="mt-2 font-display text-2xl sm:text-4xl font-semibold tracking-tight text-slate-900 dark:text-white leading-tight">
                {current.title}
              </h2>

              <p className="mt-3 text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed">
                {current.body}
              </p>

              <ul className="mt-5 space-y-2.5 border-t border-slate-200 dark:border-slate-800 pt-4">
                {current.highlights.map((item) => (
                  <li
                    key={item}
                    className="flex items-start gap-2.5 text-sm font-medium text-slate-700 dark:text-slate-200"
                  >
                    <Check className="w-4 h-4 mt-0.5 shrink-0 text-[#0F594E] dark:text-[#14B8A6]" />
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </div>

            {/* Bottom Thumb-Zone Controls */}
            <div className="mt-8 pb-safe flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div className="flex items-center justify-center sm:justify-start gap-2">
                {slides.map((_, idx) => (
                  <button
                    key={idx}
                    type="button"
                    aria-label={`Slide ${idx + 1}`}
                    onClick={() => setStep(idx)}
                    className="py-2 px-1"
                  >
                    <span
                      className={`block h-1.5 rounded-full transition-all ${
                        idx === step
                          ? 'w-8 bg-[#0F594E] dark:bg-[#14B8A6]'
                          : 'w-2 bg-slate-300 dark:bg-slate-700'
                      }`}
                    />
                  </button>
                ))}
              </div>

              <div className="flex items-center gap-2.5 w-full sm:w-auto">
                {step > 0 && (
                  <button
                    type="button"
                    onClick={() => setStep((s) => Math.max(0, s - 1))}
                    className="flex-1 sm:flex-initial min-h-[48px] inline-flex items-center justify-center gap-1.5 px-4 rounded-xl text-sm font-semibold text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800 active:scale-[0.98] transition-all"
                  >
                    {isRtl ? <ArrowRight className="w-4 h-4" /> : <ArrowLeft className="w-4 h-4" />}
                    {tr(lang, 'back')}
                  </button>
                )}

                {step < slides.length - 1 ? (
                  <button
                    type="button"
                    onClick={() => setStep((s) => Math.min(slides.length - 1, s + 1))}
                    className="flex-1 sm:flex-initial min-h-[48px] inline-flex items-center justify-center gap-2 px-6 rounded-xl text-sm font-semibold bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E] active:scale-[0.98] transition-all"
                  >
                    {tr(lang, 'next')}
                    {isRtl ? <ArrowLeft className="w-4 h-4" /> : <ArrowRight className="w-4 h-4" />}
                  </button>
                ) : (
                  <button
                    type="button"
                    onClick={onFinish}
                    className="flex-1 sm:flex-initial min-h-[48px] inline-flex items-center justify-center gap-2 px-6 rounded-xl text-sm font-semibold bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E] active:scale-[0.98] transition-all"
                  >
                    {tr(lang, 'getStarted')}
                    {isRtl ? <ArrowLeft className="w-4 h-4" /> : <ArrowRight className="w-4 h-4" />}
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};
