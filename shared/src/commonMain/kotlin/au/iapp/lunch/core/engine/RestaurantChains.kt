// Generated from shared/restaurant-chains.json. Do not edit the aliases here.
package au.iapp.lunch.core.engine

object RestaurantChains {
    private val aliases = listOf(
        "burger king",
        "burgerking",
        "chicken treat",
        "dominos",
        "grilld",
        "guzman y gomez",
        "hungry jacks",
        "hungryjacks",
        "kentucky fried chicken",
        "kfc",
        "mcdonald",
        "mcdonalds",
        "nandos",
        "oporto",
        "pizza hut",
        "red rooster",
        "starbucks",
        "subway",
        "taco bell",
        "the coffee club",
        "zambrero",
    )
    private val apostrophes = Regex("['’‘ʼ`]")
    private val separators = Regex("[^a-z0-9]+")

    fun matches(name: String): Boolean {
        val normalised = separators.replace(apostrophes.replace(name.lowercase(), ""), " ").trim()
        return aliases.any { " $normalised ".contains(" $it ") }
    }
}
