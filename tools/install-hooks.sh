#!/bin/sh
# ═══════════════════════════════════════════════════════
# Install NinKing pre-commit hooks
# Usage: sh tools/install-hooks.sh
# ═══════════════════════════════════════════════════════

HOOK_SRC="tools/pre-commit"
HOOK_DST=".git/hooks/pre-commit"

if [ ! -f "$HOOK_SRC" ]; then
  echo "❌ 找不到 $HOOK_SRC — 请从项目根目录运行"
  exit 1
fi

cp "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_DST"
echo "✅ Pre-commit hook 已安装: $HOOK_DST"
echo "   → ninja_data.gd 变更时自动同步 ninja_card_viewer.html"
