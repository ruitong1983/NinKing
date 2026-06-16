#!/usr/bin/env python3
"""
Extract ninja card data from scripts/ninking/ninja_data.gd → JSON.

Usage:
    python tools/extract_ninja_data.py                             # stdout
    python tools/extract_ninja_data.py --inline                    # JS const snippet for HTML
    python tools/extract_ninja_data.py docs/ninking/ninja_card_viewer.html  # embed directly

Output is always UTF-8, no BOM.
"""

from __future__ import annotations

import ast
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
GD_PATH = REPO_ROOT / "scripts" / "ninking" / "ninja_data.gd"

# ─── Category → Chinese labels (kept here for reference; also in HTML) ───
CATEGORY_LABELS = {
    "universal": "通用加成",
    "group_target": "组别定向",
    "rule_change": "规则变更",
    "xi_enhance": "喜之强化",
    "scaling": "成长修炼",
    "economy": "经济",
    "tools": "忍法",
    "legendary": "传说",
    "redraw": "手替え激励",
    "cross_link": "联动",
    "face_card": "点数强化",
}

RARITY_ORDER = {"common": 0, "uncommon": 1, "rare": 2, "legendary": 3}
RARITY_LABELS = {"common": "普通", "uncommon": "稀有", "rare": "史诗", "legendary": "传说"}
RARITY_COLORS = {"common": "#9e9e9e", "uncommon": "#4fc3f7", "rare": "#ef5350", "legendary": "#ffd54f"}


def _find_string_ranges(text: str) -> list[tuple[int, int]]:
    """Return list of (start, end) for every quoted string in text."""
    ranges = []
    i = 0
    while i < len(text):
        if text[i] in ('"', "'"):
            quote = text[i]
            j = i + 1
            while j < len(text):
                if text[j] == '\\':
                    j += 2
                    continue
                if text[j] == quote:
                    ranges.append((i, j + 1))
                    i = j + 1
                    break
                j += 1
            else:
                i += 1  # unterminated string, skip
        else:
            i += 1
    return ranges


def _in_ranges(pos: int, ranges: list[tuple[int, int]]) -> bool:
    return any(lo <= pos < hi for lo, hi in ranges)


def _strip_line_comment(line: str, string_ranges: list[tuple[int, int]]) -> str:
    """Remove GDScript # comment from line, respecting string boundaries."""
    for i, ch in enumerate(line):
        if ch == '#' and not _in_ranges(i, string_ranges):
            return line[:i].rstrip()
    return line


def extract_ninja_array(gd_path: Path) -> list[dict]:
    """Parse ALL_NINJAS Array[Dictionary] from GDScript into Python list."""
    text = gd_path.read_text(encoding="utf-8")

    # ── Locate the array ──
    marker = "const ALL_NINJAS: Array[Dictionary] = ["
    start = text.find(marker)
    if start < 0:
        marker = "ALL_NINJAS: Array[Dictionary] = ["
        start = text.find(marker)
    if start < 0:
        raise ValueError("Cannot find ALL_NINJAS definition")

    # Position just after the opening [ (skip Array[Dictionary] type annotation)
    equals = text.index("=", start)
    bracket = text.index("[", equals)
    content_start = bracket + 1

    # ── Bracket-depth scan for the closing ] ──
    depth = 1
    i = content_start
    str_ranges = _find_string_ranges(text)
    while i < len(text) and depth > 0:
        if text[i] == "[" and not _in_ranges(i, str_ranges):
            depth += 1
        elif text[i] == "]" and not _in_ranges(i, str_ranges):
            depth -= 1
        i += 1

    if depth != 0:
        raise ValueError("Unbalanced brackets in ALL_NINJAS array")

    raw = text[content_start : i - 1]  # exclude the closing ]

    # ── Strip GDScript line comments ──
    lines = raw.split("\n")
    cleaned = []
    for line in lines:
        # Recompute string ranges per-line for simplicity
        line_str_ranges = _find_string_ranges(line)
        cleaned.append(_strip_line_comment(line, line_str_ranges))
    raw = "\n".join(cleaned)

    # ── Normalize bool literals ──
    raw = re.sub(r"\btrue\b", "True", raw)
    raw = re.sub(r"\bfalse\b", "False", raw)

    # ── Parse ──
    wrapped = "[\n" + raw + "\n]"
    try:
        return ast.literal_eval(wrapped)
    except (SyntaxError, ValueError) as e:
        lines = wrapped.split("\n")
        if hasattr(e, "lineno") and e.lineno is not None:
            ctx_lo = max(0, e.lineno - 4)
            ctx_hi = min(len(lines), e.lineno + 2)
            print(f"Parse error near line {e.lineno}: {e}", file=sys.stderr)
            for ln in range(ctx_lo, ctx_hi):
                prefix = ">>> " if ln == e.lineno - 1 else "    "
                print(f"{prefix}{ln+1}: {lines[ln]}", file=sys.stderr)
        raise


def build_js_const(ninjas: list[dict]) -> str:
    """Render the data as a JS const declaration for embedding in HTML."""
    # Drop calculated/precomputed fields from GDScript that aren't needed in the viewer
    clean = []
    for n in ninjas:
        entry = {
            "id": n.get("id"),
            "category": n.get("category"),
            "name": n.get("name"),
            "rarity": n.get("rarity"),
            "cost": n.get("cost"),
            "desc": n.get("desc"),
            "effect": n.get("effect"),
        }
        for opt in ("deferred", "mutex_group", "scaling", "head_weakness_scale"):
            if n.get(opt) is not None:
                entry[opt] = n[opt]
        clean.append(entry)

    js = json.dumps(clean, ensure_ascii=False, indent=2)
    return f"const NINJAS = {js};"


def embed_into_html(html_path: Path, ninjas: list[dict]) -> None:
    """Replace the NINJAS const inside an existing HTML file."""
    html = html_path.read_text(encoding="utf-8")
    js = build_js_const(ninjas)
    pattern = r"const NINJAS = \[.*?\];\s*// ── auto-extracted ──"
    if not re.search(pattern, html, re.DOTALL):
        print("Error: target HTML does not contain the NINJAS placeholder", file=sys.stderr)
        print("Expected pattern:", pattern[:60] + "...", file=sys.stderr)
        sys.exit(1)
    html = re.sub(pattern, js + "  // ── auto-extracted ──", html, count=1, flags=re.DOTALL)
    # Write with LF-only line endings
    html_path.write_bytes(html.encode("utf-8"))
    print(f"Embedded {len(ninjas)} cards into {html_path}")


def main():
    if not GD_PATH.exists():
        print(f"Error: {GD_PATH} not found", file=sys.stderr)
        sys.exit(1)

    ninjas = extract_ninja_array(GD_PATH)
    print(f"Extracted {len(ninjas)} cards", file=sys.stderr)

    args = sys.argv[1:]

    if args and args[0] == "--inline":
        print(build_js_const(ninjas))
    elif args and args[0].endswith(".html"):
        embed_into_html(Path(args[0]), ninjas)
    else:
        # Plain JSON to stdout
        clean = []
        for n in ninjas:
            entry = {k: n[k] for k in ("id", "category", "name", "rarity", "cost", "desc", "effect") if k in n}
            for opt in ("deferred", "mutex_group", "scaling", "head_weakness_scale"):
                if n.get(opt) is not None:
                    entry[opt] = n[opt]
            clean.append(entry)
        json.dump(clean, sys.stdout, ensure_ascii=False, indent=2)
        print()


if __name__ == "__main__":
    main()
