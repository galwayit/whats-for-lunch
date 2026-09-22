#!/usr/bin/env python3
"""Generate Swift and Kotlin design-token sources from design/tokens.json.

Usage: python3 design/generate_tokens.py
Outputs:
  iosApp/LunchApp/DesignSystem/Tokens.swift
  androidApp/src/main/kotlin/au/iapp/lunch/ui/theme/Tokens.kt

No dependencies; run it whenever tokens.json changes and commit the outputs.
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOKENS = os.path.join(ROOT, "design", "tokens.json")
SWIFT_OUT = os.path.join(ROOT, "iosApp", "LunchApp", "DesignSystem", "Tokens.swift")
KOTLIN_OUT = os.path.join(ROOT, "androidApp", "src", "main", "kotlin", "au", "iapp", "lunch", "ui", "theme", "Tokens.kt")

HEADER = "GENERATED FROM design/tokens.json BY design/generate_tokens.py. DO NOT EDIT BY HAND."


def parse_hex(value: str):
    """#RRGGBB or #RRGGBBAA -> (r, g, b, a) floats 0..1."""
    v = value.lstrip("#")
    if len(v) == 6:
        v += "FF"
    if len(v) != 8 or not re.fullmatch(r"[0-9A-Fa-f]{8}", v):
        raise SystemExit(f"bad colour {value}")
    r, g, b, a = (int(v[i:i + 2], 16) for i in (0, 2, 4, 6))
    return r / 255, g / 255, b / 255, a / 255


def argb_long(value: str) -> str:
    v = value.lstrip("#")
    if len(v) == 6:
        v += "FF"
    rr, gg, bb, aa = v[0:2], v[2:4], v[4:6], v[6:8]
    return f"0x{aa}{rr}{gg}{bb}".upper()


def camel(name: str) -> str:
    return name[0].lower() + name[1:]


def gen_swift(t):
    lines = [f"// {HEADER}", "import SwiftUI", "", "public enum Tokens {"]
    lines.append("    public enum Palette {")
    for name, spec in t["color"].items():
        lr, lg, lb, la = parse_hex(spec["light"])
        dr, dg, db, da = parse_hex(spec["dark"])
        lines.append(f"        /// {spec['role']}")
        lines.append(
            f"        public static let {camel(name)} = Color(light: ({lr:.4f}, {lg:.4f}, {lb:.4f}, {la:.4f}), "
            f"dark: ({dr:.4f}, {dg:.4f}, {db:.4f}, {da:.4f}))"
        )
    lines.append("    }")
    lines.append("")
    lines.append("    public enum `Type` {")
    lines.append(f"        public static let family = \"{t['typography']['family']['display']}\"")
    lines.append(f"        public static let textScaleMin: CGFloat = {t['typography']['textScale']['min']}")
    lines.append(f"        public static let textScaleMax: CGFloat = {t['typography']['textScale']['max']}")
    for role, r in t["typography"]["roles"].items():
        upper = "true" if r.get("uppercase") else "false"
        lines.append(
            f"        public static let {role} = TextRole(size: {r['size']}, weight: {r['weight']}, lineHeight: {r['lineHeight']}, tracking: {r['tracking']}, uppercase: {upper})"
        )
    lines.append("    }")
    lines.append("")
    for group in ("spacing", "radius", "size"):
        lines.append(f"    public enum {group.capitalize()} {{")
        for k, v in t[group].items():
            lines.append(f"        public static let {camel(k)}: CGFloat = {v}")
        lines.append("    }")
        lines.append("")
    lines.append("    public enum Motion {")
    for k, v in t["motion"].items():
        for kk, vv in v.items():
            if isinstance(vv, bool):
                lines.append(f"        public static let {camel(k)}{kk[0].upper()}{kk[1:]}: Bool = {'true' if vv else 'false'}")
            elif isinstance(vv, (int, float)):
                suffix = "Seconds" if kk in ("duration", "autoDismiss") else ""
                val = vv / 1000 if suffix else vv
                lines.append(f"        public static let {camel(k)}{kk[0].upper()}{kk[1:]}{suffix}: Double = {val}")
    lines.append("    }")
    lines.append("}")
    lines.append("")
    lines.append("public struct TextRole {")
    lines.append("    public let size: CGFloat; public let weight: Int; public let lineHeight: CGFloat; public let tracking: CGFloat; public let uppercase: Bool")
    lines.append("    public var fontWeight: Font.Weight {")
    lines.append("        switch weight { case 800: return .heavy; case 700: return .bold; case 600: return .semibold; case 500: return .medium; default: return .regular }")
    lines.append("    }")
    lines.append("}")
    lines.append("")
    lines.append("public extension Color {")
    lines.append("    /// sRGB components, in the order red, green, blue, alpha.")
    lines.append("    typealias RGBA = (Double, Double, Double, Double)")
    lines.append("")
    lines.append("    /// Resolves to the light or dark value from the active trait collection.")
    lines.append("    ///")
    lines.append("    /// UIKit resolves a dynamic colour on whichever thread is drawing, and for SwiftUI")
    lines.append("    /// that is often its async render thread rather than the main one. The target builds")
    lines.append("    /// with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so both the initialiser and the")
    lines.append("    /// provider closure have to opt out explicitly: otherwise the closure is treated as")
    lines.append("    /// main-actor work and trips a dispatch queue assertion the moment it is resolved off")
    lines.append("    /// the main thread. For the same reason the components become `UIColor`s up front,")
    lines.append("    /// rather than calling the main-actor-isolated `UIColor(_: Color)` inside the closure.")
    lines.append("    nonisolated init(light: RGBA, dark: RGBA) {")
    lines.append("        let lightColor = UIColor(red: light.0, green: light.1, blue: light.2, alpha: light.3)")
    lines.append("        let darkColor = UIColor(red: dark.0, green: dark.1, blue: dark.2, alpha: dark.3)")
    lines.append("        self.init(uiColor: UIColor { @Sendable trait in")
    lines.append("            trait.userInterfaceStyle == .dark ? darkColor : lightColor")
    lines.append("        })")
    lines.append("    }")
    lines.append("}")
    return "\n".join(lines) + "\n"


def gen_kotlin(t):
    lines = [f"// {HEADER}", "package au.iapp.lunch.ui.theme", "", "import androidx.compose.ui.graphics.Color", "import androidx.compose.ui.unit.dp", "import androidx.compose.ui.unit.sp", ""]
    lines.append("object TokenColors {")
    lines.append("    object Light {")
    for name, spec in t["color"].items():
        lines.append(f"        /** {spec['role']} */")
        lines.append(f"        val {camel(name)} = Color({argb_long(spec['light'])})")
    lines.append("    }")
    lines.append("    object Dark {")
    for name, spec in t["color"].items():
        lines.append(f"        val {camel(name)} = Color({argb_long(spec['dark'])})")
    lines.append("    }")
    lines.append("}")
    lines.append("")
    lines.append("data class TextRole(val size: Int, val weight: Int, val lineHeight: Int, val tracking: Double, val uppercase: Boolean)")
    lines.append("")
    lines.append("object TokenType {")
    lines.append(f"    const val FAMILY = \"{t['typography']['family']['display']}\"")
    lines.append(f"    const val TEXT_SCALE_MIN = {t['typography']['textScale']['min']}f")
    lines.append(f"    const val TEXT_SCALE_MAX = {t['typography']['textScale']['max']}f")
    for role, r in t["typography"]["roles"].items():
        upper = "true" if r.get("uppercase") else "false"
        # tracking is a Double in the Kotlin TextRole; json integers such as 0 must not become Int literals
        lines.append(f"    val {role} = TextRole({r['size']}, {r['weight']}, {r['lineHeight']}, {float(r['tracking'])}, {upper})")
    lines.append("}")
    lines.append("")
    for group in ("spacing", "radius", "size"):
        lines.append(f"object Token{group.capitalize()} {{")
        for k, v in t[group].items():
            lines.append(f"    val {camel(k)} = {v}.dp")
        lines.append("}")
        lines.append("")
    lines.append("object TokenMotion {")
    for k, v in t["motion"].items():
        for kk, vv in v.items():
            name = f"{camel(k)}{kk[0].upper()}{kk[1:]}"
            if isinstance(vv, bool):
                lines.append(f"    const val {name} = {'true' if vv else 'false'}")
            elif isinstance(vv, int):
                lines.append(f"    const val {name}Ms = {vv}")
            elif isinstance(vv, float):
                lines.append(f"    const val {name} = {vv}f")
    lines.append("}")
    return "\n".join(lines) + "\n"


def main():
    with open(TOKENS, encoding="utf-8") as f:
        t = json.load(f)
    for path, content in ((SWIFT_OUT, gen_swift(t)), (KOTLIN_OUT, gen_kotlin(t))):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print("wrote", os.path.relpath(path, ROOT))


if __name__ == "__main__":
    sys.exit(main())
