import { LOCALITY_COORDINATES, RECURRENCE_PLANS } from '../data/sampleData';
import { AIRecommendationResult, Booking, RecurrenceCadence, WorkerProfile } from '../types';

/**
 * Content-Based Explainable AI (XAI) Recommendation Engine for HomeEase.
 * 1. Skill & Category Cosine/Tag Similarity (w = 0.50)
 * 2. Spherical Haversine distance decay: S_geo = 1 / (1 + 0.2 * d) (w = 0.35)
 * 3. Min-Max Bayesian rating normalization: S_rating = (R - 1) / 4 (w = 0.15)
 */
const SKILL_WEIGHT = 0.5;
const GEO_WEIGHT = 0.35;
const RATING_WEIGHT = 0.15;
const GEO_DECAY_ALPHA = 0.2;
const EARTH_RADIUS_KM = 6371.0;

export function calculateHaversineDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_KM * c;
}

export function calculateSkillSimilarity(
  targetCategory: string,
  preferredSkills: string[],
  workerRole: string,
  workerSkillTags: string[],
  workerBio: string
): number {
  const categoryLower = targetCategory.toLowerCase();
  const roleLower = workerRole.toLowerCase();

  let baseScore = 0.3;
  if (
    categoryLower === 'all' ||
    categoryLower === '' ||
    roleLower.includes(categoryLower) ||
    categoryLower.includes(roleLower)
  ) {
    baseScore = categoryLower === 'all' || categoryLower === '' ? 0.65 : 0.82;
  }

  if (preferredSkills.length === 0) {
    return baseScore;
  }

  const allWorkerTokens = new Set([
    ...workerSkillTags.map((e) => e.toLowerCase()),
    ...roleLower.split(/\s+/),
    ...workerBio.toLowerCase().split(/\s+/),
  ]);

  let matchCount = 0;
  for (const skill of preferredSkills) {
    const sk = skill.toLowerCase().trim();
    if (!sk) continue;
    for (const token of allWorkerTokens) {
      if (token.includes(sk) || sk.includes(token)) {
        matchCount++;
        break;
      }
    }
  }

  const skillRatio = matchCount / preferredSkills.length;
  return Math.max(0, Math.min(1, baseScore * 0.45 + skillRatio * 0.55));
}

export function recommendWorkers(params: {
  workers: WorkerProfile[];
  targetCategory: string;
  targetArea?: string;
  searchQuery?: string;
  maxDistanceKm?: number;
}): AIRecommendationResult[] {
  const { workers, targetCategory, targetArea = 'Mandian', searchQuery = '', maxDistanceKm = 30 } = params;
  const coords = LOCALITY_COORDINATES[targetArea] ?? LOCALITY_COORDINATES.Mandian;
  const preferredSkills = searchQuery
    .split(/[\s,]+/)
    .map((s) => s.trim())
    .filter((s) => s.length >= 2);

  const results: AIRecommendationResult[] = [];

  for (const worker of workers) {
    if (!worker.profileVisibility) continue;

    if (
      targetCategory !== 'All' &&
      worker.role.toLowerCase() !== targetCategory.toLowerCase()
    ) {
      continue;
    }

    if (searchQuery.trim().length > 0) {
      const q = searchQuery.toLowerCase();
      const hay = `${worker.name} ${worker.role} ${worker.area} ${worker.description} ${worker.skillTags.join(' ')}`.toLowerCase();
      if (!hay.includes(q)) continue;
    }

    const simSkill = calculateSkillSimilarity(
      targetCategory,
      preferredSkills,
      worker.role,
      worker.skillTags,
      worker.bio
    );

    const distKm = calculateHaversineDistance(
      coords.lat,
      coords.lon,
      worker.latitude,
      worker.longitude
    );

    if (distKm > maxDistanceKm) continue;

    const sGeo = 1 / (1 + GEO_DECAY_ALPHA * distKm);
    const sRating =
      worker.reviewsCount > 0
        ? (Math.max(1, Math.min(5, worker.rating)) - 1) / 4
        : (3.5 - 1) / 4;

    const compositeScore = SKILL_WEIGHT * simSkill + GEO_WEIGHT * sGeo + RATING_WEIGHT * sRating;
    const matchPercentage = Math.round(Math.max(0, Math.min(1, compositeScore)) * 100);

    const reasons: string[] = [];
    if (simSkill >= 0.7) {
      reasons.push(`Strong ${worker.role} specialization fit`);
    } else if (simSkill >= 0.4) {
      reasons.push('Compatible domestic skills');
    }
    if (distKm <= 2.0) {
      reasons.push(`${distKm.toFixed(1)} km away in ${worker.area}`);
    } else {
      reasons.push(`${distKm.toFixed(1)} km from ${targetArea}`);
    }
    if (worker.rating >= 4.7) {
      reasons.push(`${worker.rating.toFixed(1)}★ top-rated reputation`);
    } else if (worker.verificationStatus === 'Verified') {
      reasons.push('NADRA CNIC identity verified');
    }

    const xaiBadge = `${matchPercentage}% Match · ${distKm.toFixed(1)} km · ${worker.area}`;

    results.push({
      worker,
      compositeScore,
      matchPercentage,
      distanceKm: distKm,
      xaiBadge,
      matchReasons: reasons,
      skillScore: Math.round(simSkill * 100),
      geoScore: Math.round(sGeo * 100),
      ratingScore: Math.round(sRating * 100),
    });
  }

  return results.sort((a, b) => b.compositeScore - a.compositeScore);
}

/**
 * Recurring Household Plan pricing calculator.
 */
export function calculateRecurringPricing(
  baseRate: number,
  cadence: RecurrenceCadence,
  daysPerWeekCount = 1
): {
  baseAmount: number;
  discountPercent: number;
  perVisitAmount: number;
  savingsPerVisit: number;
  estimatedMonthlyVisits: number;
  estimatedMonthlyTotal: number;
} {
  const plan = RECURRENCE_PLANS.find((p) => p.id === cadence) ?? RECURRENCE_PLANS[0];
  const discountPercent = plan.discountPercent;
  const savingsPerVisit = Math.round((baseRate * discountPercent) / 100);
  const perVisitAmount = Math.max(0, baseRate - savingsPerVisit);

  let estimatedMonthlyVisits = plan.visitsPerMonth;
  if (cadence === 'weekly') {
    estimatedMonthlyVisits = Math.max(1, daysPerWeekCount) * 4;
  } else if (cadence === 'biweekly') {
    estimatedMonthlyVisits = Math.max(1, daysPerWeekCount) * 2;
  }

  return {
    baseAmount: baseRate,
    discountPercent,
    perVisitAmount,
    savingsPerVisit,
    estimatedMonthlyVisits,
    estimatedMonthlyTotal: perVisitAmount * estimatedMonthlyVisits,
  };
}

/**
 * Interval overlap and scheduling conflict detection engine.
 * Mathematical condition: S_req < E_exist AND E_req > S_exist
 */
export function timeStringToMinutes(timeStr: string): number {
  const [h, m] = timeStr.split(':').map((n) => parseInt(n, 10) || 0);
  return h * 60 + m;
}

export function checkBookingConflict(params: {
  workerId: string;
  date: string;
  startTime: string;
  endTime: string;
  existingBookings: Booking[];
}): { hasConflict: boolean; conflictingBooking?: Booking; error?: string } {
  const sReq = timeStringToMinutes(params.startTime);
  const eReq = timeStringToMinutes(params.endTime);

  if (sReq >= eReq) {
    return { hasConflict: true, error: 'Start time must be strictly before end time.' };
  }

  const activeStatuses = new Set(['Pending', 'Accepted', 'In Progress']);

  for (const existing of params.existingBookings) {
    if (existing.workerId !== params.workerId) continue;
    if (existing.bookingDate !== params.date) continue;
    if (!activeStatuses.has(existing.status)) continue;

    const sExist = timeStringToMinutes(existing.startTime);
    const eExist = timeStringToMinutes(existing.endTime);

    if (sReq < eExist && eReq > sExist) {
      return {
        hasConflict: true,
        conflictingBooking: existing,
        error: `Schedule conflict: worker already has a ${existing.status.toLowerCase()} booking from ${existing.startTime} to ${existing.endTime} on ${existing.bookingDate}.`,
      };
    }
  }

  return { hasConflict: false };
}
