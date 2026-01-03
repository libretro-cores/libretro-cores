#!/bin/bash
# Yohu 核心总构建脚本
# 使用方法: 
#   bash build-yohu.sh          - 构建所有 Yohu 核心
#   bash build-yohu.sh mgba     - 构建单个 Yohu 核心

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

# 有 Yohu 支持的核心
YOHU_CORES=(
  "arcade"
  "flycast"
  "psp"
)

build_core() {
  local core=$1
  
  if [ ! -d "$CORES_DIR/$core" ]; then
    error "$core 目录不存在"
    return 1
  fi
  
  cd "$CORES_DIR/$core"
  
  if [ ! -f "build.sh" ]; then
    info "$core 暂无构建脚本，跳过"
    return 0
  fi
  
  # 检查是否支持 yohu 项目
  if ! grep -q '"yohu"' projects.json 2>/dev/null; then
    info "$core 暂未支持 Yohu 项目，跳过"
    return 0
  fi
  
  echo ""
  info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  info "🎮 构建 $core - Yohu"
  
  # 清理旧产物
  rm -rf output-yohu
  
  # 执行构建
  if bash build.sh --project yohu 2>&1 | tail -30; then
    success "$core Yohu 构建成功"
    
    # 检查产物
    if [ -d "output-yohu" ]; then
      local zip_file=$(find output-yohu -name "*.zip" -type f 2>/dev/null | head -1)
      if [ -n "$zip_file" ]; then
        local size=$(ls -lh "$zip_file" | awk '{print $5}')
        info "  产物: $(basename $zip_file) ($size)"
      fi
    fi
  else
    error "$core Yohu 构建失败"
    return 1
  fi
}

main() {
  local mode="${1:-all}"
  
  cd "$CORES_DIR"
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎮 Yohu Libretro iOS 核心构建"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  case $mode in
    all)
      info "📋 模式: 构建所有 Yohu 核心"
      
      for core in "${YOHU_CORES[@]}"; do
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
  echo "🎉 Yohu 构建完成！"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # 统计所有 Yohu 产物
  info "🎁 Yohu 产物汇总："
  find . -path "*/output-yohu/*.zip" -type f 2>/dev/null | sort | while read zip; do
    size=$(ls -lh "$zip" | awk '{print $5}')
    core=$(basename $(dirname $(dirname $zip)))
    variant=$(basename "$zip" | sed 's/-framework.zip//')
    printf "  • %-15s %-20s %s\n" "$core" "$variant" "$size"
  done || echo "  （暂无产物）"
  
  local total=$(find . -path "*/output-yohu/*.zip" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo ""
  info "总计: $total 个 Yohu 产物"
}

main "$@"

