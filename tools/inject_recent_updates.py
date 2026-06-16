#!/usr/bin/env python3
"""
Inject recent commit info into ninja_card_viewer.html.

Replaces the <!-- RECENT_UPDATES_PLACEHOLDER --> placeholder with real
commit history, categorized by tag.

Usage:
    python tools/inject_recent_updates.py docs/ninking/ninja_card_viewer.html
"""

import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

COMMIT_COUNT = 1

# Keywords → CSS tag class
TAG_RULES: list[tuple[list[str], str]] = [
    (["喜", "xi"], "tag-xi"),          # 喜 system changes
    (["忍者", "卡牌", "牌", "n_00"], "tag-ninja"),  # ninja card changes
    (["场景", "scene", "tscn", "节点"], "tag-scene"),  # scene tree changes
    (["文档", "docs", "doc ", "README"], "tag-docs"),  # documentation
    (["fix", "修复", "bug", "hotfix"], "tag-fix"),    # bug fixes
]


def get_recent_commits(count: int = COMMIT_COUNT) -> list[dict]:
    """Run git log and return list of {date, message, tags}."""
    result = subprocess.run(
        ["git", "log", f"--max-count={count}",
         "--format=%ai|%s", "--date=short"],
        capture_output=True, text=True, encoding="utf-8",
    )
    if result.returncode != 0:
        return []

    commits = []
    for line in result.stdout.strip().split("\n"):
        if not line or "|" not in line:
            continue
        date_str, message = line.split("|", 1)
        # date_str is like "2026-06-16 12:34:56 +0800"
        date_part = date_str.split()[0]  # "2026-06-16"

        # Categorize
        tags = set()
        for keywords, tag_class in TAG_RULES:
            for kw in keywords:
                if kw.lower() in message.lower():
                    tags.add(tag_class)
                    break
        if not tags:
            tags.add("tag-docs")  # default

        commits.append({
            "date": date_part,
            "message": message.strip(),
            "tags": sorted(tags),
        })

    return commits


def format_recent_updates(commits: list[dict]) -> str:
    """Generate the HTML for the recent updates section."""
    if not commits:
        return '<p class="empty">暂无更新记录（非 git 仓库）</p>'

    lines = ["<ul>"]
    for c in commits:
        tag_spans = "".join(
            f'<span class="tag {t}">{t.replace("tag-", "")}</span>'
            for t in c["tags"]
        )
        lines.append(
            f'  <li><span class="date">{c["date"]}</span>'
            f"{tag_spans}{c['message']}</li>"
        )
    lines.append("</ul>")
    lines.append(
        f'<p style="font-size:11px;color:var(--text-dim);'
        f'margin-top:6px">'
        f'最新提交 · 部署于 {datetime.now().strftime("%Y-%m-%d %H:%M")}'
        f'</p>'
    )
    return "\n".join(lines)


def inject_into_html(html_path: Path) -> None:
    html = html_path.read_text(encoding="utf-8")

    print("Fetching recent commits...", file=sys.stderr)
    commits = get_recent_commits()
    print(f"  Found {len(commits)} recent commits", file=sys.stderr)

    updates_html = format_recent_updates(commits)

    # Replace placeholder + everything until </div>
    # Pattern: from <!-- RECENT_UPDATES_PLACEHOLDER --> to the </div> closing
    pattern = (
        r"<!--\s*RECENT_UPDATES_PLACEHOLDER\s*-->"
        r".*?"
        r"</div>"
    )

    replacement = (
        f"<!-- RECENT_UPDATES_PLACEHOLDER -->\n"
        f"{updates_html}\n"
        f"</div>"
    )

    if not re.search(pattern, html, re.DOTALL):
        print("Warning: RECENT_UPDATES_PLACEHOLDER not found in HTML", file=sys.stderr)
        return

    html = re.sub(pattern, replacement, html, count=1, flags=re.DOTALL)

    html_path.write_bytes(html.encode("utf-8"))
    print(f"✅ Injected into {html_path}", file=sys.stderr)


def main():
    args = sys.argv[1:]
    if args and args[0].endswith(".html"):
        inject_into_html(Path(args[0]))
    else:
        # stdout preview
        commits = get_recent_commits()
        for c in commits:
            tags = ", ".join(c["tags"])
            print(f"  [{c['date']}] ({tags}) {c['message']}")


if __name__ == "__main__":
    main()
