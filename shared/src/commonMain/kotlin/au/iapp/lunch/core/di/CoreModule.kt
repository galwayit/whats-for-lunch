package au.iapp.lunch.core.di

import au.iapp.lunch.core.api.AchievementEngine
import au.iapp.lunch.core.api.AchievementRepository
import au.iapp.lunch.core.api.AiRecommendationService
import au.iapp.lunch.core.api.AuthRepository
import au.iapp.lunch.core.api.BudgetEngine
import au.iapp.lunch.core.api.Clock
import au.iapp.lunch.core.api.CoreConfig
import au.iapp.lunch.core.api.EntitlementRepository
import au.iapp.lunch.core.api.FavouritesRepository
import au.iapp.lunch.core.api.GateService
import au.iapp.lunch.core.api.GroupRepository
import au.iapp.lunch.core.api.LocationProvider
import au.iapp.lunch.core.api.MealDefaults
import au.iapp.lunch.core.api.MealRepository
import au.iapp.lunch.core.api.PushRegistrar
import au.iapp.lunch.core.api.RecommendationEngine
import au.iapp.lunch.core.api.RestaurantRepository
import au.iapp.lunch.core.api.UserRepository
import au.iapp.lunch.core.data.AchievementRepositoryImpl
import au.iapp.lunch.core.data.FavouritesRepositoryImpl
import au.iapp.lunch.core.data.MealRepositoryImpl
import au.iapp.lunch.core.data.RestaurantRepositoryImpl
import au.iapp.lunch.core.data.UserRepositoryImpl
import au.iapp.lunch.core.db.DatabaseFactory
import au.iapp.lunch.core.db.LunchDatabase
import au.iapp.lunch.core.engine.AchievementEngineImpl
import au.iapp.lunch.core.engine.BudgetEngineImpl
import au.iapp.lunch.core.engine.MealDefaultsImpl
import au.iapp.lunch.core.engine.RecommendationEngineImpl
import au.iapp.lunch.core.network.BackendClient
import au.iapp.lunch.core.network.BackendHeaders
import au.iapp.lunch.core.network.KtorBackendClient
import au.iapp.lunch.core.service.AiContextBuilder
import au.iapp.lunch.core.service.AiRecommendationServiceImpl
import au.iapp.lunch.core.service.AiUsage
import au.iapp.lunch.core.service.AuthRepositoryImpl
import au.iapp.lunch.core.service.GateServiceImpl
import au.iapp.lunch.core.service.GroupRepositoryImpl
import au.iapp.lunch.core.service.PushRegistrarImpl
import au.iapp.lunch.core.service.createEntitlementRepository
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.functions.Functions
import io.github.jan.supabase.postgrest.Postgrest
import io.ktor.client.engine.HttpClientEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import org.koin.core.module.Module
import org.koin.dsl.module

/**
 * Koin definitions for one core instance. Everything is a singleton inside the
 * isolated Koin application that [au.iapp.lunch.core.LunchCoreFactory] creates,
 * so two cores (or a test per database) never share state.
 */
internal fun coreModule(
    config: CoreConfig,
    location: LocationProvider,
    clock: Clock,
    httpEngine: HttpClientEngine,
): Module = module {
    single { config }
    single { location }
    single { clock }
    single<CoroutineScope> { CoroutineScope(SupervisorJob() + Dispatchers.Default) }

    // Pure engines.
    single<RecommendationEngine> { RecommendationEngineImpl() }
    single<BudgetEngine> { BudgetEngineImpl() }
    single<AchievementEngine> { AchievementEngineImpl() }
    single<MealDefaults> { MealDefaultsImpl() }

    // Storage and remote access.
    single<LunchDatabase> { DatabaseFactory.open(config.databasePath) }
    single<SupabaseClient> {
        createSupabaseClient(config.supabaseUrl, config.supabaseAnonKey) {
            install(Auth)
            install(Postgrest)
            install(Functions)
        }
    }
    single<EntitlementRepository> { createEntitlementRepository(config.revenueCatApiKey, get()) }
    single {
        val supabase = get<SupabaseClient>()
        val entitlements = get<EntitlementRepository>()
        BackendHeaders(
            anonKey = config.supabaseAnonKey,
            accessToken = { supabase.auth.currentAccessTokenOrNull() },
            appUserId = { entitlements.appUserId.value },
            timeZoneId = { clock.timeZoneId() },
        )
    }
    single<BackendClient> { KtorBackendClient(config.backendBaseUrl, get(), httpEngine) }

    // Repositories over the local database.
    single<UserRepository> { UserRepositoryImpl(get(), get(), get()) }
    single<MealRepository> { MealRepositoryImpl(get(), get()) }
    single<RestaurantRepository> { RestaurantRepositoryImpl(get(), get(), get()) }
    single<FavouritesRepository> { FavouritesRepositoryImpl(get(), get(), get()) }
    single<AchievementRepository> { AchievementRepositoryImpl(get(), get(), get()) }

    // Services.
    single { AiUsage(get(), get()) }
    single { AiContextBuilder(get(), get()) }
    single<AuthRepository> { AuthRepositoryImpl(get(), get(), get(), get()) }
    single<GateService> { GateServiceImpl(get(), get(), get(), get()) }
    single<AiRecommendationService> {
        AiRecommendationServiceImpl(get(), get(), get(), get(), get(), get(), get(), get(), get())
    }
    single<GroupRepository> { GroupRepositoryImpl(get(), get(), get()) }
    single<PushRegistrar> { PushRegistrarImpl(get()) }
}
