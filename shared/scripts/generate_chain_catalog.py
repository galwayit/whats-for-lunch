"""One catalogue for Swift, Kotlin and Edge Functions. Run with --check in CI."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
catalog = json.loads((ROOT / "shared/restaurant-chains.json").read_text())
aliases = sorted({alias for brand in catalog["brands"] for alias in brand["aliases"]})
assert all(alias and all(c.isascii() and (c.isalnum() or c == " ") for c in alias) for alias in aliases)
lines = "\n".join(f"        {json.dumps(alias)}," for alias in aliases)
outputs = {
    "shared/src/commonMain/kotlin/au/iapp/lunch/core/engine/RestaurantChains.kt": f'''// Generated from shared/restaurant-chains.json. Do not edit the aliases here.
package au.iapp.lunch.core.engine

object RestaurantChains {{
    private val aliases = listOf(
{lines}
    )
    private val apostrophes = Regex("['’‘ʼ`]")
    private val separators = Regex("[^a-z0-9]+")

    fun matches(name: String): Boolean {{
        val normalised = separators.replace(apostrophes.replace(name.lowercase(), ""), " ").trim()
        return aliases.any {{ " $normalised ".contains(" $it ") }}
    }}
}}
''',
    "iosApp/LunchApp/Core/Engines/RestaurantChains.swift": f'''// Generated from shared/restaurant-chains.json. Do not edit the aliases here.
import Foundation

nonisolated enum RestaurantChains {{
    private static let aliases = [
{lines}
    ]

    static func matches(_ name: String) -> Bool {{
        let normalised = name.lowercased()
            .replacingOccurrences(of: "['’‘ʼ`]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        return aliases.contains {{ " \\(normalised) ".contains(" \\($0) ") }}
    }}
}}
''',
    "backend/supabase/functions/_shared/restaurant-chains.ts": '''// Generated from shared/restaurant-chains.json. Do not edit the aliases here.
const aliases = [
''' + "\n".join(f"  {json.dumps(alias)}," for alias in aliases) + '''
];

export function isChainRestaurant(name: string): boolean {
  const normalised = name.toLowerCase().replace(/['’‘ʼ`]/g, "").replace(/[^a-z0-9]+/g, " ").trim();
  return aliases.some((alias) => ` ${normalised} `.includes(` ${alias} `));
}
''',
}
check = argparse.ArgumentParser()
check.add_argument("--check", action="store_true")
args = check.parse_args()
for relative, content in outputs.items():
    path = ROOT / relative
    if args.check:
        if not path.exists() or path.read_text() != content:
            raise SystemExit(f"Stale chain catalogue: {relative}; run {Path(__file__).relative_to(ROOT)}")
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
print(f"Chain catalogue {'checked' if args.check else 'generated'} for {len(outputs)} platforms")
