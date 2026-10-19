# Chain preferences and restaurant photo reuse — 6 October 2026

## Changes

- Hungry Jack's/Hungry Jacks/HungryJacks and Burger King share one brand entry.
  The catalogue also covers the previous brands and common Australian chains.
  Apostrophes, punctuation and case are normalised; complete-word matching avoids
  rejecting names such as Burger Kingdom or Subwayman Coffee.
- Swift, Kotlin and Edge Functions use generated helpers from
  `shared/restaurant-chains.json`. CI checks that the generated copies match.
  Known chains are excluded before selection or AI ranking when Include chains
  is off, including explicit AI candidates and group suggestions.
- Saving preferences clears the old Home pick and count. An older in-flight
  search cannot restore it. Discover also applies the saved chain preference,
  including after a debounced or in-flight search.
- iOS cards share a 32 MiB decoded-image memory cache (up to 40 images, five-minute
  TTL), merge simultaneous requests for the same photo URL and decode/downsample
  images off the main actor. Backgrounding or memory pressure clears the store.
  A foreground transition restarts an interrupted card load. Failed requests are
  not cached, and a new photo URL cannot inherit an older image.
- Android cards use one Coil image loader with a 32 MiB memory cache and explicit
  full-URL keys. Disk caching is disabled; background/memory-pressure callbacks
  clear retained images. Android does not use the iOS five-minute TTL.

## Cache choice and limits

Reusing decoded images removes repeated network and decoding work while a photo
remains in the active memory cache. The first visit, a new photo URL, eviction,
expiry or returning after backgrounding can still require a download. The tests
measure request reuse, not a real mobile-network latency improvement.

A generic HTTP cache alone would not solve this: the current photo proxy returns
`Cache-Control: no-store`, and SwiftUI's previous AsyncImage path did not share
decoded rendering assets. No persistent photo cache or CDN mirror was added.
The implementation retains only short-lived rendering assets in memory; this is
not a claim that memory storage is a general exemption from Google's terms.

Google explicitly says photo resource names expire and must not be cached. We
preserve the full fresh photo URL as the rendering identity rather than using a
permanent place ID to retain an old image. A durable photo library would need a
provider/licence that permits that storage.

Sources considered:

- [Google Place Photos](https://developers.google.com/maps/documentation/places/web-service/place-photos)
- [Google Places policies](https://developers.google.com/maps/documentation/places/web-service/policies)
- [Google Maps Platform terms](https://cloud.google.com/maps-platform/terms)
- [Coil shared image loaders and caches](https://coil-kt.github.io/coil/image_loaders/)

The brand catalogue is a maintained list, not a worldwide chain classifier.
Unknown brands still need catalogue entries. Filtering is deterministic and does
not make an AI request or add model cost.

## Verification

| Check | Result |
| --- | --- |
| Backend format/type checks | Passed |
| Backend Deno tests | 107 passed |
| Shared JVM tests | 146 passed |
| Shared Android tests | 40 passed |
| Android app unit tests | 64 passed |
| iOS simulator unit tests | 124 passed |
| Generated catalogue consistency | Passed |
| Git whitespace check | Passed |

Regression coverage includes regional/punctuation aliases, unrelated name
substrings, enabling chains, explicit AI candidates, no AI allowance consumed
when all candidates are excluded, stale Home results and photo cache lifecycle.
Two concurrent iOS card requests plus a return visit used one download and one
decoded image in the test. Expiry, replacement URLs, failure retries and a
cancelled download followed by reloading were checked.

The three `frugal_far` best-match fixture expectations were intentionally updated:
the previous Dart expectations selected McDonald's despite Include chains being
false. They now select the highest remaining non-chain score (r1, r9, r4).
All other recommendation vectors remain unchanged.

`ios-test-summary.json` and `test-summary.json` contain test totals. The final
iOS result bundle is `/private/tmp/lunch-chains-photos-ios-final.xcresult`.
Existing Kotlin/RevenueCat debug-symbol warnings remain; no test errors occurred.

## Deployment and device

`ai-recommend` and `groups-propose` are ACTIVE version 10 in Supabase project
`cswdcbmywzzisovsgwac`; their JWT gateway settings were preserved.
`deployed-functions.json` records the verified versions.

`live-filter-check.json` records five unauthenticated validation requests with
fictional candidates. Excluded Hungry Jack's and Burger King requests stop with
an empty-candidate error; enabled chains and independent/mixed lists proceed to
the sign-in gate. These checks stop before model requests or quota reservation.
They validate deployed filtering, not an authenticated group-hosting flow.

The device build is Debug 1.0.0 (4), bundle `au.iapp.lunch`, development team
`RYM9BD2B27`. Code signing verification passed. The final build, including the
foreground photo retry, was installed over the existing app and launched on
Ray's iPhone 12 Pro. `device-build.json`, `iphone-install.json` and
`iphone-launch.json` record the exact build and successful operations. App data
was preserved; no uninstall was performed.

`tested-source-sha256.json` records the tested application and backend source.
