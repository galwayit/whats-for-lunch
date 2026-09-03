package au.iapp.lunch.core.support

import platform.Foundation.NSFileManager
import platform.Foundation.NSString
import platform.Foundation.NSUTF8StringEncoding
import platform.Foundation.stringWithContentsOfFile

actual fun readFixture(name: String): String {
    val base = NSFileManager.defaultManager.currentDirectoryPath
    val path = "$base/src/commonTest/resources/fixtures/$name"
    @Suppress("CAST_NEVER_SUCCEEDS")
    return (NSString.stringWithContentsOfFile(path, NSUTF8StringEncoding, null) as? String)
        ?: error("Fixture $name not found at $path")
}
