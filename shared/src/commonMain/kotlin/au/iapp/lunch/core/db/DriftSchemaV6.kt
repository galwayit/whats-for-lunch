package au.iapp.lunch.core.db

/**
 * The Drift schema at version 6, verbatim from the database the Flutter app
 * created (see commonTest/resources/fixtures/drift_schema_v6.sql).
 *
 * The statements are executed as-is when a database file is brand new so the
 * resulting `sqlite_master` is byte-identical to a Flutter-created file.
 * Drift issues `CREATE TABLE IF NOT EXISTS` / `CREATE INDEX IF NOT EXISTS`;
 * SQLite drops the `IF NOT EXISTS` when it stores the text, which is why the
 * dump shows plain `CREATE ...`.
 *
 * Generated from the fixture; do not hand-edit. Table order is Drift's
 * `@DriftDatabase(tables: [...])` order, index order is
 * `_createOptimizedIndexes` then `_createLearningSignalIndexes`.
 */
internal object DriftSchemaV6 {
    const val VERSION: Long = 6

    /** Table name to its CREATE statement, in Drift creation order. */
    val tables: Map<String, String> = linkedMapOf(
        "users" to """CREATE TABLE IF NOT EXISTS "users" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "name" TEXT NOT NULL, "preferences" TEXT NOT NULL, "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))""",
        "meals" to """CREATE TABLE IF NOT EXISTS "meals" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "user_id" INTEGER NOT NULL REFERENCES users (id), "restaurant_id" TEXT NULL, "meal_type" TEXT NOT NULL, "cost" REAL NOT NULL, "date" INTEGER NOT NULL, "restaurant_name" TEXT NULL, "notes" TEXT NULL, "photo_ids" TEXT NOT NULL DEFAULT '[]')""",
        "budget_trackings" to """CREATE TABLE IF NOT EXISTS "budget_trackings" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "user_id" INTEGER NOT NULL REFERENCES users (id), "amount" REAL NOT NULL, "category" TEXT NOT NULL, "date" INTEGER NOT NULL)""",
        "restaurants" to """CREATE TABLE IF NOT EXISTS "restaurants" ("place_id" TEXT NOT NULL, "name" TEXT NOT NULL, "location" TEXT NOT NULL, "address" TEXT NULL, "phone_number" TEXT NULL, "website" TEXT NULL, "latitude" REAL NULL, "longitude" REAL NULL, "distance_from_user" REAL NULL, "rating" REAL NULL, "review_count" INTEGER NULL, "price_level" INTEGER NULL, "price_ranges" TEXT NOT NULL DEFAULT '[]', "cuisine_type" TEXT NULL, "cuisine_types" TEXT NOT NULL DEFAULT '[]', "supported_dietary_restrictions" TEXT NOT NULL DEFAULT '[]', "allergen_info" TEXT NOT NULL DEFAULT '[]', "dietary_compatibility_scores" TEXT NOT NULL DEFAULT '{}', "has_verified_dietary_info" INTEGER NOT NULL DEFAULT 0 CHECK ("has_verified_dietary_info" IN (0, 1)), "community_verification_count" INTEGER NOT NULL DEFAULT 0, "opening_hours" TEXT NOT NULL DEFAULT '[]', "is_open_now" INTEGER NOT NULL DEFAULT 0 CHECK ("is_open_now" IN (0, 1)), "current_wait_time" TEXT NULL, "features" TEXT NOT NULL DEFAULT '[]', "average_meal_cost" REAL NULL, "value_score" REAL NULL, "meal_type_average_costs" TEXT NOT NULL DEFAULT '{}', "cached_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), "last_verified" INTEGER NULL, "photo_reference" TEXT NULL, "photo_references" TEXT NOT NULL DEFAULT '[]', PRIMARY KEY ("place_id"))""",
        "restaurant_cache" to """CREATE TABLE IF NOT EXISTS "restaurant_cache" ("place_id" TEXT NOT NULL, "search_query" TEXT NOT NULL, "user_latitude" REAL NOT NULL, "user_longitude" REAL NOT NULL, "cached_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), "expires_at" INTEGER NOT NULL, PRIMARY KEY ("place_id", "search_query"))""",
        "dietary_compatibility" to """CREATE TABLE IF NOT EXISTS "dietary_compatibility" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "place_id" TEXT NOT NULL REFERENCES restaurants (place_id), "dietary_restriction" TEXT NOT NULL, "compatibility_score" REAL NOT NULL, "is_community_verified" INTEGER NOT NULL DEFAULT 0 CHECK ("is_community_verified" IN (0, 1)), "verification_count" INTEGER NOT NULL DEFAULT 0, "last_verified" INTEGER NULL)""",
        "user_discovery_history" to """CREATE TABLE IF NOT EXISTS "user_discovery_history" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "user_id" INTEGER NOT NULL REFERENCES users (id), "place_id" TEXT NOT NULL REFERENCES restaurants (place_id), "search_query" TEXT NULL, "applied_filters" TEXT NOT NULL DEFAULT '{}', "was_selected" INTEGER NOT NULL DEFAULT 0 CHECK ("was_selected" IN (0, 1)), "viewed_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))""",
        "a_i_recommendations" to """CREATE TABLE IF NOT EXISTS "a_i_recommendations" ("id" TEXT NOT NULL, "user_id" INTEGER NOT NULL REFERENCES users (id), "recommended_restaurant_ids" TEXT NOT NULL, "reasoning" TEXT NOT NULL, "factor_weights" TEXT NOT NULL DEFAULT '{}', "overall_confidence" REAL NOT NULL, "user_context" TEXT NOT NULL DEFAULT '{}', "generated_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), "was_accepted" INTEGER NOT NULL DEFAULT 0 CHECK ("was_accepted" IN (0, 1)), "user_feedback" TEXT NULL, "metadata" TEXT NOT NULL DEFAULT '{}', "expires_at" INTEGER NOT NULL, PRIMARY KEY ("id"))""",
        "a_i_recommendation_feedback" to """CREATE TABLE IF NOT EXISTS "a_i_recommendation_feedback" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "recommendation_id" TEXT NOT NULL REFERENCES a_i_recommendations (id), "user_id" INTEGER NOT NULL REFERENCES users (id), "place_id" TEXT NOT NULL REFERENCES restaurants (place_id), "rating" INTEGER NOT NULL, "feedback_text" TEXT NULL, "was_selected" INTEGER NOT NULL DEFAULT 0 CHECK ("was_selected" IN (0, 1)), "submitted_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))""",
        "a_i_usage_metrics" to """CREATE TABLE IF NOT EXISTS "a_i_usage_metrics" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "user_id" INTEGER NOT NULL REFERENCES users (id), "request_type" TEXT NOT NULL, "tokens_used" INTEGER NOT NULL DEFAULT 0, "cost_in_cents" REAL NOT NULL DEFAULT 0.0, "response_time_ms" INTEGER NULL, "was_successful" INTEGER NOT NULL DEFAULT 1 CHECK ("was_successful" IN (0, 1)), "error_message" TEXT NULL, "timestamp" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))""",
        "photos" to """CREATE TABLE IF NOT EXISTS "photos" ("id" TEXT NOT NULL, "user_id" INTEGER NOT NULL REFERENCES users (id), "file_name" TEXT NOT NULL, "local_path" TEXT NOT NULL, "cloud_url" TEXT NULL, "file_size_bytes" INTEGER NOT NULL, "width" INTEGER NULL, "height" INTEGER NULL, "content_type" TEXT NOT NULL DEFAULT 'image/jpeg', "photo_type" TEXT NOT NULL, "associated_entity_id" TEXT NULL, "metadata" TEXT NOT NULL DEFAULT '{}', "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), "uploaded_at" INTEGER NULL, "is_uploaded" INTEGER NOT NULL DEFAULT 0 CHECK ("is_uploaded" IN (0, 1)), "is_deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("is_deleted" IN (0, 1)), PRIMARY KEY ("id"))""",
        "user_restaurant_interactions" to """CREATE TABLE IF NOT EXISTS "user_restaurant_interactions" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "user_id" INTEGER NOT NULL, "restaurant_place_id" TEXT NOT NULL, "restaurant_name" TEXT NULL, "interaction_type" TEXT NOT NULL, "interaction_date" INTEGER NOT NULL, "context" TEXT NULL)""",
        "meal_outcomes" to """CREATE TABLE IF NOT EXISTS "meal_outcomes" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "meal_id" INTEGER NOT NULL, "user_id" INTEGER NOT NULL, "restaurant_place_id" TEXT NULL, "rating" INTEGER NULL, "would_revisit" INTEGER NOT NULL DEFAULT 0 CHECK ("would_revisit" IN (0, 1)), "feedback" TEXT NULL, "recorded_at" INTEGER NOT NULL)""",
    )

    /** Indexes from `_createOptimizedIndexes` (schema v4). */
    val optimizedIndexes: List<String> = listOf(
        """CREATE INDEX IF NOT EXISTS idx_meals_user_date ON meals(user_id, date DESC)""",
        """CREATE INDEX IF NOT EXISTS idx_restaurants_location ON restaurants(latitude, longitude)""",
        """CREATE INDEX IF NOT EXISTS idx_restaurants_rating_price ON restaurants(rating DESC, price_level)""",
        """CREATE INDEX IF NOT EXISTS idx_budget_user_date ON budget_trackings(user_id, date DESC)""",
        """CREATE INDEX IF NOT EXISTS idx_discovery_user_date ON user_discovery_history(user_id, viewed_at DESC)""",
        """CREATE INDEX IF NOT EXISTS idx_ai_recommendations_expires ON a_i_recommendations(expires_at)""",
        """CREATE INDEX IF NOT EXISTS idx_restaurant_cache_expires ON restaurant_cache(expires_at)""",
        """CREATE INDEX IF NOT EXISTS idx_restaurants_filter ON restaurants(is_open_now, has_verified_dietary_info, rating DESC)""",
    )

    /** Indexes from `_createLearningSignalIndexes` (schema v6). */
    val learningSignalIndexes: List<String> = listOf(
        """CREATE INDEX IF NOT EXISTS idx_interactions_user_type ON user_restaurant_interactions(user_id, interaction_type, interaction_date DESC)""",
        """CREATE INDEX IF NOT EXISTS idx_interactions_place ON user_restaurant_interactions(restaurant_place_id, interaction_date DESC)""",
        """CREATE INDEX IF NOT EXISTS idx_meal_outcomes_user ON meal_outcomes(user_id, recorded_at DESC)""",
    )

    /** Everything `onCreate` runs: all tables, then both index groups. */
    val createStatements: List<String>
        get() = tables.values + optimizedIndexes + learningSignalIndexes

    /** All 13 Drift table names. */
    val tableNames: Set<String> get() = tables.keys
}
