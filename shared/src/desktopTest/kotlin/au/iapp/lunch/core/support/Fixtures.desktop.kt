package au.iapp.lunch.core.support

import java.io.File

actual fun readFixture(name: String): String = JvmFixtures.read(name)

/** Shared JVM lookup: classpath first, then the module source tree. */
object JvmFixtures {
    fun read(name: String): String {
        val fromClasspath = JvmFixtures::class.java.classLoader?.getResourceAsStream("fixtures/$name")
        if (fromClasspath != null) return fromClasspath.use { it.readBytes().decodeToString() }
        val file = File("src/commonTest/resources/fixtures/$name")
        require(file.exists()) { "Fixture $name not found on the classpath or at ${file.absolutePath}" }
        return file.readText()
    }

    /** Copies a binary fixture to a temporary file and returns it. */
    fun copyToTemp(name: String, suffix: String): File {
        val target = File.createTempFile("lunch-fixture-", suffix)
        val fromClasspath = JvmFixtures::class.java.classLoader?.getResourceAsStream("fixtures/$name")
        if (fromClasspath != null) {
            fromClasspath.use { input -> target.outputStream().use { input.copyTo(it) } }
        } else {
            File("src/commonTest/resources/fixtures/$name").copyTo(target, overwrite = true)
        }
        target.deleteOnExit()
        return target
    }
}
