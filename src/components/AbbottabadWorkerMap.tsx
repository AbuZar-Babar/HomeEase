import React, { useEffect, useRef, useState } from 'react';
import {
  APIProvider,
  AdvancedMarker,
  InfoWindow,
  Map as GoogleMap,
  useMap,
} from '@vis.gl/react-google-maps';
import { AnimatePresence, MotionConfig, motion } from 'framer-motion';
import { CheckCircle2, Compass, LocateFixed, MapPin, Star } from 'lucide-react';
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

const SPRING_MARKER = {
  type: 'spring' as const,
  stiffness: 360,
  damping: 25,
  mass: 0.85,
};

const EASE_OUT_EXPO: [number, number, number, number] = [0.22, 1, 0.36, 1];

interface MapViewportControllerProps {
  center: { lat: number; lng: number };
  zoom: number;
}

/**
 * Smoothly interpolates Google Maps camera pan and zoom-in on mount,
 * neighborhood selection, and individual worker focus.
 */
const MapViewportController: React.FC<MapViewportControllerProps> = ({ center, zoom }) => {
  const map = useMap();
  const rafRef = useRef<number | null>(null);
  const currentRef = useRef<{ lat: number; lng: number; zoom: number } | null>(null);

  useEffect(() => {
    if (!map) return;

    if (rafRef.current !== null) {
      window.cancelAnimationFrame(rafRef.current);
      rafRef.current = null;
    }

    const existingCenter = map.getCenter();
    const startLat = currentRef.current?.lat ?? existingCenter?.lat() ?? ABBOTTABAD_CENTER.lat;
    const startLng = currentRef.current?.lng ?? existingCenter?.lng() ?? ABBOTTABAD_CENTER.lng;
    const startZoom = currentRef.current?.zoom ?? map.getZoom() ?? 11.8;

    const prefersReducedMotion =
      typeof window !== 'undefined' &&
      window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;

    if (prefersReducedMotion) {
      map.moveCamera({ center, zoom });
      currentRef.current = { lat: center.lat, lng: center.lng, zoom };
      return;
    }

    const durationMs = 620;
    const startTime = performance.now();

    const step = (now: number) => {
      const elapsed = now - startTime;
      const t = Math.min(1, elapsed / durationMs);
      // Cubic ease-out for calm, editorial camera glide
      const eased = 1 - Math.pow(1 - t, 3);

      const nextLat = startLat + (center.lat - startLat) * eased;
      const nextLng = startLng + (center.lng - startLng) * eased;
      const nextZoom = startZoom + (zoom - startZoom) * eased;

      map.moveCamera({
        center: { lat: nextLat, lng: nextLng },
        zoom: nextZoom,
      });
      currentRef.current = { lat: nextLat, lng: nextLng, zoom: nextZoom };

      if (t < 1) {
        rafRef.current = window.requestAnimationFrame(step);
      } else {
        rafRef.current = null;
      }
    };

    rafRef.current = window.requestAnimationFrame(step);

    return () => {
      if (rafRef.current !== null) {
        window.cancelAnimationFrame(rafRef.current);
        rafRef.current = null;
      }
    };
  }, [map, center.lat, center.lng, zoom]);

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
  const [cameraFocusedOnWorker, setCameraFocusedOnWorker] = useState(false);

  const activeRec =
    recommendations.find((r) => r.worker.id === activeId) ?? recommendations[0] ?? null;

  const targetCoords = LOCALITY_COORDINATES[selectedArea] ?? {
    lat: ABBOTTABAD_CENTER.lat,
    lon: ABBOTTABAD_CENTER.lng,
  };
  const localityCenter = { lat: targetCoords.lat, lng: targetCoords.lon };

  // Camera target: zoom closer onto selected specialist, or frame selected locality smoothly
  const cameraCenter =
    cameraFocusedOnWorker && activeRec
      ? { lat: activeRec.worker.latitude, lng: activeRec.worker.longitude }
      : localityCenter;
  const cameraZoom = cameraFocusedOnWorker && activeRec ? 14.5 : 13.4;

  const useInteractiveFallback = !apiKey || quotaExceeded;

  const handleSelectLocality = (area: string) => {
    setCameraFocusedOnWorker(false);
    onSelectArea(area);
  };

  const handleSelectMarker = (workerId: string) => {
    setActiveId(workerId);
    setCameraFocusedOnWorker(true);
  };

  const handleResetView = () => {
    setCameraFocusedOnWorker(false);
  };

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

  // Compute subtle pan/zoom transform for interactive fallback canvas
  const fallbackFocusPoint = projectToPercent(cameraCenter.lat, cameraCenter.lng);
  const fallbackZoomScale = cameraFocusedOnWorker ? 1.24 : 1.06;
  const fallbackOffsetX = cameraFocusedOnWorker
    ? Math.max(-14, Math.min(14, (50 - fallbackFocusPoint.x) * 0.42))
    : Math.max(-6, Math.min(6, (50 - fallbackFocusPoint.x) * 0.18));
  const fallbackOffsetY = cameraFocusedOnWorker
    ? Math.max(-14, Math.min(14, (50 - fallbackFocusPoint.y) * 0.42))
    : Math.max(-6, Math.min(6, (50 - fallbackFocusPoint.y) * 0.18));

  return (
    <MotionConfig reducedMotion="user">
      <div className="space-y-4">
        {/* Locality quick-recenter horizontal strip */}
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar pb-0.5 flex-1">
            {ABBOTTABAD_AREAS.map((area) => {
              const active = selectedArea === area;
              return (
                <motion.button
                  key={area}
                  type="button"
                  whileTap={{ scale: 0.96 }}
                  onClick={() => handleSelectLocality(area)}
                  className={`min-h-[40px] px-3.5 rounded-xl text-xs font-semibold whitespace-nowrap shrink-0 transition-colors ${
                    active
                      ? 'bg-[#0F594E] dark:bg-[#14B8A6] text-white dark:text-[#042F2E]'
                      : 'bg-white dark:bg-[#141C1E] text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-slate-800 hover:border-slate-300 dark:hover:border-slate-700'
                  }`}
                >
                  {area}
                </motion.button>
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
          <motion.div
            initial={{ opacity: 0, scale: 0.975 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.45, ease: EASE_OUT_EXPO }}
            className="lg:col-span-8 rounded-2xl overflow-hidden border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E]"
          >
            {useInteractiveFallback ? (
              <div className="relative h-[360px] sm:h-[460px] lg:h-[520px] w-full bg-[#EEF3F0] dark:bg-[#0F1A1B] overflow-hidden select-none">
                {/* Smooth zoom-in & pan spatial canvas */}
                <motion.div
                  initial={{ scale: 0.92, opacity: 0 }}
                  animate={{
                    scale: fallbackZoomScale,
                    x: `${fallbackOffsetX}%`,
                    y: `${fallbackOffsetY}%`,
                    opacity: 1,
                  }}
                  transition={{ type: 'spring', stiffness: 170, damping: 26 }}
                  className="absolute inset-0"
                >
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
                  {Object.entries(LOCALITY_COORDINATES).map(([name, coords], idx) => {
                    const pos = projectToPercent(coords.lat, coords.lon);
                    const isSelected = name === selectedArea;
                    return (
                      <motion.button
                        key={name}
                        type="button"
                        initial={{ opacity: 0, y: 6 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 0.08 + idx * 0.03, duration: 0.3, ease: EASE_OUT_EXPO }}
                        onClick={() => handleSelectLocality(name)}
                        style={{ left: `${pos.x}%`, top: `${pos.y}%` }}
                        className={`absolute -translate-x-1/2 -translate-y-1/2 text-[11px] font-semibold tracking-wide transition-colors ${
                          isSelected
                            ? 'text-[#0F594E] dark:text-[#5EEAD4]'
                            : 'text-slate-500/80 dark:text-slate-400/70 hover:text-slate-800 dark:hover:text-slate-200'
                        }`}
                      >
                        {name}
                      </motion.button>
                    );
                  })}

                  {/* Staggered spring worker pins */}
                  <AnimatePresence>
                    {recommendations.map((rec, index) => {
                      const pos = projectToPercent(rec.worker.latitude, rec.worker.longitude);
                      const isSelected = activeRec?.worker.id === rec.worker.id;
                      return (
                        <motion.button
                          key={rec.worker.id}
                          type="button"
                          onClick={() => handleSelectMarker(rec.worker.id)}
                          style={{ left: `${pos.x}%`, top: `${pos.y}%` }}
                          initial={{ opacity: 0, scale: 0.5, y: 12, x: '-50%' }}
                          animate={{
                            opacity: 1,
                            scale: isSelected ? 1.1 : 1,
                            y: isSelected ? '-58%' : '-50%',
                            x: '-50%',
                          }}
                          exit={{ opacity: 0, scale: 0.55 }}
                          whileHover={{ scale: isSelected ? 1.13 : 1.07 }}
                          whileTap={{ scale: 0.95 }}
                          transition={{
                            ...SPRING_MARKER,
                            delay: Math.min(index * 0.045, 0.36),
                          }}
                          className={`absolute flex items-center gap-1.5 p-1 pe-2.5 rounded-full shadow-md border cursor-pointer ${
                            isSelected
                              ? 'z-20 bg-[#0F594E] text-white border-[#0F594E] dark:bg-[#14B8A6] dark:text-[#042F2E] dark:border-[#14B8A6]'
                              : 'z-10 bg-white dark:bg-[#141C1E] text-slate-900 dark:text-slate-100 border-slate-200 dark:border-slate-700'
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
                        </motion.button>
                      );
                    })}
                  </AnimatePresence>
                </motion.div>

                {/* Floating Reset View Button */}
                {cameraFocusedOnWorker && (
                  <motion.button
                    type="button"
                    initial={{ opacity: 0, y: -6 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -6 }}
                    onClick={handleResetView}
                    className="absolute top-3 end-3 z-30 inline-flex items-center gap-1.5 min-h-[38px] px-3 rounded-xl bg-white/95 dark:bg-[#141C1E]/95 backdrop-blur-sm border border-slate-200 dark:border-slate-700 text-xs font-semibold text-slate-700 dark:text-slate-200 shadow-sm hover:border-[#0F594E] dark:hover:border-[#14B8A6]"
                  >
                    <LocateFixed className="w-3.5 h-3.5 text-[#0F594E] dark:text-[#5EEAD4]" />
                    {lang === 'ur' ? 'علاقہ دیکھیں' : `Recenter ${selectedArea}`}
                  </motion.button>
                )}

                <div className="absolute bottom-3 inset-x-3 z-20 flex items-center justify-between px-3.5 py-2 rounded-xl bg-white/90 dark:bg-[#141C1E]/90 backdrop-blur-sm border border-slate-200 dark:border-slate-800 text-[11px] text-slate-600 dark:text-slate-300">
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
                    defaultCenter={ABBOTTABAD_CENTER}
                    defaultZoom={11.8}
                    mapId="DEMO_MAP_ID"
                    colorScheme={theme === 'dark' ? 'DARK' : 'LIGHT'}
                    gestureHandling="greedy"
                    disableDefaultUI={false}
                    internalUsageAttributionIds={['gmp_mcp_codeassist_v1_aistudio']}
                    className="w-full h-full"
                  >
                    <MapViewportController center={cameraCenter} zoom={cameraZoom} />

                    {/* Household locality marker with entrance animation */}
                    <AdvancedMarker position={localityCenter} title={selectedArea} zIndex={5}>
                      <motion.div
                        key={selectedArea}
                        initial={{ opacity: 0, scale: 0.75, y: 6 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        transition={{ duration: 0.32, ease: EASE_OUT_EXPO }}
                        className="px-2.5 py-1 rounded-lg bg-slate-900 dark:bg-white text-white dark:text-slate-900 text-[11px] font-semibold shadow-md border border-white/20"
                      >
                        {selectedArea}
                      </motion.div>
                    </AdvancedMarker>

                    {/* Filtered Abbottabad workers with staggered spring entrance */}
                    {recommendations.map((rec, index) => {
                      const isSelected = activeRec?.worker.id === rec.worker.id;
                      return (
                        <AdvancedMarker
                          key={rec.worker.id}
                          position={{ lat: rec.worker.latitude, lng: rec.worker.longitude }}
                          title={`${rec.worker.name} — ${rec.worker.role}`}
                          zIndex={isSelected ? 50 : 10}
                          onClick={() => handleSelectMarker(rec.worker.id)}
                        >
                          <motion.div
                            initial={{ opacity: 0, scale: 0.55, y: 12 }}
                            animate={{
                              opacity: 1,
                              scale: isSelected ? 1.1 : 1,
                              y: isSelected ? -3 : 0,
                            }}
                            whileHover={{ scale: isSelected ? 1.13 : 1.06, y: -2 }}
                            whileTap={{ scale: 0.95 }}
                            transition={{
                              ...SPRING_MARKER,
                              delay: Math.min(index * 0.045, 0.36),
                            }}
                            className={`flex items-center gap-1.5 p-1 pe-2.5 rounded-full shadow-md border cursor-pointer ${
                              isSelected
                                ? 'bg-[#0F594E] text-white border-[#0F594E]'
                                : 'bg-white text-slate-900 border-slate-200'
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
                          </motion.div>
                        </AdvancedMarker>
                      );
                    })}

                    {activeRec && (
                      <InfoWindow
                        position={{
                          lat: activeRec.worker.latitude,
                          lng: activeRec.worker.longitude,
                        }}
                        onCloseClick={() => {
                          setActiveId(null);
                          setCameraFocusedOnWorker(false);
                        }}
                        pixelOffset={[0, -30]}
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

                {/* Floating Recenter Button when zoomed into a specialist */}
                <AnimatePresence>
                  {cameraFocusedOnWorker && (
                    <motion.button
                      type="button"
                      initial={{ opacity: 0, y: -8, scale: 0.95 }}
                      animate={{ opacity: 1, y: 0, scale: 1 }}
                      exit={{ opacity: 0, y: -8, scale: 0.95 }}
                      transition={{ duration: 0.2, ease: EASE_OUT_EXPO }}
                      onClick={handleResetView}
                      className="absolute top-3 start-3 z-20 inline-flex items-center gap-1.5 min-h-[38px] px-3 rounded-xl bg-white/95 dark:bg-[#141C1E]/95 backdrop-blur-sm border border-slate-200 dark:border-slate-700 text-xs font-semibold text-slate-700 dark:text-slate-200 shadow-md hover:border-[#0F594E] dark:hover:border-[#14B8A6]"
                    >
                      <LocateFixed className="w-3.5 h-3.5 text-[#0F594E] dark:text-[#5EEAD4]" />
                      {lang === 'ur' ? `${selectedArea} پر واپس` : `Recenter ${selectedArea}`}
                    </motion.button>
                  )}
                </AnimatePresence>
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
          </motion.div>

          {/* Right Selected Specialist Panel with smooth crossfade */}
          <div className="lg:col-span-4 space-y-3">
            <AnimatePresence mode="wait">
              {activeRec ? (
                <motion.div
                  key={activeRec.worker.id}
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -6 }}
                  transition={{ duration: 0.22, ease: EASE_OUT_EXPO }}
                  className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-5"
                >
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
                        {activeRec.worker.role} · {activeRec.worker.experience} ·{' '}
                        {activeRec.worker.area}
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

                  {/* Animated XAI Match Breakdown */}
                  <div className="mt-4 pt-4 border-t border-slate-100 dark:border-slate-800 space-y-2.5">
                    {[
                      {
                        label: lang === 'ur' ? 'مہارت کی مطابقت' : 'Skill Fit',
                        value: activeRec.skillScore,
                      },
                      {
                        label: lang === 'ur' ? 'علاقائی قربت' : 'Proximity',
                        value: activeRec.geoScore,
                      },
                      {
                        label: lang === 'ur' ? 'گھریلو اعتماد' : 'Household Rating',
                        value: activeRec.ratingScore,
                      },
                    ].map((metric) => (
                      <div key={metric.label}>
                        <div className="flex items-center justify-between text-xs mb-1">
                          <span className="text-slate-500 dark:text-slate-400">{metric.label}</span>
                          <span className="font-mono-num font-semibold text-slate-800 dark:text-slate-200">
                            {metric.value}%
                          </span>
                        </div>
                        <div className="h-1.5 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                          <motion.div
                            initial={{ scaleX: 0 }}
                            animate={{ scaleX: metric.value / 100 }}
                            transition={{ duration: 0.4, ease: EASE_OUT_EXPO }}
                            style={{ transformOrigin: lang === 'ur' ? 'right' : 'left' }}
                            className="h-full w-full rounded-full bg-[#0F594E] dark:bg-[#14B8A6]"
                          />
                        </div>
                      </div>
                    ))}
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
                </motion.div>
              ) : (
                <motion.div
                  key="empty-map"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] p-6 text-center text-sm text-slate-500 dark:text-slate-400"
                >
                  {lang === 'ur'
                    ? 'اس فلٹر کے تحت کوئی ورکر دستیاب نہیں۔'
                    : 'No specialists match the current filters.'}
                </motion.div>
              )}
            </AnimatePresence>

            {/* Compact Map Directory List */}
            <div className="rounded-2xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-[#141C1E] divide-y divide-slate-100 dark:divide-slate-800 max-h-[230px] overflow-y-auto">
              {recommendations.map((rec) => {
                const selected = activeRec?.worker.id === rec.worker.id;
                return (
                  <button
                    key={rec.worker.id}
                    type="button"
                    onClick={() => handleSelectMarker(rec.worker.id)}
                    className={`w-full min-h-[56px] px-4 py-3 flex items-center justify-between gap-3 text-start transition-colors ${
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
    </MotionConfig>
  );
};
