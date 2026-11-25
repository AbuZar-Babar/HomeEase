import React, { useMemo, useState } from 'react';
import {
  AlertOctagon,
  CheckCircle2,
  FileImage,
  Scale,
  ScrollText,
  ShieldCheck,
  TrendingUp,
  X,
} from 'lucide-react';
import { tr } from '../services/localization';
import {
  AuditLogEntry,
  Booking,
  Dispute,
  LanguageCode,
  SafetyAlert,
  WorkerProfile,
} from '../types';
import { WorkerAvatar } from './WorkerAvatar';

export type AdminTabId = 'overview' | 'verification' | 'disputes' | 'audit';

interface AdminDashboardProps {
  workers: WorkerProfile[];
  bookings: Booking[];
  disputes: Dispute[];
  auditLogs: AuditLogEntry[];
  safetyAlerts: SafetyAlert[];
  lang: LanguageCode;
  activeTab?: AdminTabId;
  onTabChange?: (tab: AdminTabId) => void;
  onApproveWorker: (workerId: string) => void;
  onRejectWorker: (workerId: string) => void;
  onResolveDispute: (
    disputeId: string,
    resolution: 'resolved_refund' | 'resolved_payout' | 'dismissed'
  ) => void;
  onUpdateSafetyAlert: (alertId: string, status: SafetyAlert['status']) => void;
}

export const AdminDashboard: React.FC<AdminDashboardProps> = ({
  workers,
  bookings,
  disputes,
  auditLogs,
  safetyAlerts,
  lang,
  activeTab: controlledTab,
  onTabChange,
  onApproveWorker,
  onRejectWorker,
  onResolveDispute,
  onUpdateSafetyAlert,
}) => {
  const [internalTab, setInternalTab] = useState<AdminTabId>('overview');
  const tab = controlledTab ?? internalTab;
  const setTab = (next: AdminTabId) => {
    setInternalTab(next);
    onTabChange?.(next);
  };
  const [lightboxImage, setLightboxImage] = useState<{ src: string; title: string } | null>(null);

  const grossVolume = useMemo(
    () => bookings.reduce((sum, b) => sum + b.agreedAmount, 0),
    [bookings]
  );
  const verifiedCount = useMemo(
    () => workers.filter((w) => w.verificationStatus === 'Verified').length,
    [workers]
  );
  const openDisputes = useMemo(
    () => disputes.filter((d) => d.status === 'open' || d.status === 'under_review'),
    [disputes]
  );
  const activeAlerts = useMemo(
    () => safetyAlerts.filter((a) => a.status !== 'resolved'),
    [safetyAlerts]
  );

  const localityBreakdown = useMemo(() => {
    const counts = new Map<string, number>();
    for (const w of workers) {
      counts.set(w.area, (counts.get(w.area) ?? 0) + 1);
    }
    return Array.from(counts.entries()).sort((a, b) => b[1] - a[1]);
  }, [workers]);

  return (
    <div className="space-y-8">
      {/* Header + Sub-nav */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 pb-5 border-b border-slate-200 dark:border-slate-800">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-[#0F594E] dark:text-[#5EEAD4]">
            Abbottabad Regional Operations
          </p>
          <h1 className="mt-1 font-display text-3xl font-semibold text-slate-900 dark:text-white">
            {tr(lang, 'adminDashboard')}
          </h1>
        </div>

        <div className="hidden md:flex items-center gap-1.5 overflow-x-auto no-scrollbar">
          {(
            [
              { id: 'overview', label: tr(lang, 'platformAnalytics'), icon: TrendingUp },
              { id: 'verification', label: tr(lang, 'workerVerificationDesk'), icon: ShieldCheck },
              { id: 'disputes', label: tr(lang, 'disputeResolutionDesk'), icon: Scale },
              { id: 'audit', label: tr(lang, 'systemAuditLogs'), icon: ScrollText },
            ] as const
          ).map((item) => {
            const Icon = item.icon;
            const active = tab === item.id;
            return (
              <button
                key={item.id}
                type="button"
                onClick={() => setTab(item.id)}
                className={`inline-flex items-center gap-1.5 px-3.5 py-2 rounded-lg text-xs font-semibold whitespace-nowrap shrink-0 transition-colors ${
                  active
                    ? 'bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E]'
                    : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
                }`}
              >
                <Icon className="w-3.5 h-3.5" />
                {item.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Urgent Emergency Safety Alerts Panel */}
      {activeAlerts.length > 0 && (
        <section className="rounded-2xl border border-red-300 dark:border-red-900 bg-red-50/70 dark:bg-red-950/30 p-5 space-y-3">
          <div className="flex items-center gap-2 text-red-700 dark:text-red-300">
            <AlertOctagon className="w-5 h-5" />
            <h2 className="text-sm font-semibold">
              {tr(lang, 'activeSafetyAlerts')} ({activeAlerts.length})
            </h2>
          </div>
          <div className="divide-y divide-red-200/70 dark:divide-red-900/60">
            {activeAlerts.map((alert) => (
              <div
                key={alert.id}
                className="py-3 first:pt-0 last:pb-0 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
              >
                <div className="text-xs text-red-900 dark:text-red-100 space-y-0.5">
                  <p className="font-semibold">
                    {alert.householdName} · Specialist: {alert.workerName} · #{alert.bookingId}
                  </p>
                  <p className="text-red-800/80 dark:text-red-200/80">
                    {alert.address} · Emergency Contact: {alert.emergencyContactName} (
                    <span className="font-mono-num">{alert.emergencyContactPhone}</span>)
                  </p>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  {alert.status === 'active' && (
                    <button
                      type="button"
                      onClick={() => onUpdateSafetyAlert(alert.id, 'acknowledged')}
                      className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-amber-600 hover:bg-amber-700 text-white"
                    >
                      {tr(lang, 'acknowledgeAlert')}
                    </button>
                  )}
                  <button
                    type="button"
                    onClick={() => onUpdateSafetyAlert(alert.id, 'resolved')}
                    className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-red-600 hover:bg-red-700 text-white"
                  >
                    {tr(lang, 'resolveAlert')}
                  </button>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Overview Tab */}
      {tab === 'overview' && (
        <div className="space-y-6">
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3.5 sm:gap-5">
            <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-5">
              <p className="text-xs text-slate-500 dark:text-slate-400">
                {tr(lang, 'grossPkrVolume')}
              </p>
              <p className="mt-2 font-mono-num text-2xl font-semibold text-slate-900 dark:text-white">
                PKR {grossVolume.toLocaleString()}
              </p>
            </div>
            <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-5">
              <p className="text-xs text-slate-500 dark:text-slate-400">
                {tr(lang, 'totalBookings')}
              </p>
              <p className="mt-2 font-mono-num text-2xl font-semibold text-slate-900 dark:text-white">
                {bookings.length}
              </p>
            </div>
            <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-5">
              <p className="text-xs text-slate-500 dark:text-slate-400">
                {tr(lang, 'verifiedWorkers')}
              </p>
              <p className="mt-2 font-mono-num text-2xl font-semibold text-[#0F594E] dark:text-[#5EEAD4]">
                {verifiedCount} / {workers.length}
              </p>
            </div>
            <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-5">
              <p className="text-xs text-slate-500 dark:text-slate-400">
                {tr(lang, 'activeDisputes')}
              </p>
              <p className="mt-2 font-mono-num text-2xl font-semibold text-amber-600 dark:text-amber-400">
                {openDisputes.length}
              </p>
            </div>
          </div>

          <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-6 space-y-4">
            <h2 className="font-display text-lg font-semibold text-slate-900 dark:text-white">
              {lang === 'ur'
                ? 'ایبٹ آباد محلہ وار ورکر کوریج'
                : 'Abbottabad Neighborhood Supply Distribution'}
            </h2>
            <div className="space-y-3">
              {localityBreakdown.map(([area, count]) => {
                const pct = Math.round((count / Math.max(1, workers.length)) * 100);
                return (
                  <div key={area}>
                    <div className="flex justify-between text-xs mb-1">
                      <span className="font-medium text-slate-700 dark:text-slate-300">{area}</span>
                      <span className="font-mono-num text-slate-500 dark:text-slate-400">
                        {count} specialists ({pct}%)
                      </span>
                    </div>
                    <div className="h-2 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                      <div
                        className="h-full rounded-full bg-[#0F594E] dark:bg-[#14B8A6]"
                        style={{ width: `${pct}%` }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* Worker Verification Desk (with Uploaded Document Previews) */}
      {tab === 'verification' && (
        <div className="divide-y divide-slate-100 dark:divide-slate-800 rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E]">
          {workers.map((worker) => (
            <div
              key={worker.id}
              className="p-5 flex flex-col lg:flex-row lg:items-center justify-between gap-5"
            >
              <div className="flex items-start gap-3.5 min-w-0">
                <WorkerAvatar
                  name={worker.name}
                  role={worker.role}
                  avatarUrl={worker.avatarUrl}
                  size="md"
                />
                <div className="min-w-0">
                  <div className="flex items-center gap-2">
                    <h3 className="font-semibold text-slate-900 dark:text-white">{worker.name}</h3>
                    <span
                      className={`text-xs font-semibold ${
                        worker.verificationStatus === 'Verified'
                          ? 'text-[#0F594E] dark:text-[#5EEAD4]'
                          : worker.verificationStatus === 'PendingVerification'
                          ? 'text-amber-600 dark:text-amber-400'
                          : 'text-red-600 dark:text-red-400'
                      }`}
                    >
                      · {worker.verificationStatus}
                    </span>
                  </div>
                  <p className="mt-0.5 text-xs text-slate-500 dark:text-slate-400">
                    {worker.role} · {worker.area} · CNIC{' '}
                    <span className="font-mono-num">{worker.cnic}</span> ·{' '}
                    <span className="font-mono-num">{worker.phone}</span>
                  </p>

                  {/* Document Previews synced from Worker Profile Builder */}
                  {(worker.cnicDocPreview || worker.policeCertPreview) && (
                    <div className="mt-3 flex flex-wrap items-center gap-3">
                      {worker.cnicDocPreview && (
                        <button
                          type="button"
                          onClick={() =>
                            setLightboxImage({
                              src: worker.cnicDocPreview!,
                              title: `${worker.name} — NADRA CNIC`,
                            })
                          }
                          className="inline-flex items-center gap-2 px-2.5 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700 hover:border-[#0F594E] text-xs font-medium text-slate-700 dark:text-slate-200"
                        >
                          <img
                            src={worker.cnicDocPreview}
                            alt="CNIC preview"
                            className="w-8 h-6 object-cover rounded"
                          />
                          <span>NADRA CNIC</span>
                        </button>
                      )}
                      {worker.policeCertPreview && (
                        <button
                          type="button"
                          onClick={() =>
                            setLightboxImage({
                              src: worker.policeCertPreview!,
                              title: `${worker.name} — Police Character Certificate`,
                            })
                          }
                          className="inline-flex items-center gap-2 px-2.5 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700 hover:border-[#0F594E] text-xs font-medium text-slate-700 dark:text-slate-200"
                        >
                          <img
                            src={worker.policeCertPreview}
                            alt="Police certificate preview"
                            className="w-8 h-6 object-cover rounded"
                          />
                          <span>Police Certificate</span>
                        </button>
                      )}
                    </div>
                  )}
                  {!worker.cnicDocPreview && !worker.policeCertPreview && (
                    <p className="mt-1.5 text-[11px] text-slate-400 inline-flex items-center gap-1">
                      <FileImage className="w-3.5 h-3.5" />
                      {lang === 'ur'
                        ? 'فزیکل ریکارڈ پر تصدیق شدہ'
                        : 'Physical credentials on file (upload previews in Worker Profile Builder)'}
                    </p>
                  )}
                </div>
              </div>

              <div className="flex items-center gap-2 shrink-0">
                {worker.verificationStatus !== 'Verified' && (
                  <button
                    type="button"
                    onClick={() => onApproveWorker(worker.id)}
                    className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-lg text-xs font-semibold bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E]"
                  >
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    {tr(lang, 'approveVerification')}
                  </button>
                )}
                {worker.verificationStatus !== 'RejectedVerification' && (
                  <button
                    type="button"
                    onClick={() => onRejectWorker(worker.id)}
                    className="px-3.5 py-2 rounded-lg text-xs font-semibold text-red-600 dark:text-red-400 border border-red-200 dark:border-red-900 hover:bg-red-50 dark:hover:bg-red-950/30"
                  >
                    {tr(lang, 'rejectVerification')}
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Disputes Tab */}
      {tab === 'disputes' && (
        <div className="divide-y divide-slate-100 dark:divide-slate-800 rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E]">
          {disputes.map((d) => (
            <div key={d.id} className="p-5 space-y-3">
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <p className="font-mono-num text-xs text-slate-400">
                    {d.id} · Booking #{d.bookingId}
                  </p>
                  <h3 className="font-semibold text-slate-900 dark:text-white mt-0.5">
                    {d.category} — {d.complainantName} vs {d.respondentName}
                  </h3>
                </div>
                <span className="text-xs font-semibold capitalize text-amber-700 dark:text-amber-400">
                  {d.status.replace('_', ' ')}
                </span>
              </div>
              <p className="text-sm text-slate-600 dark:text-slate-300">{d.description}</p>
              {(d.status === 'open' || d.status === 'under_review') && (
                <div className="pt-2 flex flex-wrap items-center gap-2">
                  <button
                    type="button"
                    onClick={() => onResolveDispute(d.id, 'resolved_refund')}
                    className="px-3.5 py-2 rounded-lg text-xs font-semibold bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E]"
                  >
                    {tr(lang, 'refundHousehold')}
                  </button>
                  <button
                    type="button"
                    onClick={() => onResolveDispute(d.id, 'resolved_payout')}
                    className="px-3.5 py-2 rounded-lg text-xs font-semibold text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800"
                  >
                    {tr(lang, 'releaseToWorker')}
                  </button>
                  <button
                    type="button"
                    onClick={() => onResolveDispute(d.id, 'dismissed')}
                    className="px-3.5 py-2 rounded-lg text-xs font-semibold text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
                  >
                    {tr(lang, 'dismissDispute')}
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* System Audit Logs Tab */}
      {tab === 'audit' && (
        <div className="divide-y divide-slate-100 dark:divide-slate-800 rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E]">
          {auditLogs.map((log) => (
            <div key={log.id} className="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-2">
              <div>
                <p className="text-sm font-semibold text-slate-900 dark:text-white">
                  {log.title}{' '}
                  <span
                    className={`text-xs font-medium ${
                      log.severity === 'danger'
                        ? 'text-red-600 dark:text-red-400'
                        : log.severity === 'warning'
                        ? 'text-amber-600 dark:text-amber-400'
                        : log.severity === 'success'
                        ? 'text-[#0F594E] dark:text-[#5EEAD4]'
                        : 'text-slate-400'
                    }`}
                  >
                    · {log.actionType}
                  </span>
                </p>
                <p className="mt-0.5 text-xs text-slate-600 dark:text-slate-300">
                  {log.description}
                </p>
              </div>
              <div className="text-xs text-slate-400 font-mono-num shrink-0 sm:text-end">
                <p>{log.actor}</p>
                <p>{new Date(log.timestamp).toLocaleString()}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Document Lightbox Modal */}
      {lightboxImage && (
        <div className="fixed inset-0 z-50 bg-slate-950/75 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="max-w-xl w-full rounded-2xl bg-white dark:bg-[#141C1E] border border-slate-200 dark:border-slate-800 overflow-hidden shadow-2xl">
            <div className="px-5 py-3.5 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
              <p className="text-sm font-semibold text-slate-900 dark:text-white">
                {lightboxImage.title}
              </p>
              <button
                type="button"
                onClick={() => setLightboxImage(null)}
                className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-4 bg-slate-50 dark:bg-[#0B1011]">
              <img
                src={lightboxImage.src}
                alt={lightboxImage.title}
                className="w-full max-h-[65vh] object-contain rounded-lg"
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
