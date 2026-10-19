/**
 * @file SplitTestSupport.kt
 * @description Test helpers for the split sheet: the `split_*` copy read straight from
 * src/main/res/values/strings.xml (so assertions use the words the app ships, and a missing key
 * fails loudly), and an in-memory "Pay me at" store.
 * @author AI Assistant
 * @date 2026-09-23
 */
package au.iapp.lunch.ui.features

import au.iapp.lunch.ui.features.split.PayIdStore
import au.iapp.lunch.ui.features.split.SplitCopy
import java.io.File

object SplitTestCopy {
    private val strings: Map<String, String> by lazy {
        // Unit tests run with androidApp/ as the working directory.
        val file = File(System.getProperty("user.dir"), "src/main/res/values/strings.xml")
        Regex("""<string name="([a-z0-9_]+)"[^>]*>(.*?)</string>""")
            .findAll(file.readText())
            .associate { it.groupValues[1] to it.groupValues[2].replace("\\'", "'").replace("\\\"", "\"").replace("&amp;", "&") }
    }

    private fun string(name: String): String = strings[name] ?: error("strings.xml has no $name")

    /** Mirrors `rememberSplitCopy()` in SplitBillSheet.kt. */
    val copy: SplitCopy by lazy {
        SplitCopy(
            you = string("split_person_you"),
            personNumbered = string("split_person_n"),
            total = string("split_total"),
            totalWithSurcharge = string("split_total_surcharge"),
            errorNoBill = string("split_error_no_bill"),
            errorNoPeople = string("split_error_no_people"),
            errorTooMany = string("split_error_too_many"),
            errorSurcharge = string("split_error_surcharge"),
            errorOver = string("split_error_over"),
            errorUnder = string("split_error_under"),
            placeFallback = string("split_message_place_fallback"),
            messageHeader = string("split_message_header"),
            messageLine = string("split_message_line"),
            messagePay = string("split_message_pay"),
            messageFooter = string("split_message_footer"),
            note = string("split_note"),
        )
    }
}

class InMemoryPayIdStore(var saved: String = "") : PayIdStore {
    override fun load(): String = saved
    override fun save(value: String) {
        saved = if (value.isBlank()) "" else value
    }
}
