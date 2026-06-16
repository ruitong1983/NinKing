#!/bin/sh
# ═══════════════════════════════════════════════════════
# Install pre-commit hook for NinKing HTML viewer sync.
# ═══════════════════════════════════════════════════════
# Usage:  sh tools/install-hooks.sh
#         (run from repo root, or accept any dir)
# ═══════════════════════════════════════════════════════

# Try to find repo root
if [ -f ".git/HEAD" ]; then
  ROOT="."
elif [ -f "../.git/HEAD" ]; then
  ROOT=".."
else
  echo "❌ 请在仓库根目录运行: sh sh/tools/install-hooks.sh"
  exit 1
fi

SRC="$ROOT/tools/pre-commit"
DST="$ROOT/.git/hooks/pre-commit"

if [ ! -f "$SRC" ]; then
  echo "❌ 未找到 $SRC"
  exit 1
fi

cp "$SRC" "$DST"
chmod +x "$DST"
echo "✅ pre-commit 钩子已安装: $DST"
echo "   commit 前会自动提取: 忍者牌 / 喜系统 / 场景树 / 最近更新"
