/**
 * @file fixtures.ts
 * @description Shared test data: a user context and three candidate
 *   restaurants in the shape the clients send to /ai-recommend.
 */

import type { RecommendationContext, Restaurant } from "../types.ts";

export const fixtureContext: RecommendationContext = {
  mealType: "lunch",
  budgetRange: "$$",
  dietaryPreferences: { restrictions: ["vegetarian"], allergies: [] },
  recentMeals: [
    "Lunch: $18.50 (yesterday)",
    "Dinner: $32.00 (2 days ago)",
    "Lunch: $12.00 (3 days ago)",
    "Breakfast: $9.50 (3 days ago)",
    "Lunch: $21.00 (4 days ago)",
    "Dinner: $40.00 (5 days ago)",
  ],
  location: { hasLocation: true, latitude: -33.87, longitude: 151.21 },
  temporal: { hour: 12, dayOfWeek: 2, isWeekend: false },
  preferenceScores: { price_sensitivity: 0.7, variety_seeking: 0.5 },
};

export function restaurant(
  overrides: Partial<Restaurant> & Pick<Restaurant, "placeId" | "name">,
): Restaurant {
  return {
    location: "Sydney NSW",
    address: null,
    phoneNumber: null,
    website: null,
    latitude: null,
    longitude: null,
    distanceFromUser: null,
    rating: null,
    reviewCount: null,
    priceLevel: null,
    priceRanges: [],
    cuisineType: null,
    cuisineTypes: [],
    supportedDietaryRestrictions: [],
    allergenInfo: [],
    dietaryCompatibilityScores: {},
    hasVerifiedDietaryInfo: false,
    communityVerificationCount: 0,
    openingHours: [],
    isOpenNow: false,
    currentWaitTime: null,
    features: [],
    averageMealCost: null,
    valueScore: null,
    mealTypeAverageCosts: {},
    recentReviews: [],
    cachedAtEpochSeconds: 1725250000,
    lastVerifiedEpochSeconds: null,
    photoReference: null,
    photoReferences: [],
    photoUrl: null,
    ...overrides,
  };
}

export const fixtureCandidates: Restaurant[] = [
  restaurant({
    placeId: "ChIJN1t_tDeuEmsRUsoyG83frY4",
    name: "Trattoria Bridge",
    address: "12 Bridge St, Sydney NSW 2000, Australia",
    rating: 4.5,
    reviewCount: 1287,
    priceLevel: 2,
    averageMealCost: 24.5,
    valueScore: 0.8,
    cuisineTypes: ["Italian", "Pizza"],
    supportedDietaryRestrictions: ["vegetarian"],
    features: ["takeout"],
    distanceFromUser: 0.72,
  }),
  restaurant({
    placeId: "ChIJrTLr-GyuEmsRBfy61i59si0",
    name: "Sushi Rocks",
    address: "3/45 George St, The Rocks NSW 2000, Australia",
    rating: 4,
    reviewCount: 411,
    priceLevel: 3,
    cuisineTypes: ["Japanese", "Sushi"],
    features: ["delivery", "takeout"],
    distanceFromUser: 1.15,
  }),
  restaurant({
    placeId: "ChIJ7cv00DwsDogRAMDACa2i4K8",
    name: "Pitt Street Canteen",
    location: "200 Pitt St, Sydney",
    rating: 3.9,
    reviewCount: 88,
    cuisineTypes: ["Restaurant"],
  }),
];
