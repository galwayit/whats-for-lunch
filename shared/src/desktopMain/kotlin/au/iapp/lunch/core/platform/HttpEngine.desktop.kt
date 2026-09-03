package au.iapp.lunch.core.platform

import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.okhttp.OkHttp

internal actual fun createHttpEngine(): HttpClientEngine = OkHttp.create()
