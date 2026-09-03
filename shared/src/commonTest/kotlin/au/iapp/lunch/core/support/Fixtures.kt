package au.iapp.lunch.core.support

/**
 * Reads a file from commonTest/resources/fixtures. JVM targets use the test
 * classpath (falling back to the source tree, since Android unit tests do not
 * always package common resources); iOS resolves relative to the working
 * directory.
 */
expect fun readFixture(name: String): String
