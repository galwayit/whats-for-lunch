// Root build script. Plugins are declared here with apply = false so that
// version resolution happens once; each module applies what it needs.
plugins {
    alias(libs.plugins.kotlin.multiplatform) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.sqldelight) apply false
    alias(libs.plugins.skie) apply false
}
