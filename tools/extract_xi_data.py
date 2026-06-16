#!/usr/bin/env python3
"""
Extract xi definitions from scripts/ninking/xi_detector.gd → embed into HTML.

方案 b: preserves existing cond/tier/tierLabel fields from HTML (hand-authored).
Only synchronizes name/mult/chips from GDScript.

Usage:
    python tools/extract_xi_data.py docs/ninking/ninja_card_viewer.html
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
GD_PATH = REPO_ROOT / "scripts" / "ninking" / "xi_detector.gd"

COMBO_NAMES = {"三合", "双合", "一合"}

# ─── helpers ──────────────────────────────────────────


def _skip_comment(text: str, i: int) -> int:
    """Advance past a # line comment."""
    while i < len(text) and text[i] != "\n":
        i += 1
    return i


def _next_bracket_depth(text: str, start: int, open_b: str = "[", close_b: str = "]") -> int:
    """Return index after the matching close bracket, handling strings and # comments."""
    depth = 1
    i = start
    in_str = False
    str_char = None
    while i < len(text) and depth > 0:
        ch = text[i]
        if in_str:
            if ch == "\\":
                i += 2
                continue
            if ch == str_char:
                in_str = False
        else:
            if ch in ('"', "'"):
                in_str = True
                str_char = ch
            elif ch == "#":
                i = _skip_comment(text, i)
                continue
            elif ch == open_b:
                depth += 1
            elif ch == close_b:
                depth -= 1
        i += 1
    return i


def _parse_keyvals(obj_text: str) -> dict:
    """Parse 'key: val, key: "str", ...' into a dict.
    Handles both quoted keys ("name":) and unquoted keys (name:).
    """
    entry = {}
    for m in re.finditer(r'"?(\w+)"?\s*:\s*("[^"]*"|\'[^\']*\'|-?\d+\.?\d*)', obj_text):
        key = m.group(1)
        val = m.group(2)
        if val.startswith('"') or val.startswith("'"):
            entry[key] = val.strip("\"'")
        else:
            entry[key] = int(val) if "." not in val else float(val)
    return entry


def _format_js_entry(entry: dict, keys: list[str]) -> str:
    """Format a dict as '{ key: val, ... }' JS object literal."""
    parts = []
    for k in keys:
        v = entry.get(k)
        if v is None:
            continue
        if isinstance(v, str):
            parts.append(f"{k}: \"{v}\"")
        else:
            parts.append(f"{k}: {v}")
    return "  { " + ", ".join(parts) + " },"


# ─── extract from GDScript ────────────────────────────


def extract_from_gd(gd_path: Path) -> list[dict]:
    """Parse XI_DEFINITIONS from GDScript → list of {name, x_mult, chips}."""
    text = gd_path.read_text(encoding="utf-8")

    marker = "const XI_DEFINITIONS: Array[Dictionary] = ["
    start = text.find(marker)
    if start < 0:
        raise ValueError("Cannot find XI_DEFINITIONS in GDScript")

    # Skip past "Array[Dictionary] = " to find the actual Array opening [
    equals = text.index("=", start)
    bracket = text.index("[", equals)
    end = _next_bracket_depth(text, bracket + 1)
    raw = text[bracket + 1 : end - 1]

    # Strip # comments (outside strings)
    cleaned: list[str] = []
    for line in raw.split("\n"):
        in_str = False
        sc = None
        for j, ch in enumerate(line):
            if in_str:
                if ch == "\\":
                    continue
                if ch == sc:
                    in_str = False
            else:
                if ch in ('"', "'"):
                    in_str = True
                    sc = ch
                elif ch == "#":
                    cleaned.append(line[:j].rstrip())
                    break
        else:
            cleaned.append(line.rstrip())
    raw = "\n".join(cleaned)

    entries = []
    i = 0
    while i < len(raw):
        ch = raw[i]
        if ch == "{":
            end = _next_bracket_depth(raw, i + 1, "{", "}")
            obj_text = raw[i:end]
            entry = _parse_keyvals(obj_text)
            if entry.get("name"):
                entries.append(entry)
            i = end
        else:
            i += 1

    return entries


# ─── parse existing HTML arrays ────────────────────────


def _extract_array_block(
    text: str, var_name: str, sentinel: str
) -> tuple[str, int, int]:
    """Extract the raw array content between [] delimiters.

    Returns (content_within_brackets, start_of_decl, end_of_line).
    end_of_line is past the `];` and any trailing comment, so the full line is consumed.
    """
    marker = f"const {var_name} = ["
    decl_start = text.find(marker)
    if decl_start < 0:
        return "", -1, -1

    bracket = text.index("[", decl_start)
    end = _next_bracket_depth(text, bracket + 1)
    # end points past the closing `]`
    array_content = text[bracket + 1 : end - 1]

    # Find `];` — the semicolon after the closing bracket
    semicolon = text.find(";", end)
    if semicolon < 0:
        # No semicolon at all — shouldn't happen in valid JS
        return array_content, decl_start, end

    # Check for sentinel comment on the same line
    sentinel_pos = text.find(sentinel, semicolon)
    if sentinel_pos >= 0:
        # Consume the entire comment line
        eol = text.find("\n", sentinel_pos)
        consume_end = eol + 1 if eol >= 0 else len(text)
    else:
        # No sentinel — consume `];` and the trailing newline
        eol = text.find("\n", semicolon)
        consume_end = eol + 1 if eol >= 0 else semicolon + 1

    return array_content, decl_start, consume_end


def _parse_array_entries(content: str) -> list[dict]:
    """Parse '{ key: val, ... }' objects from raw array text."""
    entries = []
    i = 0
    while i < len(content):
        if content[i] == "{":
            end = _next_bracket_depth(content, i + 1, "{", "}")
            obj_text = content[i:end]
            entry = _parse_keyvals(obj_text)
            if entry.get("name"):
                entries.append(entry)
            i = end
        else:
            i += 1
    return entries


def parse_html_arrays(html_text: str) -> dict:
    """Return {basic: [...], phase_e: [...], combos: [...]} from HTML."""
    result = {}
    for var_name, sentinel_suffix in [
        ("XI_BASIC", "xi-auto-extracted:basic"),
        ("XI_PHASE_E", "xi-auto-extracted:phase-e"),
        ("XI_COMBOS", "xi-auto-extracted:combos"),
    ]:
        content, _, _ = _extract_array_block(html_text, var_name, sentinel_suffix)
        result[var_name] = _parse_array_entries(content)
    return result


# ─── merge ──────────────────────────────────────────────


def merge_entries(
    html_entries: list[dict], gd_by_name: dict, keys: list[str], is_combo: bool = False
) -> list[dict]:
    """Merge GDScript values into HTML entries, preserving order and extra fields.

    For each HTML entry: update mult/chips from GDScript, keep cond/tier/tierLabel.
    For GDScript entries not in HTML: append with defaults.
    """
    seen = set()
    merged = []

    for html_entry in html_entries:
        name = html_entry.get("name", "")
        seen.add(name)
        gd = gd_by_name.get(name)
        if gd:
            html_entry["mult"] = gd.get("x_mult", html_entry.get("mult", 0))
            html_entry["chips"] = gd.get("chips", html_entry.get("chips", 0))
        merged.append(html_entry)

    # Add new entries from GDScript not in HTML
    for name, gd in gd_by_name.items():
        if name not in seen:
            entry = {
                "name": name,
                "mult": gd.get("x_mult", 0),
                "chips": gd.get("chips", 0),
                "cond": name,
                "tier": "",
                "tierLabel": "",
            }
            merged.append(entry)

    return merged


def format_array(entries: list[dict], keys: list[str]) -> str:
    """Format entries as JS const array."""
    lines = [_format_js_entry(e, keys) for e in entries]
    return "\n".join(lines)


# ─── main ──────────────────────────────────────────────


def build_gd_lookup(gd_entries: list[dict]) -> dict:
    """Build name → {x_mult, chips} from GDScript entries."""
    lookup = {}
    for e in gd_entries:
        lookup[e["name"]] = {
            "x_mult": e.get("x_mult", 0),
            "chips": e.get("chips", 0),
        }
    return lookup


def embed_into_html(html_path: Path) -> None:
    html = html_path.read_text(encoding="utf-8")

    # 1. Extract from GDScript
    print("Parsing XI_DEFINITIONS from GDScript...", file=sys.stderr)
    gd_entries = extract_from_gd(GD_PATH)
    print(f"  Found {len(gd_entries)} definitions", file=sys.stderr)

    # 2. Parse existing HTML arrays
    print("Parsing existing xi arrays from HTML...", file=sys.stderr)
    html_arrays = parse_html_arrays(html)

    # 3. Split GDScript entries by position
    # GDScript flat array: indices 0-8 = basic, 9-16 = phase-e, 17-19 = combos (三合/双合/一合)
    # But we split by content: non-combo first, then by position
    non_combo = [e for e in gd_entries if e["name"] not in COMBO_NAMES]
    gd_subsets = {
        "XI_BASIC": build_gd_lookup(non_combo[:9]),     # 全黑 → 全三条 (indices 0-8)
        "XI_PHASE_E": build_gd_lookup(non_combo[9:]),    # 豹子 → 满堂 (indices 9-16)
        "XI_COMBOS": build_gd_lookup(
            [e for e in gd_entries if e["name"] in COMBO_NAMES]
        ),
    }

    # 4. Merge each array with its correct subset
    array_configs = [
        ("XI_BASIC", ["id", "name", "cond", "mult", "chips", "tier", "tierLabel"]),
        ("XI_PHASE_E", ["id", "name", "cond", "mult", "chips", "tier", "tierLabel"]),
        ("XI_COMBOS", ["name", "cond", "mult", "tier"]),
    ]

    merged_results = {}
    for var_name, keys in array_configs:
        merged = merge_entries(
            html_arrays[var_name], gd_subsets[var_name], keys
        )
        merged_results[var_name] = format_array(merged, keys)

    # 5. Replace in HTML
    sentinel_map = {
        "XI_BASIC": "xi-auto-extracted:basic",
        "XI_PHASE_E": "xi-auto-extracted:phase-e",
        "XI_COMBOS": "xi-auto-extracted:combos",
    }

    for var_name, _ in array_configs:
        sentinel = sentinel_map[var_name]

        _, decl_start, sentinel_end = _extract_array_block(
            html, var_name, sentinel
        )
        if decl_start < 0:
            print(f"  ⚠  Cannot find {var_name} in HTML, skipping", file=sys.stderr)
            continue

        before = html[:decl_start]
        after = html[sentinel_end:]

        new_array = (
            f"const {var_name} = [\n{merged_results[var_name]}\n];  // ── {sentinel} ──\n"
        )
        html = before + new_array + after
        print(f"  ✓ Updated {var_name}", file=sys.stderr)

    html_path.write_bytes(html.encode("utf-8"))
    print(f"\n✅ Saved {html_path}", file=sys.stderr)


def main():
    args = sys.argv[1:]
    if args and args[0].endswith(".html"):
        embed_into_html(Path(args[0]))
    else:
        # stdout: JSON preview
        entries = extract_from_gd(GD_PATH)
        import json

        json.dump(entries, sys.stdout, ensure_ascii=False, indent=2)
        print()


if __name__ == "__main__":
    main()
