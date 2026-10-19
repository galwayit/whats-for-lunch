/**
 * @file types.ts
 * @description TypeScript mirrors of the Kotlin models in
 *   shared/src/commonMain/kotlin/au/iapp/lunch/core/model/Models.kt.
 *   Keys are camelCase and every timestamp is epoch SECONDS, exactly as the
 *   Kotlin serializers expect. Keep the two files in sync.
 */

export type Tier = "free" | "pro";

export type RsvpStatus = "pending" | "accepted" | "declined";

/** Free-tier allowances. Mirrors `FreeLimits` in Models.kt. */
export const FreeLimits = {
  AI_REQUESTS_PER_DAY: 1,
  FAVOURITES: 10,
  HISTORY_DAYS: 30,
} as const;

export interface PlaceAttribution {
  name: string;
  uri: string | null;
  photoUri: string | null;
}

export interface RestaurantReview {
  reviewId: string;
  authorName: string;
  authorPhotoUrl: string | null;
  rating: number;
  text: string | null;
  timeEpochSeconds: number;
  relativeTimeDescription: string;
  authorUri?: string | null;
  sourceUri?: string | null;
}

export interface Restaurant {
  placeId: string;
  name: string;
  location: string;
  address: string | null;
  phoneNumber: string | null;
  website: string | null;
  latitude: number | null;
  longitude: number | null;
  /** Kilometres from the user at fetch time. */
  distanceFromUser: number | null;
  rating: number | null;
  reviewCount: number | null;
  /** 1..4, matching the number of dollar signs. */
  priceLevel: number | null;
  priceRanges: string[];
  cuisineType: string | null;
  cuisineTypes: string[];
  supportedDietaryRestrictions: string[];
  allergenInfo: string[];
  dietaryCompatibilityScores: Record<string, number>;
  hasVerifiedDietaryInfo: boolean;
  communityVerificationCount: number;
  openingHours: string[];
  isOpenNow: boolean;
  currentWaitTime: string | null;
  features: string[];
  averageMealCost: number | null;
  valueScore: number | null;
  mealTypeAverageCosts: Record<string, number>;
  recentReviews: RestaurantReview[];
  cachedAtEpochSeconds: number;
  lastVerifiedEpochSeconds: number | null;
  photoReference: string | null;
  photoReferences: string[];
  /** Absolute URL served by the backend for the first photo, when available. */
  photoUrl: string | null;
  googleMapsUri?: string | null;
  photoSourceUri?: string | null;
  photoAttributions?: PlaceAttribution[];
  attributions?: PlaceAttribution[];
}

export interface AiRecommendation {
  id: string;
  /** Local (SQLite) user id. The backend does not know it; see BUILD_NOTES.md. */
  userId: number;
  restaurants: Restaurant[];
  reasoning: string;
  factorWeights: Record<string, number>;
  overallConfidence: number;
  investmentSummary: string | null;
  generatedAtEpochSeconds: number;
  wasAccepted: boolean;
  userFeedback: string | null;
}

export interface LunchGroup {
  id: string;
  hostId: string;
  hostName: string;
  budgetPerPersonMinor?: number | null;
  currencyCode?: string;
  paymentArrangement?: string;
  paymentMethod?: string;
  name: string;
  scheduledAtEpochSeconds: number;
  areaLatitude: number;
  areaLongitude: number;
  radiusKm: number;
  placeId: string | null;
  placeName: string | null;
  placeAddress: string | null;
  inviteCode: string;
  createdAtEpochSeconds: number;
}

export interface Rsvp {
  id: string;
  groupId: string;
  guestUserId: string | null;
  displayName: string;
  status: RsvpStatus;
  respondedAtEpochSeconds: number | null;
}

export interface GroupProposal {
  restaurant: Restaurant;
  reasons: string[];
}

/** What a guest sees when opening an invitation link. */
export interface Invitation {
  group: LunchGroup;
  attendees: Rsvp[];
  myStatus: RsvpStatus | null;
  inviteUrl: string;
  mySuggestion?: ReturnType<typeof import("./group-planning.ts").suggestionFromRow> | null;
}

/**
 * The `context` object of POST /ai-recommend. Mirrors the shape produced by the
 * Flutter UserContextService; the sub-objects are free-form and are serialised
 * verbatim into the prompt, so they are typed loosely on purpose.
 */
export interface RecommendationContext {
  mealType: string;
  budgetRange: string;
  dietaryPreferences: Record<string, unknown>;
  recentMeals: string[];
  location: Record<string, unknown>;
  temporal: Record<string, unknown>;
  preferenceScores: Record<string, number>;
  includeChains?: boolean;
}

/** Database row shapes (snake_case) used by the handlers. */
export interface GroupRow {
  id: string;
  host_id: string;
  host_name: string;
  budget_per_person_minor?: number | null;
  currency_code?: string;
  payment_arrangement?: string;
  payment_method?: string;
  name: string;
  scheduled_at: string;
  area_lat: number;
  area_lng: number;
  radius_km: number;
  place_id: string | null;
  place_name: string | null;
  place_address: string | null;
  invite_code: string;
  created_at: string;
  cancelled_at: string | null;
}

export interface RsvpRow {
  id: string;
  group_id: string;
  guest_user_id: string | null;
  guest_token: string | null;
  display_name: string;
  status: RsvpStatus;
  responded_at: string | null;
}

export interface EntitlementRow {
  app_user_id: string;
  is_pro: boolean;
  product_id: string | null;
  expires_at: string | null;
  source: string;
}

export interface DeviceTokenRow {
  app_user_id: string;
  user_id: string | null;
  token: string;
  platform: string;
}

/** Converts a Postgres timestamptz (ISO string) to epoch seconds. */
export function toEpochSeconds(iso: string): number {
  return Math.floor(new Date(iso).getTime() / 1000);
}

/** Converts epoch seconds to an ISO string for a timestamptz column. */
export function fromEpochSeconds(seconds: number): string {
  return new Date(seconds * 1000).toISOString();
}

export function nowEpochSeconds(): number {
  return Math.floor(Date.now() / 1000);
}
