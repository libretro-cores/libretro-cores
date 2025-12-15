#!/bin/bash
# 构建所有核心（包括 PPEMU 和 Zeta 变种）
# 使用方法: bash build_all.sh

set -e

CORES_DIR="$(cd "$(dirname "$0")" && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${YELLOW}ℹ️  $1${NC}"; }
header() { echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

# 所有核心列表
ALL_CORES=(
  "mgba"
  "genesis"
  "nes"
  "snes"
  "pce"
  "saturn"
  "ps1"
  "n64"
  "nds"
  "psp"
  "flycast"
)

# 有 Zeta 变种的核心
ZETA_CORES=(
  "mgba"
  "genesis"
  "nes"
  "snes"
  "pce"
  "saturn"
  "ps1"
  "n64"
  "nds"
  "psp"
  "flycast"
)

SUCCESS_COUNT=0
FAIL_COUNT=0

build_core() {
  local core=$1
  local project=$2
  
  if [ ! -d "$CORES_DIR/$core" ]; then
    error "$core 目录不存在"
    return 1
  fi
  
  cd "$CORES_DIR/$core"
  
  if [ ! -f "build.sh" ]; then
    info "$core 暂无构建脚本，跳过"
    return 0
  fi
  
  echo ""
  header
  info "构建 $core - $project"
  header
  
  # 执行构建
  if bash build.sh --project "$project" 2>&1 | tail -30; then
    success "$core ($project) 构建成功"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    return 0
  else
    error "$core ($project) 构建失败"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return 1
  fi
}

main() {
  cd "$CORES_DIR"
  
  echo ""
  header
  echo "🔨 批量构建所有 Libretro iOS 核心"
  header
  echo ""
  
  # 第一步：构建所有 PPEMU 核心
  info "📋 阶段 1: 构建所有 PPEMU 核心"
  echo ""
  
  for core in "${ALL_CORES[@]}"; do
    build_core "$core" "ppemu" || true
  done
  
  echo ""
  header
  info "📋 阶段 2: 构建所有 Zeta 核心"
  header
  echo ""
  
  for core in "${ZETA_CORES[@]}"; do
    build_core "$core" "zeta" || true
  done
  
  echo ""
  header
  echo "🎉 构建完成！"
  header
  echo ""
  
  # 统计所有产物
  info "📦 产物统计："
  find . -path "*/output/*-framework.zip" -type f 2>/dev/null | sort | while read zip; do
    size=$(ls -lh "$zip" | awk '{print $5}')
    core=$(basename $(dirname $(dirname $zip)))
    variant=$(basename "$zip" | sed 's/-framework.zip//')
    printf "  • %-15s %-20s %s\n" "$core" "$variant" "$size"
  done
  
  total=$(find . -path "*/output/*-framework.zip" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo ""
  info "总计: $total 个产物"
  success "成功: $SUCCESS_COUNT"
  error "失败: $FAIL_COUNT"
}

main "$@"

