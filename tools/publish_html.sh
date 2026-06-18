#!/bin/bash
# ═══════════════════════════════════════════════════════
# publish_html.sh — HTML 可视化全自动发布脚本
#
# 用法:
#   bash tools/publish_html.sh           # 更新HTML + 本地提交
#   bash tools/publish_html.sh --pr      # 更新HTML + 提交 + 推送 + 创建PR
#   bash tools/publish_html.sh --help    # 显示帮助
#
# 流程:
#   1. 运行 4 个提取脚本注入数据到 ninja_card_viewer.html
#   2. 复制忍者卡图片到 docs/assets/
#   3. 基本校验（文件大小、卡牌数量）
#   4. git commit（如有变更）
#   5. 如果传了 --pr: git push + gh pr create
# ═══════════════════════════════════════════════════════
set -e

PYTHON="python"
command -v "$PYTHON" >/dev/null 2>&1 || PYTHON="python3"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

HTML="docs/ninking/ninja_card_viewer.html"
EXTRACTORS=(
  "tools/extract_ninja_data.py"
  "tools/extract_xi_data.py"
  "tools/tscn_parser.py"
)
INJECTOR="tools/inject_recent_updates.py"

# ── Asset paths (copy card images for GitHub Pages) ──
NINJA_CARD_SRC="assets/images/cards/ninjas"
NINJA_CARD_DST="docs/assets/images/cards/ninjas"

# ── Help ──────────────────────────────────────────────
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "用法: bash tools/publish_html.sh [--pr]"
  echo ""
  echo "  (无参数)   更新 HTML → git commit（本地提交）"
  echo "  --pr       更新 HTML → git commit → git push → gh pr create"
  echo "  --help     显示此帮助"
  exit 0
fi

DO_PR=false
if [ "$1" = "--pr" ]; then
  DO_PR=true
fi

# ── Helper: colored output ────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }

# ── 1. Run extraction scripts ────────────────────────
echo "━━━ 1/6 提取忍者牌数据 ━━━"
"$PYTHON" "${EXTRACTORS[0]}" "$HTML"
ok "ninja_data 注入完成"

echo "━━━ 2/6 提取喜系统数据 ━━━"
"$PYTHON" "${EXTRACTORS[1]}" "$HTML"
ok "xi_data 注入完成"

echo "━━━ 3/6 提取场景树数据 ━━━"
"$PYTHON" "${EXTRACTORS[2]}" "$HTML"
ok "场景树注入完成"

echo "━━━ 4/6 注入最近提交 ━━━"
"$PYTHON" "$INJECTOR" "$HTML"
ok "最近提交注入完成"

# ── 5. Copy card images for GitHub Pages ─────────────
echo "━━━ 5/6 复制忍者卡图片 ━━━"
mkdir -p "$NINJA_CARD_DST"
cp "$NINJA_CARD_SRC/"*.png "$NINJA_CARD_DST/"
COUNT=$(ls "$NINJA_CARD_DST/"*.png 2>/dev/null | wc -l)
ok "已复制 $COUNT 张忍者卡图片"

# ── 6. Validate ──────────────────────────────────────
echo "━━━ 6/6 校验 HTML ━━━"
if [ ! -f "$HTML" ]; then
  fail "$HTML 不存在"
  exit 1
fi

# 检查文件大小（至少 10KB）
SIZE=$(stat -c%s "$HTML" 2>/dev/null || stat -f%z "$HTML" 2>/dev/null || echo 0)
if [ "$SIZE" -lt 10240 ]; then
  warn "HTML 文件偏小（${SIZE} 字节），可能数据不完整"
fi

# 检查是否有卡牌数据 (const NINJAS = [)
if grep -q 'const NINJAS = \[' "$HTML" 2>/dev/null; then
  CARD_COUNT=$(grep -o '"id": "[^"]*"' "$HTML" | wc -l)
  ok "忍者牌数据: $CARD_COUNT 张"
else
  fail "未找到 NINJAS 数据"
  exit 1
fi

# 检查是否有场景树数据 (const SCENES =)
if grep -q 'const SCENES = ' "$HTML" 2>/dev/null; then
  ok "场景树数据存在"
else
  warn "未找到 SCENES 数据"
fi

ok "HTML 校验通过"

# ── 6. Commit ────────────────────────────────────────
echo "━━━ 提交 ━━━"
git add "$HTML" "$NINJA_CARD_DST"

if git diff --cached --quiet; then
  ok "HTML 无变更，跳过提交"
else
  git commit -m "docs: 同步最新数据到 HTML (auto)"
  COMMIT_HASH=$(git rev-parse --short HEAD)
  ok "提交成功: $COMMIT_HASH"
fi

# ── 7. Push + PR（可选）─────────────────────────────
if [ "$DO_PR" = true ]; then
  echo "━━━ 推送 ━━━"
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  git push origin "$CURRENT_BRANCH"
  ok "已推送到 origin/$CURRENT_BRANCH"

  echo "━━━ 创建 PR ━━━"
  if [ "$CURRENT_BRANCH" = "dev" ]; then
    PR_URL=$(gh pr create --base master --head dev \
      --title "docs: 同步 HTML 可视化数据" \
      --body "自动更新 HTML 可视化数据" \
      --fill 2>&1)
    ok "PR 已创建: $PR_URL"
  else
    warn "当前不在 dev 分支（$CURRENT_BRANCH），跳过 PR 创建"
  fi
fi

echo ""
echo -e "${GREEN}✅ 全部完成${NC}"
