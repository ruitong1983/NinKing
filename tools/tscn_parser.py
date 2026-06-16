#!/usr/bin/env python3
"""
Parse .tscn files and embed scene tree data into scene-tree-visualizer.html.

Usage:
    python tools/tscn_parser.py                                          # stdout JSON
    python tools/tscn_parser.py docs/ninking/scene-tree-visualizer.html  # embed
"""

from __future__ import annotations

import ast
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# ─── Scene key → tscn file mapping ───
SCENE_MAP: dict[str, str] = {
    "main":     "scenes/ninking/ninking_main.tscn",
    "launcher": "scenes/ninking/ninking_launcher.tscn",
    "shop":     "scenes/ninking/shop_panel.tscn",
    "ninja":    "scenes/ninking/ninja_card.tscn",
    "debug":    "scenes/ninking/debug_ninking_main.tscn",
    "card":     "scenes/ninking/ninking_card.tscn",
    "popup":    "scenes/ninking/card_detail_popup.tscn",
    "deck":     "scenes/ninking/deck_select_panel.tscn",
    "continue": "scenes/ninking/continue_panel.tscn",
}

# ─── Root notes (human descriptions for scene roots) ───
# These are combined with auto-extracted info.
ROOT_NOTES: dict[str, str] = {
    "main":     "1920×1080",
    "launcher": "1920×1080",
    "shop":     "800×716",
    "ninja":    "125×175",
    "debug":    "1920×1080",
    "card":     "card_size=125×175",
    "popup":    "全屏覆盖",
    "deck":     "全屏, visible=false",
    "continue": "1920×1080, visible=false",
}

# HTML sections for each scene (hand-authored once)
SCENE_HTML: dict[str, dict] = {
    "main":     {"tscn": "ninking_main.tscn", "root_name": "NinKingMain"},
    "launcher": {"tscn": "ninking_launcher.tscn", "root_name": "NinKingLauncher"},
    "shop":     {"tscn": "shop_panel.tscn", "root_name": "ShopPanel"},
    "ninja":    {"tscn": "ninja_card.tscn", "root_name": "NinjaCard"},
    "debug":    {"tscn": "debug_ninking_main.tscn", "root_name": "DebugNinKingMain"},
    "card":     {"tscn": "ninking_card.tscn", "root_name": "NinKingCard"},
    "popup":    {"tscn": "card_detail_popup.tscn", "root_name": "CardDetailPopup"},
    "deck":     {"tscn": "deck_select_panel.tscn", "root_name": "DeckSelectPanel"},
    "continue": {"tscn": "continue_panel.tscn", "root_name": "ContinuePanel"},
}

# ─── Godot node type → CSS class ───
NODE_CSS = {
    "Control": "control", "Panel": "panel", "Label": "label",
    "Button": "button", "TextureRect": "texturerect", "ColorRect": "colorrect",
    "HBoxContainer": "hbox", "VBoxContainer": "vbox", "GridContainer": "grid",
    "ScrollContainer": "scroll", "RichTextLabel": "richtext",
    "ProgressBar": "progress", "CardManager": "cardmanager",
}


# ═══════════════════════════════════════════════════════════
#  TSCN parser
# ═══════════════════════════════════════════════════════════

def parse_tscn(filepath: Path) -> list[dict]:
    """Parse .tscn → list of node dicts with name, type, parent, unique, script."""
    text = filepath.read_text(encoding="utf-8")

    # ext_resource id → path mapping
    ext_res: dict[str, str] = {}
    for m in re.finditer(r'\[ext_resource\s+(?:type="[^"]*"\s+)?uid="[^"]*"\s+path="([^"]+)"\s+id="([^"]+)"', text):
        ext_res[m.group(2)] = m.group(1)
    for m in re.finditer(r'\[ext_resource\s+type="[^"]*"\s+path="([^"]+)"\s+id="([^"]+)"', text):
        ext_res[m.group(2)] = m.group(1)

    def _ext_resource_name(ref: str) -> str:
        """Resolve ExtResource('id') → filename."""
        path_str = ext_res.get(ref, ref)
        return Path(path_str).name

    nodes: list[dict] = []
    # Match [node name="..." type="..." ...] followed by properties
    # Need to handle parent (optional), unique_id, instance
    pattern = re.compile(
        r'\[node\s+name="([^"]+)"\s+type="([^"]+)"'
        r'(?:\s+parent="([^"]*)")?'
        r'(?:\s+unique_id=(\d+))?'
        r'(?:\s+instance=ExtResource\("([^"]+)"\))?'
        r'\](.*?)(?=\n\[|\Z)',
        re.DOTALL
    )

    for m in pattern.finditer(text):
        name = m.group(1)
        node_type = m.group(2)
        has_parent = m.group(3)  # None if parent attribute not present → root node
        parent = has_parent if has_parent is not None else "."
        unique_id = m.group(4) or ""
        instance_ref = m.group(5) or ""
        body = m.group(6)

        has_unique = "unique_name_in_owner = true" in body
        script = ""
        sm = re.search(r'script\s*=\s*ExtResource\("([^"]+)"\)', body)
        if sm:
            script = _ext_resource_name(sm.group(1))

        instance = _ext_resource_name(instance_ref) if instance_ref else ""

        nodes.append({
            "name": name,
            "type": node_type,
            "parent": parent,
            "is_root": has_parent is None,  # No parent attr → root of the scene
            "unique_id": unique_id,
            "unique": has_unique,
            "script": script,
            "instance": instance,
        })

    return nodes


def build_tree(nodes: list[dict]) -> dict | None:
    """Build nested tree from flat node list (parent field).

    In Godot tscn:
      - Node WITHOUT parent attribute = root node
      - Node with parent="." = direct child of root
      - Node with parent="X/Y/Z" = child of path X/Y/Z
    """
    children_map: dict[str, list[dict]] = {}
    root: dict | None = None

    for node in nodes:
        if node["is_root"]:
            root = node
        else:
            p = node["parent"]
            if p == ".":
                # Direct child of root — use root's name as parent path
                p = root["name"] if root else p
            children_map.setdefault(p, []).append(node)

    if not root:
        return None

    def _walk(n: dict) -> dict:
        result: dict = {"type": n["type"], "name": n["name"]}
        if n.get("unique"):
            result["unique"] = True
        if n.get("script"):
            result["script"] = n["script"]
        if n.get("instance"):
            result["instance"] = n["instance"]

        # Determine children_map lookup key from tscn's parent field.
        #   parent="."  → key = node name (root-level child)
        #   parent="P"  → key = P + "/" + name (deeper, P is relative path from root)
        #   is_root     → key = root name
        p = n.get("parent", "")
        if n.get("is_root") or p in ("", "."):
            key = n["name"]
        else:
            key = p + "/" + n["name"]

        kids = children_map.get(key, [])
        if kids:
            # Sort by unique_id for stable ordering (roughly insertion order)
            kids.sort(key=lambda x: int(x.get("unique_id") or "0"))
            result["children"] = []
            for kid in kids:
                sub = _walk(kid)
                if sub:
                    result["children"].append(sub)

        return result

    return _walk(root)


# ═══════════════════════════════════════════════════════════
#  JS object parser (extract annotations from existing HTML)
# ═══════════════════════════════════════════════════════════

def _js_to_python(js_text: str):
    """Convert a JS object literal to a Python dict via ast.literal_eval."""
    text = js_text.strip()

    # 1. Remove JS line comments
    text = re.sub(r'(?<![:\w])//[^\n]*', '', text)

    # 2. Tokenize and convert
    out: list[str] = []
    i = 0
    while i < len(text):
        c = text[i]

        # ── single-quoted string → double-quoted ──
        if c == "'":
            j = i + 1
            buf: list[str] = []
            while j < len(text):
                if text[j] == "\\" and j + 1 < len(text):
                    buf.append(text[j] + text[j + 1])
                    j += 2
                    continue
                if text[j] == "'":
                    raw = "".join(buf)
                    # Escape any existing double quotes
                    raw = raw.replace('"', '\\"')
                    out.append('"' + raw + '"')
                    i = j + 1
                    break
                buf.append(text[j])
                j += 1
            else:
                out.append(c)
                i += 1
            continue

        # ── double-quoted string — pass through ──
        if c == '"':
            j = i + 1
            while j < len(text):
                if text[j] == "\\" and j + 1 < len(text):
                    j += 2
                    continue
                if text[j] == '"':
                    out.append(text[i:j + 1])
                    i = j + 1
                    break
                j += 1
            else:
                out.append(c)
                i += 1
            continue

        # ── identifier (key or bareword) ──
        if c.isalpha() or c == "_":
            j = i
            while j < len(text) and (text[j].isalnum() or text[j] == "_"):
                j += 1
            word = text[i:j]
            # If followed by `:`, it's a key → quote it
            if j < len(text) and text[j] == ":":
                out.append('"' + word + '":')
                i = j + 1
            else:
                # true/false/null → Python
                out.append({"true": "True", "false": "False", "null": "None"}.get(word, word))
                i = j
            continue

        # ── trailing comma → skip ──
        if c == ",":
            j = i + 1
            while j < len(text) and text[j] in " \t\n\r":
                j += 1
            if j < len(text) and text[j] in "]}":
                i = j
                continue

        out.append(c)
        i += 1

    py_text = "".join(out)
    try:
        return ast.literal_eval(py_text)
    except (SyntaxError, ValueError) as e:
        # On failure, show context
        lines = py_text.split("\n")
        if hasattr(e, "lineno") and e.lineno:
            ctx_lo = max(0, e.lineno - 3)
            ctx_hi = min(len(lines), e.lineno + 2)
            print(f"JS→Python parse error near line {e.lineno}: {e}", file=sys.stderr)
            for ln in range(ctx_lo, ctx_hi):
                prefix = ">>>" if ln == e.lineno - 1 else "   "
                print(f"  {prefix} {ln + 1}: {lines[ln][:200]}", file=sys.stderr)
        raise


def _walk_for_notes(tree: dict, scene_key: str, prefix: str, notes: dict) -> None:
    """Recursively walk parsed SCENES dict and extract (scene_key, path) → note."""
    name = tree.get("name", "")
    path = f"{prefix}/{name}" if prefix else name
    note = tree.get("note", "")
    if note:
        notes[(scene_key, path)] = note
    for child in tree.get("children", []):
        _walk_for_notes(child, scene_key, path, notes)


def extract_annotations(html_text: str) -> dict:
    """Extract (scene_key, path) → note from existing SCENES data in HTML."""
    m = re.search(r"const SCENES\s*=\s*(\{.*?\});", html_text, re.DOTALL)
    if not m:
        return {}

    try:
        scenes = _js_to_python(m.group(1))
    except Exception:
        print("  ⚠ Failed to parse existing SCENES data, starting with empty annotations", file=sys.stderr)
        return {}

    notes: dict = {}
    for key, scene_data in scenes.items():
        if isinstance(scene_data, dict):
            children = scene_data.get("children", [])
            for root in children:
                if isinstance(root, dict):
                    _walk_for_notes(root, key, "", notes)
    return notes


# ═══════════════════════════════════════════════════════════
#  Apply annotations to new tree
# ═══════════════════════════════════════════════════════════

def _annotate_tree(tree: dict, scene_key: str, prefix: str, notes: dict) -> int:
    """Apply notes to tree nodes, return count of applied notes."""
    name = tree.get("name", "")
    path = f"{prefix}/{name}" if prefix else name
    applied = 0

    note_key = (scene_key, path)
    if note_key in notes:
        tree["note"] = notes[note_key]
        applied += 1

    for child in tree.get("children", []):
        applied += _annotate_tree(child, scene_key, path, notes)

    return applied


# ═══════════════════════════════════════════════════════════
#  JS generation
# ═══════════════════════════════════════════════════════════

def _tree_to_js(tree: dict, indent: int = 2) -> str:
    """Render a single tree node as JS object literal (commas between props)."""
    pad = "  " * indent
    inner_pad = "  " * (indent + 1)
    lines: list[str] = []

    # Collect all property lines
    props: list[str] = []
    props.append(f"type: '{tree['type']}', name: '{tree['name']}'")
    if tree.get("unique"):
        props.append("unique: true")
    if tree.get("script"):
        props.append(f"script: '{tree['script']}'")
    if tree.get("instance"):
        props.append(f"instance: '{tree['instance']}'")
    if tree.get("note"):
        note = tree["note"].replace("'", "\\'")
        props.append(f"note: '{note}'")

    children = tree.get("children", [])

    lines.append(f"{{")
    for p in props:
        lines.append(f"{inner_pad}{p},")

    if children:
        lines.append(f"{inner_pad}children: [")
        for child in children:
            lines.append(_tree_to_js(child, indent + 2))
        lines.append(f"{inner_pad}],")

    # If trailing comma on last prop line and no children, remove it
    if not children and lines[-1].endswith(","):
        lines[-1] = lines[-1][:-1]

    lines.append(f"{pad}}},")
    return "\n".join(lines)


def generate_scenes_js(all_trees: dict[str, dict]) -> str:
    """Generate the full SCENES JS object as a string."""
    lines: list[str] = []
    lines.append("const SCENES = {")
    keys = list(all_trees.keys())
    for i, key in enumerate(keys):
        root = all_trees[key]
        tree_js = _tree_to_js(root, 2)
        lines.append(f"  {key}: {{")
        lines.append(f"    children: [")
        lines.append(tree_js)
        lines.append(f"    ]")
        lines.append(f"  }}{'' if i == len(keys) - 1 else ','}")
    lines.append("};")
    return "\n".join(lines)


# ═══════════════════════════════════════════════════════════
#  Embed into HTML
# ═══════════════════════════════════════════════════════════

def build_all_trees(annotations: dict) -> dict[str, dict]:
    """Parse all tscn files, build trees, apply annotations."""
    trees: dict[str, dict] = {}
    applied = 0
    orphaned: list[tuple] = []

    for key, rel_path in SCENE_MAP.items():
        fp = REPO_ROOT / rel_path
        if not fp.exists():
            print(f"  ⚠  Scene file not found: {rel_path}", file=sys.stderr)
            continue

        nodes = parse_tscn(fp)
        raw_tree = build_tree(nodes)
        if not raw_tree:
            print(f"  ⚠  No root node found in {rel_path}", file=sys.stderr)
            continue

        # Set root note
        root_note = ROOT_NOTES.get(key, "")
        script = raw_tree.get("script", "")
        if script:
            if root_note:
                raw_tree["note"] = f"{root_note} [{script}]"
            else:
                raw_tree["note"] = f"[{script}]"

        # Apply inherited annotations
        cnt = _annotate_tree(raw_tree, key, "", annotations)
        applied += cnt
        trees[key] = raw_tree

    # Report orphaned annotations (notes for paths that no longer exist)
    all_paths = set()
    for key, tree in trees.items():
        def _collect(t, prefix=""):
            name = t["name"]
            path = f"{prefix}/{name}" if prefix else name
            all_paths.add((key, path))
            for c in t.get("children", []):
                _collect(c, path)
        _collect(tree)

    for (skey, spath), snote in annotations.items():
        if (skey, spath) not in all_paths:
            orphaned.append((skey, spath, snote))

    if orphaned:
        print(f"\n  ⚠  Orphaned annotations (nodes no longer exist, notes preserved in output):", file=sys.stderr)
        for sk, sp, sn in sorted(orphaned):
            print(f"    [{sk}] {sp}: {sn}", file=sys.stderr)

    print(f"  Applied {applied} annotations{', ' + str(len(orphaned)) + ' orphaned' if orphaned else ''}", file=sys.stderr)
    return trees


def embed_into_html(html_path: Path) -> None:
    """Read HTML, extract annotations, build trees, replace SCENES data."""
    html = html_path.read_text(encoding="utf-8")

    print("Extracting annotations from existing HTML...", file=sys.stderr)
    annotations = extract_annotations(html)
    print(f"  Found {len(annotations)} existing annotations", file=sys.stderr)

    print("Building trees from .tscn files...", file=sys.stderr)
    trees = build_all_trees(annotations)

    # Generate new SCENES JS
    js = generate_scenes_js(trees)

    # Replace SCENES data in the script section
    pattern = r"const SCENES\s*=\s*\{.*?\};"
    replacement = js

    if not re.search(pattern, html, re.DOTALL):
        print("Error: cannot find SCENES data placeholder in HTML", file=sys.stderr)
        sys.exit(1)

    html = re.sub(pattern, replacement, html, count=1, flags=re.DOTALL)

    # Update timestamp in subtitle
    from datetime import date
    today = date.today().isoformat()
    # Format A: ninja_card_viewer — `<span id="data-date">2026-06-16</span>`
    html = re.sub(
        r'(id="data-date">)\d{4}-\d{2}-\d{2}(</span>)',
        rf'\g<1>{today}\g<2>',
        html
    )
    # Format B (legacy): scene-tree-visualizer — `基于 2026-06-16 tscn 扫描`
    html = re.sub(
        r'基于 \d{4}-\d{2}-\d{2} tscn 扫描',
        f'基于 {today} tscn 扫描',
        html
    )

    # Remove stale-note section (legacy standalone file cleanup)
    html = re.sub(
        r'<div class="stale-note">.*?</div>\s*',
        '',
        html
    )

    html_path.write_bytes(html.encode("utf-8"))
    print(f"\n✅ Updated {html_path}", file=sys.stderr)
    print(f"   {len(trees)} scenes, all annotations preserved", file=sys.stderr)


def main():
    if not sys.argv[1:]:
        # stdout: full tree JSON
        annotations = {}
        trees = build_all_trees(annotations)
        # Convert to serializable dict
        import copy
        out = {}
        for k, t in trees.items():
            def _clean(node):
                d = {k: v for k, v in node.items() if v is not None and v != ""}
                if "children" in d:
                    d["children"] = [_clean(c) for c in d["children"]]
                return d
            out[k] = _clean(t)
        json.dump(out, sys.stdout, ensure_ascii=False, indent=2)
        print()
        return

    target = sys.argv[1]
    if target.endswith(".html"):
        embed_into_html(Path(target))
    else:
        print(f"Usage: python {__file__} [<path/to/html>]", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
