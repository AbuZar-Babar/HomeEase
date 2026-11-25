import React, { useEffect, useState } from 'react';
import {
  APIProvider,
  AdvancedMarker,
  InfoWindow,
  Map as GoogleMap,
  useMap,
} from '@vis.gl/react-google-maps';
import { CheckCircle2, Compass, MapPin, Star } from 'lucide-react';
import { ABBOTTABAD_AREAS, ABBOTTABAD_CENTER, LOCALITY_COORDINATES } from '../data/sampleData';
import { tr } from '../services/localization';
import { AIRecommendationResult, LanguageCode, ThemeMode, WorkerProfile } from '../types';
import { WorkerAvatar } from './WorkerAvatar';

interface AbbottabadWorkerMapProps {
  recommendations: AIRecommendationResult[];
  selectedArea: string;
  onSelectArea: (area: string) => void;
  onSelectWorker: (worker: WorkerProfile) => void;
  onBookWorker: (worker: WorkerProfile) => void;
  lang: LanguageCode;
  theme: ThemeMode;
  quotaExceeded: boolean;
}

const MapViewportController: React.FC<{ center: { lat: number; lng: number } }> = ({ center }) => {
  const map = useMap();
  useEffect(() => {
    if (map) {
      map.panTo(center);
    }
  }, [map, center.lat, center.lng]);
  return null;
};

export const AbbottabadWorkerMap: React.FC<AbbottabadWorkerMapProps> = ({
  recommendations,
  selectedArea,
  onSelectArea,
  onSelectWorker,
  onBookWorker,
  lang,
  theme,
  quotaExceeded,
}) => {
  const apiKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY || '';
  const [activeId, setActiveId] = useState<string | null>(recommendations[0]?.worker.id ?? null);

  const activeRec =
    recommendations.find((r) => r.worker.id === activeId) ?? recommendations[0] ?? null;

  const targetCoords = LOCALITY_COORDINATES[selectedArea] ?? {
    lat: ABBOTTABAD_CENTER.lat,
    lon: ABBOTTABAD_CENTER.lng,
  };
  const mapCenter = { lat: targetCoords.lat, lng: targetCoords.lon };

  const useInteractiveFallback = !apiKey || quotaExceeded;

  // Map lat/lng into relative % coordinates for graceful fallback view when quota/key unavailable
  const projectToPercent = (lat: number, lon: number) => {
    const minLat = 34.148;
    const maxLat = 34.21;
    const minLon = 73.208;
    const maxLon = 73.278;
    const x = Math.max(8, Math.min(92, ((lon - minLon) / (maxLon - minLon)) * 100));
    const y = Math.max(10, Math.min(88, ((maxLat - lat) / (maxLat - minLat)) * 100));
    return { x, y };
  };

  return (
    <div className="space-y-4">
      {/* Locality quick-recenter horizontal strip */}
      <div className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar pb-0.5 flex-1">
          {ABBOTTABAD_AREAS.map((area) => {
            const active = selectedArea === area;
            return (
              <button
                key={area}
                type="button"
                onClick={() => onSelectArea(area)}
                className={`min-h-[40px] px-3.5 rounded-xl text-xs font-semibold whitespace-nowrap shrink-0 active:scale-[0.98] transition-all ${
                  active
                    ? 'bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E]'
                    : 'bg-white dark:bg-[#141C1E] text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-800 hover:border-slate-300 dark:hover:border-slate-700'
                }`}
              >
                {area}
              </button>
            );
          })}
        </div>
        <span className="hidden sm:inline text-xs text-slate-500 dark:text-slate-400 font-mono-num shrink-0">
          {recommendations.length}{' '}
          {lang === 'ur' ? 'ورکرز نقشے پر' : 'specialists mapped'}
        </span>
      </div>

      {/* Map + Selected Specialist Split */}
      <div className="grid lg:grid-cols-12 gap-5 items-start">
        <div className="lg:col-span-8 rounded-2xl overflow-hidden border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E]">
          {useInteractiveFallback ? (
            <div className="relative h-[360px] sm:h-[460px] lg:h-[520px] w-full bg-[#EEF3F0] dark:bg-[#0F1A1B] overflow-hidden select-none">
              {/* Subtle topographic grid */}
              <div
                className="absolute inset-0 opacity-35 dark:opacity-20"
                style={{
                  backgroundImage:
                    'linear-gradient(to right, rgba(15,89,78,0.18) 1px, transparent 1px), linear-gradient(to bottom, rgba(15,89,78,0.18) 1px, transparent 1px)',
                  backgroundSize: '48px 48px',
                }}
              />

              {/* Locality anchors */}
              {Object.entries(LOCALITY_COORDINATES).map(([name, coords]) => {
                const pos = projectToPercent(coords.lat, coords.lon);
                const isSelected = name === selectedArea;
                return (
                  <button
                    key={name}
                    type="button"
                    onClick={() => onSelectArea(name)}
                    style={{ left: `${pos.x}%`, top: `${pos.y}%` }}
                    className={`absolute -translate-x-1/2 -translate-y-1/2 text-[11px] font-semibold tracking-wide transition-colors ${
                      isSelected
                        ? 'text-[#0F594E] dark:text-[#5EEAD4]'
                        : 'text-slate-500/80 dark:text-slate-400/70 hover:text-slate-800 dark:hover:text-slate-200'
                    }`}
                  >
                    {name}
                  </button>
                );
              })}

              {/* Worker pins */}
              {recommendations.map((rec) => {
                const pos = projectToPercent(rec.worker.latitude, rec.worker.longitude);
                const isSelected = activeRec?.worker.id === rec.worker.id;
                return (
                  <button
                    key={rec.worker.id}
                    type="button"
                    onClick={() => setActiveId(rec.worker.id)}
                    style={{ left: `${pos.x}%`, top: `${pos.y}%` }}
                    className={`absolute -translate-x-1/2 -translate-y-1/2 flex items-center gap-1.5 p-1 pe-2.5 rounded-full shadow-md border transition-transform ${
                      isSelected
                        ? 'z-20 scale-110 bg-[#0F594E] text-white border-[#0F594E] dark:bg-[#14B8A6] dark:text-[#042F2E] dark:border-[#14B8A6]'
                        : 'z-10 bg-white dark:bg-[#141C1E] text-slate-900 dark:text-slate-100 border-slate-200 dark:border-slate-700 hover:scale-105'
                    }`}
                  >
                    <WorkerAvatar
                      name={rec.worker.name}
                      role={rec.worker.role}
                      avatarUrl={rec.worker.avatarUrl}
                      size="xs"
                    />
                    <span className="text-xs font-semibold font-mono-num whitespace-nowrap">
                      {rec.matchPercentage}%
                    </span>
                  </button>
                );
              })}

              <div className="absolute bottom-3 inset-x-3 flex items-center justify-between px-3.5 py-2 rounded-xl bg-white/90 dark:bg-[#141C1E]/90 backdrop-blur-sm border border-slate-200 dark:border-slate-800 text-[11px] text-slate-600 dark:text-slate-300">
                <span className="inline-flex items-center gap-1.5">
                  <Compass className="w-3.5 h-3.5 text-[#0F594E] dark:text-[#14B8A6]" />
                  {lang === 'ur'
                    ? 'ایبٹ آباد لوکل کوآرڈینیٹ ویو (گوگل میپس دستیاب نہ ہونے پر متبادل نقشہ)'
                    : 'Abbottabad Coordinate View (interactive fallback)'}
                </span>
                <span className="font-mono-num text-slate-400">34.17° N, 73.24° E</span>
              </div>
            </div>
          ) : (
            <div className="h-[360px] sm:h-[460px] lg:h-[520px] w-full relative">
              <APIProvider
                apiKey={apiKey}
                language={lang === 'ur' ? 'ur' : 'en'}
                region="PK"
              >
                <GoogleMap
                  defaultCenter={mapCenter}
                  defaultZoom={13}
                  mapId="DEMO_MAP_ID"
                  colorScheme={theme === 'dark' ? 'DARK' : 'LIGHT'}
                  gestureHandling="greedy"
                  disableDefaultUI={false}
                  internalUsageAttributionIds={['gmp_mcp_codeassist_v1_aistudio']}
                  className="w-full h-full"
                >
                  <MapViewportController center={mapCenter} />

                  {/* Household locality marker */}
                  <AdvancedMarker position={mapCenter} title={selectedArea}>
                    <div className="px-2.5 py-1 rounded-lg bg-slate-900 dark:bg-white text-white dark:text-slate-900 text-[11px] font-semibold shadow-md border border-white/20">
                      {selectedArea}
                    </div>
                  </AdvancedMarker>

                  {/* Filtered Abbottabad workers */}
                  {recommendations.map((rec) => {
                    const isSelected = activeRec?.worker.id === rec.worker.id;
                    return (
                      <AdvancedMarker
                        key={rec.worker.id}
                        position={{ lat: rec.worker.latitude, lng: rec.worker.longitude }}
                        title={`${rec.worker.name} — ${rec.worker.role}`}
                        onClick={() => setActiveId(rec.worker.id)}
                      >
                        <div
                          className={`flex items-center gap-1.5 p-1 pe-2.5 rounded-full shadow-md border transition-transform cursor-pointer ${
                            isSelected
                              ? 'scale-110 bg-[#0F594E] text-white border-[#0F594E]'
                              : 'bg-white text-slate-900 border-slate-200 hover:scale-105'
                          }`}
                        >
                          <WorkerAvatar
                            name={rec.worker.name}
                            role={rec.worker.role}
                            avatarUrl={rec.worker.avatarUrl}
                            size="xs"
                          />
                          <div className="text-left leading-tight">
                            <div className="text-[11px] font-semibold whitespace-nowrap">
                              {rec.worker.name.split(' ')[0]}
                            </div>
                            <div
                              className={`text-[10px] font-mono-num ${
                                isSelected ? 'text-teal-200' : 'text-slate-500'
                              }`}
                            >
                              PKR {rec.worker.numericRate.toLocaleString()}
                            </div>
                          </div>
                        </div>
                      </AdvancedMarker>
                    );
                  })}

                  {activeRec && (
                    <InfoWindow
                      position={{
                        lat: activeRec.worker.latitude,
                        lng: activeRec.worker.longitude,
                      }}
                      onCloseClick={() => setActiveId(null)}
                      pixelOffset={[0, -28]}
                    >
                      <div className="min-w-[200px] p-1 text-slate-900">
                        <p className="font-semibold text-sm">{activeRec.worker.name}</p>
                        <p className="text-xs text-slate-600 mt-0.5">
                          {activeRec.worker.role} · {activeRec.worker.area} ·{' '}
                          {activeRec.distanceKm.toFixed(1)} km
                        </p>
                        <p className="text-xs font-semibold text-[#0F594E] mt-1 font-mono-num">
                          PKR {activeRec.worker.numericRate.toLocaleString()} / visit ·{' '}
                          {activeRec.matchPercentage}% {tr(lang, 'aiMatch')}
                        </p>
                      </div>
                    </InfoWindow>
                  )}
                </GoogleMap>
              </APIProvider>
            </div>
          )}

          {/* Subtle Terms notice */}
          <div className="px-4 py-2.5 border-t border-slate-200 dark:border-slate-800 flex flex-wrap items-center justify-between gap-2 text-[11px] text-slate-500 dark:text-slate-400">
            <span>
              {lang === 'ur'
                ? 'فاصلے کا حساب ایبٹ آباد کے منتخب محلے سے کیا جاتا ہے۔'
                : `Haversine distance calculated from ${selectedArea}, Abbottabad.`}
            </span>
            <a
              href="https://cloud.google.com/maps-platform/terms"
              target="_blank"
              rel="noreferrer"
              className="underline hover:text-slate-700 dark:hover:text-slate-200"
            >
              Google Maps Terms
            </a>
          </div>
        </div>

        {/* Right Selected Specialist Panel */}
        <div className="lg:col-span-4 space-y-3">
          {activeRec ? (
            <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-5">
              <div className="flex items-start gap-3.5">
                <WorkerAvatar
                  name={activeRec.worker.name}
                  role={activeRec.worker.role}
                  avatarUrl={activeRec.worker.avatarUrl}
                  size="lg"
                />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-1.5">
                    <h3 className="font-display text-lg font-semibold text-slate-900 dark:text-white truncate">
                      {activeRec.worker.name}
                    </h3>
                    {activeRec.worker.verificationStatus === 'Verified' && (
                      <CheckCircle2 className="w-4 h-4 text-[#0F594E] dark:text-[#14B8A6] shrink-0" />
                    )}
                  </div>
                  <p className="mt-0.5 text-xs text-slate-500 dark:text-slate-400">
                    {activeRec.worker.role} · {activeRec.worker.experience} · {activeRec.worker.area}
                  </p>
                  <div className="mt-2 flex items-center gap-3 text-xs text-slate-600 dark:text-slate-300 font-mono-num">
                    <span className="inline-flex items-center gap-1 font-semibold">
                      <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
                      {activeRec.worker.rating.toFixed(1)}
                    </span>
                    <span>·</span>
                    <span className="inline-flex items-center gap-1">
                      <MapPin className="w-3.5 h-3.5 text-slate-400" />
                      {activeRec.distanceKm.toFixed(1)} km
                    </span>
                    <span>·</span>
                    <span className="text-[#0F594E] dark:text-[#5EEAD4] font-semibold">
                      {activeRec.matchPercentage}% {tr(lang, 'aiMatch')}
                    </span>
                  </div>
                </div>
              </div>

              <p className="mt-4 text-sm text-slate-600 dark:text-slate-300 leading-relaxed">
                {activeRec.worker.bio}
              </p>

              {/* XAI Match Breakdown */}
              <div className="mt-4 pt-4 border-t border-slate-100 dark:border-slate-800 space-y-2">
                <div className="flex items-center justify-between text-xs">
                  <span className="text-slate-500 dark:text-slate-400">
                    {lang === 'ur' ? 'مہارت کی مطابقت' : 'Skill Fit'}
                  </span>
                  <span className="font-mono-num font-semibold text-slate-800 dark:text-slate-200">
                    {activeRec.skillScore}%
                  </span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-slate-500 dark:text-slate-400">
                    {lang === 'ur' ? 'علاقائی قربت' : 'Proximity'}
                  </span>
                  <span className="font-mono-num font-semibold text-slate-800 dark:text-slate-200">
                    {activeRec.geoScore}%
                  </span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-slate-500 dark:text-slate-400">
                    {lang === 'ur' ? 'گھریلو اعتماد' : 'Household Rating'}
                  </span>
                  <span className="font-mono-num font-semibold text-slate-800 dark:text-slate-200">
                    {activeRec.ratingScore}%
                  </span>
                </div>
              </div>

              <div className="mt-5 pt-4 border-t border-slate-100 dark:border-slate-800 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                  <span className="font-mono-num text-lg font-semibold text-slate-900 dark:text-white">
                    PKR {activeRec.worker.numericRate.toLocaleString()}
                  </span>
                  <span className="text-xs text-slate-500 dark:text-slate-400 ms-1">/ visit</span>
                </div>
                <div className="grid grid-cols-2 sm:flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => onSelectWorker(activeRec.worker)}
                    className="min-h-[44px] px-3.5 rounded-xl text-xs font-semibold text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 active:scale-[0.98] transition-all"
                  >
                    {tr(lang, 'viewProfile')}
                  </button>
                  <button
                    type="button"
                    onClick={() => onBookWorker(activeRec.worker)}
                    className="min-h-[44px] px-4 rounded-xl text-xs font-semibold bg-[#0F594E] hover:bg-[#0B453C] dark:bg-[#14B8A6] dark:hover:bg-[#0D9488] text-white dark:text-[#042F2E] active:scale-[0.98] transition-all"
                  >
                    {tr(lang, 'bookNow')}
                  </button>
                </div>
              </div>
            </div>
          ) : (
            <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-6 text-center text-sm text-slate-500 dark:text-slate-400">
              {lang === 'ur'
                ? 'اس فلٹر کے تحت کوئی ورکر دستیاب نہیں۔'
                : 'No specialists match the current filters.'}
            </div>
          )}

          {/* Compact Map Directory List */}
          <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] divide-y divide-slate-100 dark:divide-slate-800 max-h-[230px] overflow-y-auto">
            {recommendations.map((rec) => {
              const selected = activeRec?.worker.id === rec.worker.id;
              return (
                <button
                  key={rec.worker.id}
                  type="button"
                  onClick={() => setActiveId(rec.worker.id)}
                  className={`w-full px-4 py-3 flex items-center justify-between gap-3 text-start transition-colors ${
                    selected
                      ? 'bg-[#0F594E]/6 dark:bg-[#14B8A6]/10'
                      : 'hover:bg-slate-50 dark:hover:bg-slate-800/50'
                  }`}
                >
                  <div className="flex items-center gap-2.5 min-w-0">
                    <WorkerAvatar
                      name={rec.worker.name}
                      role={rec.worker.role}
                      avatarUrl={rec.worker.avatarUrl}
                      size="xs"
                    />
                    <div className="min-w-0">
                      <p className="text-xs font-semibold text-slate-900 dark:text-white truncate">
                        {rec.worker.name}
                      </p>
                      <p className="text-[11px] text-slate-500 dark:text-slate-400 truncate">
                        {rec.worker.role} · {rec.worker.area}
                      </p>
                    </div>
                  </div>
                  <span className="font-mono-num text-xs font-semibold text-[#0F594E] dark:text-[#5EEAD4] shrink-0">
                    {rec.distanceKm.toFixed(1)} km
                  </span>
                </button>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
};
