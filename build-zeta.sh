#!/bin/bash
# Zeta 核心总构建脚本
# 使用方法: 
#   bash build-zeta.sh          - 构建所有 Zeta 核心
#   bash build-zeta.sh mgba     - 构建单个 Zeta 核心

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

# 有 Zeta 构建脚本的核心
ZETA_CORES=(
  "mgba"
  "psp"
  "flycast"
)

build_core() {
  local core=$1
  
  if [ ! -d "$CORES_DIR/$core" ]; then
    error "$core 目录不存在"
    return 1
  fi
  
  cd "$CORES_DIR/$core"
  
  if [ ! -f "build-zeta.sh" ]; then
    info "$core 暂无 Zeta 构建脚本，跳过"
    return 0
  fi
  
  echo ""
  info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # 清理旧产物
  rm -rf output
  
  # 执行构建
  if bash build-zeta.sh; then
    success "$core Zeta 构建成功"
  else
    error "$core Zeta 构建失败"
    return 1
  fi
}

main() {
  local mode="${1:-all}"
  
  cd "$CORES_DIR"
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎮 Zeta Libretro iOS 核心构建"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  case $mode in
    all)
      info "📋 模式: 构建所有 Zeta 核心"
      
      for core in "${ZETA_CORES[@]}"; do
        build_core "$core" || true
      done
      ;;
      
    *)
      # 构建单个核心
      info "📋 模式: 构建单个核心 - $mode"
      build_core "$mode"
      ;;
  esac
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎉 Zeta 构建完成！"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # 统计所有 Zeta 产物
  info "🎁 Zeta 产物："
  find . -path "*/output/zeta_*-framework.zip" -type f 2>/dev/null | while read zip; do
    size=$(ls -lh "$zip" | awk '{print $5}')
    core=$(basename $(dirname $(dirname $zip)))
    variant=$(basename "$zip" | sed 's/-framework.zip//')
    echo "  • $core/$variant: $size"
  done || echo "  （暂无产物）"
}

main "$@"
