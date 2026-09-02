import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.sqldelight)
    alias(libs.plugins.skie)
}

kotlin {
    androidTarget {
        compilerOptions { jvmTarget.set(JvmTarget.JVM_17) }
    }
    // JVM target exists so the domain rules and the SQLite layer can be tested
    // on a plain JVM without an emulator.
    jvm("desktop")

    listOf(iosArm64(), iosSimulatorArm64()).forEach { target ->
        target.binaries.framework {
            baseName = "LunchCore"
            isStatic = true
        }
    }

    sourceSets {
        commonMain.dependencies {
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.kotlinx.serialization.json)
            implementation(libs.kotlinx.datetime)
            implementation(libs.ktor.client.core)
            implementation(libs.ktor.client.content.negotiation)
            implementation(libs.ktor.serialization.kotlinx.json)
            implementation(libs.ktor.client.logging)
            implementation(libs.sqldelight.runtime)
            implementation(libs.sqldelight.coroutines)
            implementation(libs.koin.core)
            implementation(libs.kermit)
            implementation(libs.multiplatform.settings)
            implementation(libs.supabase.auth)
            implementation(libs.supabase.postgrest)
            implementation(libs.supabase.functions)
            implementation(libs.revenuecat.core)
        }
        commonTest.dependencies {
            implementation(kotlin("test"))
            implementation(libs.kotlinx.coroutines.test)
            implementation(libs.ktor.client.mock)
            implementation(libs.turbine)
        }
        androidMain.dependencies {
            implementation(libs.ktor.client.okhttp)
            implementation(libs.sqldelight.android.driver)
            implementation(libs.kotlinx.coroutines.android)
            implementation(libs.koin.android)
        }
        iosMain.dependencies {
            implementation(libs.ktor.client.darwin)
            implementation(libs.sqldelight.native.driver)
        }
        val desktopMain by getting {
            dependencies {
                implementation(libs.ktor.client.okhttp)
                implementation(libs.sqldelight.sqlite.driver)
            }
        }
        val desktopTest by getting {
            dependencies {
                implementation(libs.sqldelight.sqlite.driver)
            }
        }
    }
}

android {
    namespace = "au.iapp.lunch.core"
    compileSdk = libs.versions.compileSdk.get().toInt()
    defaultConfig { minSdk = libs.versions.minSdk.get().toInt() }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

sqldelight {
    databases {
        create("LunchDatabase") {
            packageName.set("au.iapp.lunch.core.db")
            // Schema must mirror the Drift schema v6 so an existing
            // diet_buddy.sqlite opens unchanged. See shared/README.md.
            schemaOutputDirectory.set(file("src/commonMain/sqldelight/schema"))
            verifyMigrations.set(false)
        }
    }
}

skie {
    features {
        // Kotlin Flow -> Swift AsyncSequence, sealed classes -> Swift enums.
        coroutinesInterop.set(true)
    }
}
