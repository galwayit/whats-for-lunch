package au.iapp.lunch.core.platform

import io.ktor.client.engine.HttpClientEngine

/** Native Ktor engine for the backend client: OkHttp on the JVM targets, Darwin on iOS. */
internal expect fun createHttpEngine(): HttpClientEngine
