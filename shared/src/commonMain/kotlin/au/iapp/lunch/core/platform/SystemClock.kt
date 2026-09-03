package au.iapp.lunch.core.platform

import au.iapp.lunch.core.api.Clock

/**
 * Wall clock backed by the platform: epoch seconds and the device's IANA
 * time zone id. Tests inject their own [Clock] instead.
 */
expect object SystemClock : Clock
