import React, { useState } from 'react';
import {
  ArrowRight,
  Briefcase,
  Globe,
  Home,
  Moon,
  RotateCcw,
  Shield,
  Sun,
  UserCheck,
} from 'lucide-react';
import { ABBOTTABAD_AREAS, DEMO_ACCOUNTS, EDITORIAL_ASSETS } from '../data/sampleData';
import { tr } from '../services/localization';
import { AppUser, LanguageCode, ThemeMode, UserRole } from '../types';

interface AuthScreenProps {
  lang: LanguageCode;
  theme: ThemeMode;
  onToggleLang: () => void;
  onToggleTheme: () => void;
  onReplayOnboarding: () => void;
  onLogin: (user: AppUser) => void;
}

export const AuthScreen: React.FC<AuthScreenProps> = ({
  lang,
  theme,
  onToggleLang,
  onToggleTheme,
  onReplayOnboarding,
  onLogin,
}) => {
  const [mode, setMode] = useState<'login' | 'signup'>('login');
  const [selectedRole, setSelectedRole] = useState<UserRole>('Household');
  const [email, setEmail] = useState(DEMO_ACCOUNTS.Household.email);
  const [password, setPassword] = useState(DEMO_ACCOUNTS.Household.password);
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [area, setArea] = useState<string>('Mandian');
  const [error, setError] = useState<string | null>(null);

  const isRtl = lang === 'ur';

  const handleRolePreset = (role: UserRole) => {
    setSelectedRole(role);
    setEmail(DEMO_ACCOUNTS[role].email);
    setPassword(DEMO_ACCOUNTS[role].password);
    setError(null);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!email.trim() || !password.trim()) {
      setError(
        lang === 'ur'
          ? 'براہ کرم ای میل اور پاس ورڈ درج کریں۔'
          : 'Please enter both email address and password.'
      );
      return;
    }

    if (mode === 'login') {
      const normalized = email.trim().toLowerCase();
      const matched = Object.values(DEMO_ACCOUNTS).find(
        (acc) => acc.email.toLowerCase() === normalized
      );

      if (matched) {
        onLogin({
          id: matched.id,
          fullName: matched.fullName,
          email: matched.email,
          phone: matched.phone,
          role: matched.role,
          area: matched.area,
        });
        return;
      }

      onLogin({
        id: `usr_${Date.now()}`,
        fullName: email.split('@')[0].replace(/[._]/g, ' '),
        email: email.trim(),
        phone: '0300-0000000',
        role: selectedRole,
        area,
      });
    } else {
      if (!fullName.trim()) {
        setError(lang === 'ur' ? 'براہ کرم اپنا مکمل نام درج کریں۔' : 'Please enter your full name.');
        return;
      }
      onLogin({
        id: selectedRole === 'Worker' ? 'worker_1' : `usr_${Date.now()}`,
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim() || '0300-5123456',
        role: selectedRole,
        area,
      });
    }
  };

  const handleQuickDemo = (role: UserRole) => {
    const acc = DEMO_ACCOUNTS[role];
    onLogin({
      id: acc.id,
      fullName: acc.fullName,
      email: acc.email,
      phone: acc.phone,
      role: acc.role,
      area: acc.area,
    });
  };

  return (
    <div
      dir={isRtl ? 'rtl' : 'ltr'}
      className="min-h-[100dvh] bg-[#FAFBF9] dark:bg-[#0B1011] text-[#0F172A] dark:text-[#F1F5F9] grid lg:grid-cols-12"
    >
      {/* Left Editorial Photography & Trust Proof */}
      <div className="hidden lg:flex lg:col-span-6 relative bg-[#0B3B34] text-white overflow-hidden">
        <img
          src={EDITORIAL_ASSETS.heroHome}
          alt="Abbottabad residence overlooking pine hills"
          referrerPolicy="no-referrer"
          className="absolute inset-0 w-full h-full object-cover opacity-50"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-[#07241F] via-[#0B3B34]/75 to-[#0B3B34]/45" />

        <div className="relative z-10 flex flex-col justify-between p-12 w-full">
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-lg bg-white/15 backdrop-blur-sm flex items-center justify-center">
              <Home className="w-5 h-5 text-[#5EEAD4]" />
            </div>
            <span className="font-display text-2xl font-semibold tracking-tight">
              {tr(lang, 'appTitle')}
            </span>
          </div>

          <div className="max-w-md">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#5EEAD4]">
              {lang === 'ur' ? 'ایبٹ آباد کا بااعتماد پلیٹ فارم' : 'Abbottabad · Domestic Care Marketplace'}
            </p>
            <h1 className="mt-3 font-display text-4xl font-semibold leading-tight text-white">
              {lang === 'ur'
                ? 'آپ کے گھر کے لیے تصدیق شدہ، باوقار اور محفوظ خدمات۔'
                : 'Verified domestic care built for Abbottabad households.'}
            </h1>
            <p className="mt-4 text-sm text-teal-100/85 leading-relaxed">
              {lang === 'ur'
                ? 'نادرا شناختی تصدیق، لائیو ایبٹ آباد نقشہ، ہفتہ وار پلانز اور محفوظ ایسکرو ادائیگی — سب ایک شفاف پلیٹ فارم پر۔'
                : 'NADRA CNIC identity checks, interactive neighborhood discovery, recurring household plans, arrival OTP timers, and escrow protection.'}
            </p>

            <div className="mt-8 pt-6 border-t border-white/15 grid grid-cols-3 gap-6">
              <div>
                <p className="font-mono-num text-2xl font-semibold text-white">100%</p>
                <p className="mt-1 text-xs text-teal-100/75">
                  {lang === 'ur' ? 'شناختی تصدیق' : 'CNIC Vetted'}
                </p>
              </div>
              <div>
                <p className="font-mono-num text-2xl font-semibold text-white">5</p>
                <p className="mt-1 text-xs text-teal-100/75">
                  {lang === 'ur' ? 'ایبٹ آباد علاقے' : 'Localities'}
                </p>
              </div>
              <div>
                <p className="font-mono-num text-2xl font-semibold text-white">4.8★</p>
                <p className="mt-1 text-xs text-teal-100/75">
                  {lang === 'ur' ? 'اوسط درجہ بندی' : 'Avg Rating'}
                </p>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-3 text-xs text-teal-100/75">
            <span>Mandian</span>
            <span>·</span>
            <span>Jhangi Syedan</span>
            <span>·</span>
            <span>Supply Bazaar</span>
            <span>·</span>
            <span>Nawan Shehr</span>
            <span>·</span>
            <span>PMA Kakul Rd</span>
          </div>
        </div>
      </div>

      {/* Right Authentication Workspace */}
      <div className="lg:col-span-6 flex flex-col justify-between px-4 py-4 sm:px-12 sm:py-6 lg:px-16 pt-safe pb-safe">
        {/* Utility bar */}
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2 lg:hidden">
            <div className="w-8 h-8 rounded-lg bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E] flex items-center justify-center">
              <Home className="w-4 h-4" />
            </div>
            <span className="font-display text-lg font-semibold">{tr(lang, 'appTitle')}</span>
          </div>
          <div className="hidden lg:block" />

          <div className="flex items-center gap-1.5">
            <button
              type="button"
              onClick={onReplayOnboarding}
              className="inline-flex items-center justify-center gap-1.5 min-h-[40px] px-2.5 rounded-xl text-xs font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">{tr(lang, 'replayIntro')}</span>
            </button>
            <button
              type="button"
              onClick={onToggleLang}
              className="inline-flex items-center justify-center gap-1.5 min-h-[40px] px-3 rounded-xl text-xs font-semibold text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
            >
              <Globe className="w-3.5 h-3.5" />
              {tr(lang, 'languageToggle')}
            </button>
            <button
              type="button"
              onClick={onToggleTheme}
              aria-label={theme === 'dark' ? tr(lang, 'themeLight') : tr(lang, 'themeDark')}
              className="min-h-[40px] min-w-[40px] flex items-center justify-center rounded-xl text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
            >
              {theme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </button>
          </div>
        </div>

        {/* Form Container */}
        <div className="w-full max-w-md mx-auto my-6">
          <h2 className="font-display text-2xl sm:text-3xl font-semibold tracking-tight text-slate-900 dark:text-white">
            {mode === 'login' ? tr(lang, 'welcomeBack') : tr(lang, 'createAccount')}
          </h2>
          <p className="mt-1.5 text-sm text-slate-500 dark:text-slate-400">
            {tr(lang, 'signInSubtitle')}
          </p>

          {/* Mode Tabs */}
          <div className="mt-5 flex border-b border-slate-200 dark:border-slate-800">
            <button
              type="button"
              onClick={() => {
                setMode('login');
                setError(null);
              }}
              className={`min-h-[44px] px-1 me-6 text-sm font-semibold border-b-2 transition-colors ${
                mode === 'login'
                  ? 'border-[#0F594E] dark:border-[#14B8A6] text-[#0F594E] dark:text-[#5EEAD4]'
                  : 'border-transparent text-slate-500 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200'
              }`}
            >
              {tr(lang, 'signIn')}
            </button>
            <button
              type="button"
              onClick={() => {
                setMode('signup');
                setError(null);
              }}
              className={`min-h-[44px] px-1 text-sm font-semibold border-b-2 transition-colors ${
                mode === 'signup'
                  ? 'border-[#0F594E] dark:border-[#14B8A6] text-[#0F594E] dark:text-[#5EEAD4]'
                  : 'border-transparent text-slate-500 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200'
              }`}
            >
              {tr(lang, 'createAccount')}
            </button>
          </div>

          {/* Role Selector */}
          <div className="mt-4 grid grid-cols-3 gap-2">
            {(
              [
                { role: 'Household' as UserRole, label: tr(lang, 'householdRole'), icon: Home },
                { role: 'Worker' as UserRole, label: tr(lang, 'workerRole'), icon: Briefcase },
                { role: 'Admin' as UserRole, label: tr(lang, 'adminRole'), icon: Shield },
              ] as const
            ).map(({ role, label, icon: RoleIcon }) => {
              const active = selectedRole === role;
              return (
                <button
                  key={role}
                  type="button"
                  onClick={() => handleRolePreset(role)}
                  className={`min-h-[44px] flex items-center justify-center gap-1.5 px-2.5 rounded-xl text-xs font-semibold border active:scale-[0.98] transition-all ${
                    active
                      ? 'bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E] border-[#0F594E] dark:border-[#14B8A6]'
                      : 'bg-white dark:bg-[#141C1E] text-slate-700 dark:text-slate-300 border-slate-200 dark:border-slate-800 hover:border-slate-300 dark:hover:border-slate-700'
                  }`}
                >
                  <RoleIcon className="w-3.5 h-3.5 shrink-0" />
                  <span className="truncate">{label}</span>
                </button>
              );
            })}
          </div>

          <form onSubmit={handleSubmit} className="mt-4 space-y-3.5">
            {mode === 'signup' && (
              <>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                    {tr(lang, 'fullName')}
                  </label>
                  <input
                    type="text"
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    placeholder="e.g. Babar Khan"
                    className="w-full min-h-[46px] px-3.5 rounded-xl bg-white dark:bg-[#141C1E] border border-slate-200 dark:border-slate-800 text-base sm:text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-[#0F594E]/25 dark:focus:ring-[#14B8A6]/30 focus:border-[#0F594E] dark:focus:border-[#14B8A6]"
                  />
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                      {tr(lang, 'phoneNumber')}
                    </label>
                    <input
                      type="tel"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      placeholder="0300-5123456"
                      className="w-full min-h-[46px] px-3.5 rounded-xl bg-white dark:bg-[#141C1E] border border-slate-200 dark:border-slate-800 text-base sm:text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-[#0F594E]/25 focus:border-[#0F594E]"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                      {tr(lang, 'selectArea')}
                    </label>
                    <select
                      value={area}
                      onChange={(e) => setArea(e.target.value)}
                      className="w-full min-h-[46px] px-3.5 rounded-xl bg-white dark:bg-[#141C1E] border border-slate-200 dark:border-slate-800 text-base sm:text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-[#0F594E]/25 focus:border-[#0F594E]"
                    >
                      {ABBOTTABAD_AREAS.map((a) => (
                        <option key={a} value={a}>
                          {a}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              </>
            )}

            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {tr(lang, 'emailAddress')}
              </label>
              <input
                type="email"
                autoComplete="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="household@homeease.com"
                className="w-full min-h-[46px] px-3.5 rounded-xl bg-white dark:bg-[#141C1E] border border-slate-200 dark:border-slate-800 text-base sm:text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-[#0F594E]/25 dark:focus:ring-[#14B8A6]/30 focus:border-[#0F594E] dark:focus:border-[#14B8A6]"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                {tr(lang, 'password')}
              </label>
              <input
                type="password"
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full min-h-[46px] px-3.5 rounded-xl bg-white dark:bg-[#141C1E] border border-slate-200 dark:border-slate-800 text-base sm:text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-[#0F594E]/25 dark:focus:ring-[#14B8A6]/30 focus:border-[#0F594E] dark:focus:border-[#14B8A6]"
              />
            </div>

            {error && (
              <p className="text-xs font-medium text-red-600 dark:text-red-400">{error}</p>
            )}

            <button
              type="submit"
              className="w-full min-h-[48px] px-4 rounded-xl bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E] text-sm font-semibold flex items-center justify-center gap-2 active:scale-[0.98] transition-all"
            >
              <span>{mode === 'login' ? tr(lang, 'signIn') : tr(lang, 'createAccount')}</span>
              <ArrowRight className={`w-4 h-4 ${isRtl ? 'rotate-180' : ''}`} />
            </button>
          </form>

          {/* 1-Tap Demo Access */}
          <div className="mt-6 pt-5 border-t border-slate-200 dark:border-slate-800">
            <p className="text-xs font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500 mb-3">
              {tr(lang, 'instantDemoAccess')}
            </p>
            <div className="grid grid-cols-3 gap-2">
              {(['Household', 'Worker', 'Admin'] as UserRole[]).map((role) => (
                <button
                  key={role}
                  type="button"
                  onClick={() => handleQuickDemo(role)}
                  className="min-h-[56px] flex flex-col justify-center items-start p-3 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] hover:border-[#0F594E] dark:hover:border-[#14B8A6] active:scale-[0.98] transition-all text-start"
                >
                  <span className="inline-flex items-center gap-1 text-xs font-semibold text-slate-900 dark:text-slate-100">
                    <UserCheck className="w-3.5 h-3.5 text-[#0F594E] dark:text-[#14B8A6] shrink-0" />
                    <span className="truncate">
                      {role === 'Household'
                        ? tr(lang, 'householdRole')
                        : role === 'Worker'
                        ? tr(lang, 'workerRole')
                        : tr(lang, 'adminRole')}
                    </span>
                  </span>
                  <span className="mt-1 text-[11px] text-slate-500 dark:text-slate-400 truncate w-full">
                    {DEMO_ACCOUNTS[role].fullName}
                  </span>
                </button>
              ))}
            </div>
          </div>
        </div>

        <p className="text-center text-xs text-slate-400 dark:text-slate-500">
          {lang === 'ur'
            ? 'ہوم ایز · ایبٹ آباد گھریلو خدمات'
            : 'HomeEase · Verified Domestic Care for Abbottabad'}
        </p>
      </div>
    </div>
  );
};
