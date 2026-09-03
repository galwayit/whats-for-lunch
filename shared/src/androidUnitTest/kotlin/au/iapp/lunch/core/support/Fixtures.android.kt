package au.iapp.lunch.core.support

import java.io.File

actual fun readFixture(name: String): String {
    val fromClasspath = FixtureAnchor::class.java.classLoader?.getResourceAsStream("fixtures/$name")
    if (fromClasspath != null) return fromClasspath.use { it.readBytes().decodeToString() }
    val file = File("src/commonTest/resources/fixtures/$name")
    require(file.exists()) { "Fixture $name not found on the classpath or at ${file.absolutePath}" }
    return file.readText()
}

private object FixtureAnchor
