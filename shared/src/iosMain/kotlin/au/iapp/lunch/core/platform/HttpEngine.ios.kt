package au.iapp.lunch.core.platform

import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.darwin.Darwin

internal actual fun createHttpEngine(): HttpClientEngine = Darwin.create()
