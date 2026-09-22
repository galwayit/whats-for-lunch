plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
}

/** A quoted string literal for BuildConfig from `-Plunch.<property>` or `$env`, else "". */
fun lunchSecret(property: String, env: String): String {
    val value = (project.findProperty("lunch.$property") as? String)?.takeIf { it.isNotBlank() }
        ?: System.getenv(env).orEmpty()
    return "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
}

android {
    namespace = "au.iapp.lunch"
    compileSdk = libs.versions.compileSdk.get().toInt()

    defaultConfig {
        // Same application id as the Flutter app so the store update path and
        // the existing diet_buddy.sqlite carry over.
        applicationId = "au.iapp.guess_what.what_we_have_for_lunch"
        minSdk = libs.versions.minSdk.get().toInt()
        targetSdk = libs.versions.targetSdk.get().toInt()
        versionCode = 2
        versionName = "2.0.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            // Release signing is configured in Phase 4; debug signing must not ship.
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    defaultConfig {
        // Backend configuration mirrors iosApp/LunchApp/Config/Lunch.plist.example. Values come
        // from Gradle properties (-Plunch.supabaseUrl=...) or environment variables
        // (LUNCH_SUPABASE_URL, ...) and default to empty, in which case the app shows the
        // "not configured" screen. Never commit real values.
        buildConfigField("String", "LUNCH_SUPABASE_URL", lunchSecret("supabaseUrl", "LUNCH_SUPABASE_URL"))
        buildConfigField("String", "LUNCH_SUPABASE_ANON_KEY", lunchSecret("supabaseAnonKey", "LUNCH_SUPABASE_ANON_KEY"))
        buildConfigField("String", "LUNCH_BACKEND_BASE_URL", lunchSecret("backendBaseUrl", "LUNCH_BACKEND_BASE_URL"))
        buildConfigField("String", "LUNCH_REVENUECAT_API_KEY", lunchSecret("revenueCatApiKey", "LUNCH_REVENUECAT_API_KEY"))
        buildConfigField("String", "LUNCH_INVITE_LINK_BASE", lunchSecret("inviteLinkBase", "LUNCH_INVITE_LINK_BASE"))
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }

    packaging { resources.excludes += "/META-INF/{AL2.0,LGPL2.1}" }
}

dependencies {
    implementation(project(":shared"))

    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.tooling.preview)
    implementation(libs.compose.foundation)
    implementation(libs.compose.material3)
    // Material Icons stand-ins for the Material Symbols subset (see res/README.md).
    implementation(libs.compose.material.icons.extended)
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.koin.android)
    implementation(libs.koin.compose)
    implementation(libs.coil.compose)
    implementation(libs.coil.network.okhttp)
    implementation(libs.play.services.location)

    debugImplementation(libs.compose.ui.tooling)
    debugImplementation(libs.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    androidTestImplementation(libs.androidx.test.junit)
    androidTestImplementation(libs.espresso.core)
    androidTestImplementation(platform(libs.compose.bom))
    androidTestImplementation(libs.compose.ui.test.junit4)
}
