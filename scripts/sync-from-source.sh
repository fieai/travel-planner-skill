#!/usr/bin/env bash
# 把上游 x-mansion skill 的最新版本同步到本仓库的 skill/ 目录。
#
# 使用方式：
#   SOURCE=/path/to/x-mansion ./scripts/sync-from-source.sh
#
# 默认 SOURCE 假设 x-mansion 和本仓库在同一个父目录下。
# 同步是单向的：上游 → 本仓库。本仓库的 README / LICENSE / scripts 不会被覆盖。

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${SOURCE:-$(cd "$REPO_ROOT/../x-mansion" 2>/dev/null && pwd || true)}"

if [[ -z "$SOURCE" || ! -d "$SOURCE/skills/travel-planner" ]]; then
  echo "找不到上游 skill 源。请设置 SOURCE 环境变量指向 x-mansion 仓库根目录："
  echo "  SOURCE=/path/to/x-mansion $0"
  exit 1
fi

SRC="$SOURCE/skills/travel-planner"
DST="$REPO_ROOT/skill"

echo "同步: $SRC  →  $DST"

mkdir -p "$DST/references/site-patterns"

# 主文件
cp "$SRC/SKILL.md" "$DST/SKILL.md"

# references 下所有文件
cp "$SRC/references/SKILL.md" "$DST/references/SKILL.md" 2>/dev/null || true
cp "$SRC/references/data-sources.md" "$DST/references/data-sources.md"
cp "$SRC/references/orchestration.md" "$DST/references/orchestration.md"
cp "$SRC/references/template.html" "$DST/references/template.html"

# site-patterns 整个目录
if [[ -d "$SRC/references/site-patterns" ]]; then
  cp -R "$SRC/references/site-patterns/." "$DST/references/site-patterns/"
fi

echo "完成。diff 看看："
echo "  git -C \"$REPO_ROOT\" diff --stat -- skill/"
