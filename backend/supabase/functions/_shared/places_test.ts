import { assertEquals } from "jsr:@std/assert@1";
import details from "./__fixtures__/places_details_response.json" with { type: "json" };
import nearby from "./__fixtures__/places_nearby_response.json" with { type: "json" };
import {
  applyFilters,
  extractCuisineTypes,
  extractFeatures,
  mapPlace,
  mapReviews,
  normaliseQuery,
  photoProxyUrl,
} from "./places.ts";
import type { Restaurant } from "./types.ts";

const options = {
  origin: { lat: -33.87, lng: 151.21 },
  functionsBase: "https://abc.supabase.co/functions/v1",
  nowEpochSeconds: 1725250000,
};

Deno.test("mapPlace maps a nearby Place resource to the Restaurant JSON", () => {
  const r = mapPlace(nearby.places[0], options);
  assertEquals(
    r,
    {
      placeId: "ChIJN1t_tDeuEmsRUsoyG83frY4",
      name: "Trattoria Bridge",
      location: "12 Bridge St, Sydney NSW 2000, Australia",
      address: "12 Bridge St, Sydney NSW 2000, Australia",
      phoneNumber: null,
      website: null,
      latitude: -33.8636,
      longitude: 151.2092,
      distanceFromUser: 0.72,
      rating: 4.5,
      reviewCount: 1287,
      priceLevel: 2,
      priceRanges: ["$$"],
      cuisineType: "Italian",
      cuisineTypes: ["Italian", "Pizza"],
      supportedDietaryRestrictions: [],
      allergenInfo: [],
      dietaryCompatibilityScores: {},
      hasVerifiedDietaryInfo: false,
      communityVerificationCount: 0,
      openingHours: [],
      isOpenNow: true,
      currentWaitTime: null,
      features: ["takeout"],
      averageMealCost: null,
      valueScore: null,
      mealTypeAverageCosts: {},
      recentReviews: [],
      cachedAtEpochSeconds: 1725250000,
      lastVerifiedEpochSeconds: null,
      photoReference: "places/ChIJN1t_tDeuEmsRUsoyG83frY4/photos/AXCi2Q5abc",
      photoReferences: [
        "places/ChIJN1t_tDeuEmsRUsoyG83frY4/photos/AXCi2Q5abc",
        "places/ChIJN1t_tDeuEmsRUsoyG83frY4/photos/AXCi2Q5def",
      ],
      photoUrl:
        "https://abc.supabase.co/functions/v1/places-photo?name=places%2FChIJN1t_tDeuEmsRUsoyG83frY4%2Fphotos%2FAXCi2Q5abc&maxWidth=800",
      googleMapsUri:
        "https://www.google.com/maps/search/?api=1&query=Trattoria%20Bridge&query_place_id=ChIJN1t_tDeuEmsRUsoyG83frY4",
      photoSourceUri: null,
      photoAttributions: [],
      attributions: [],
    } satisfies Restaurant,
  );
});

Deno.test("mapPlace handles missing optional fields and drops places without id or name", () => {
  const sushi = mapPlace(nearby.places[1], options)!;
  assertEquals(sushi.priceLevel, 3);
  assertEquals(sushi.priceRanges, ["$$$"]);
  assertEquals(sushi.features, ["delivery", "takeout"]);
  assertEquals(sushi.cuisineTypes, ["Japanese", "Sushi"]);
  assertEquals(sushi.photoUrl, null);
  assertEquals(sushi.isOpenNow, false);

  const canteen = mapPlace(nearby.places[2], options)!;
  assertEquals(canteen.priceLevel, null);
  assertEquals(canteen.priceRanges, []);
  assertEquals(canteen.cuisineTypes, ["Restaurant"]);
  assertEquals(canteen.cuisineType, "Restaurant");
  assertEquals(canteen.isOpenNow, false);

  assertEquals(mapPlace(nearby.places[3], options), null);
  assertEquals(mapPlace(null, options), null);
});

Deno.test("mapPlace on a details resource fills phone, website and opening hours; reviews map", () => {
  const r = mapPlace(details, { ...options, origin: null })!;
  assertEquals(r.phoneNumber, "+61 2 9251 1234");
  assertEquals(r.website, "https://trattoriabridge.example/");
  assertEquals(r.distanceFromUser, null);
  assertEquals(r.openingHours.length, 7);
  assertEquals(r.openingHours[6], "Sunday: Closed");

  const reviews = mapReviews(details.reviews);
  assertEquals(reviews.length, 2);
  assertEquals(reviews[0], {
    reviewId: "places/ChIJN1t_tDeuEmsRUsoyG83frY4/reviews/ChdDSUhNMG9nS0VJQ0FnSUNud1lxRmdBRRAB",
    authorName: "Priya N",
    authorPhotoUrl: "https://lh3.googleusercontent.com/a/photo1",
    rating: 5,
    text: "Best carbonara in the CBD.",
    timeEpochSeconds: Math.floor(Date.parse("2026-08-19T03:21:44Z") / 1000),
    relativeTimeDescription: "2 weeks ago",
    authorUri: "https://www.google.com/maps/contrib/1",
    sourceUri: null,
  });
  assertEquals(reviews[1].text, null);
  assertEquals(reviews[1].authorPhotoUrl, null);
  assertEquals(mapReviews(undefined), []);
});

Deno.test("extractCuisineTypes reproduces the legacy labels from New API types", () => {
  assertEquals(extractCuisineTypes(["korean_restaurant", "restaurant", "food"]), ["Korean"]);
  assertEquals(extractCuisineTypes(["steak_house", "hamburger_restaurant"]), [
    "Steakhouse",
    "Burgers",
  ]);
  assertEquals(extractCuisineTypes(["coffee_shop", "cafe", "bakery"]), ["Cafe", "Bakery"]);
  assertEquals(extractCuisineTypes(["fast_food_restaurant", "fine_dining_restaurant"]), [
    "Fast Food",
    "Fine Dining",
  ]);
  assertEquals(extractCuisineTypes(["restaurant", "point_of_interest"]), ["Restaurant"]);
  assertEquals(extractCuisineTypes(["food"]), ["Food"]);
  assertEquals(extractCuisineTypes(["bar"]), []);
});

Deno.test("extractFeatures keeps the legacy names and order", () => {
  assertEquals(
    extractFeatures([
      "wifi",
      "outdoor_seating",
      "meal_takeaway",
      "meal_delivery",
      "dine_in",
      "wheelchair_accessible",
    ]),
    ["delivery", "takeout", "dine_in", "wheelchair_accessible", "outdoor_seating", "wifi"],
  );
  assertEquals(extractFeatures(["restaurant"]), []);
});

Deno.test("photoProxyUrl, normaliseQuery and applyFilters", () => {
  assertEquals(
    photoProxyUrl("places/a/photos/b", "https://x.supabase.co/functions/v1/", 400),
    "https://x.supabase.co/functions/v1/places-photo?name=places%2Fa%2Fphotos%2Fb&maxWidth=400",
  );
  assertEquals(normaliseQuery("  Sushi   Bar "), "sushi bar");
  assertEquals(normaliseQuery(null), "");
  assertEquals(normaliseQuery(42), "");

  const all = nearby.places.map((p) => mapPlace(p, options)).filter((r): r is Restaurant =>
    r !== null
  );
  assertEquals(applyFilters(all, 2, null).map((r) => r.name), [
    "Trattoria Bridge",
    "Pitt Street Canteen",
  ]);
  assertEquals(applyFilters(all, null, 4.3).map((r) => r.name), ["Trattoria Bridge"]);
  assertEquals(applyFilters(all, null, null).length, 3);
});

Deno.test("photo, provider and review source attributions survive mapping", () => {
  const place = mapPlace({
    id: "fixture",
    displayName: { text: "Fictional cafe" },
    googleMapsUri: "https://maps.google.com/fixture",
    attributions: [{ provider: "Fixture provider", providerUri: "https://example.test/provider" }],
    photos: [{
      name: "places/fixture/photos/one",
      googleMapsUri: "https://maps.google.com/photo",
      authorAttributions: [{
        displayName: "Fixture Author",
        uri: "https://maps.google.com/author",
        photoUri: "https://example.test/avatar",
      }],
    }],
  }, options)!;
  assertEquals(place.photoAttributions?.[0].name, "Fixture Author");
  assertEquals(place.photoAttributions?.[0].uri, "https://maps.google.com/author");
  assertEquals(place.attributions?.[0].name, "Fixture provider");
  assertEquals(place.photoSourceUri, "https://maps.google.com/photo");
  const reviews = mapReviews([{
    name: "fixture-review",
    googleMapsUri: "https://maps.google.com/review",
    authorAttribution: { displayName: "Fixture Author", uri: "https://maps.google.com/author" },
  }]);
  assertEquals(reviews[0].sourceUri, "https://maps.google.com/review");
  assertEquals(reviews[0].authorUri, "https://maps.google.com/author");
});
