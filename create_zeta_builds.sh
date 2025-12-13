#!/bin/bash
# Zeta 构建配置自动化脚本
# 为所有核心创建 Zeta 版本的构建脚本

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

CORES_DIR="$(cd "$(dirname "$0")" && pwd)"

# 核心配置 - 格式: "目录:输出名:Bundle ID名"
declare -a SINGLE_CORES=(
    "mgba:mgba:mgba"
    "nes:nes:nes"
    "snes:snes:snes"
    "genesis:genesis:genesis"
    "saturn:saturn:saturn"
    "arcade:arcade:arcade"
)

declare -a MULTI_CORES=(
    "psp:psp:psp"
    "flycast:dreamcast:dreamcast"
    "n64:n64:n64"
    "nds:nds:nds"
    "ps1:ps1:ps1"
)

# 为单变体核心创建 Zeta 构建脚本
create_single_variant_zeta() {
    local core_dir=$1
    local output_name=$2
    local bundle_name=$3
    
    log_info "处理单变体核心: ${core_dir}"
    
    if [ ! -d "$core_dir" ]; then
        log_error "目录不存在: $core_dir"
        return 1
    fi
    
    local build_script="$core_dir/build.sh"
    
    if [ ! -f "$build_script" ]; then
        log_warning "$core_dir 没有构建脚本，跳过"
        return 0
    fi
    
    # 创建 Zeta 版本的构建脚本
    local zeta_script="$core_dir/build-zeta.sh"
    
    log_info "创建 ${zeta_script}..."
    
    # 复制原始脚本并修改
    cp "$build_script" "$zeta_script"
    
    # 使用 sed 替换关键配置
    # 1. 替换 framework 名称
    sed -i '' "s|/${output_name}.framework|/zeta_${output_name}.framework|g" "$zeta_script"
    sed -i '' "s|\"${output_name}.framework|\"zeta_${output_name}.framework|g" "$zeta_script"
    
    # 2. 替换 zip 文件名
    sed -i '' "s|${output_name}-framework.zip|zeta_${output_name}-framework.zip|g" "$zeta_script"
    
    # 3. 替换 Bundle ID
    sed -i '' "s|com.ppemu.core.${bundle_name}|com.zeta.core.${bundle_name}|g" "$zeta_script"
    
    # 4. 替换 Info.plist 中的 executable 和 name
    sed -i '' "s|<string>${output_name}</string>|<string>zeta_${output_name}</string>|g" "$zeta_script"
    
    # 5. 替换 install_name_tool 命令
    sed -i '' "s|@rpath/${output_name}.framework/${output_name}|@rpath/zeta_${output_name}.framework/zeta_${output_name}|g" "$zeta_script"
    
    # 6. 替换二进制文件名
    sed -i '' "s|\"\\$framework_path/${output_name}\"|\"\\$framework_path/zeta_${output_name}\"|g" "$zeta_script"
    
    # 7. 替换标题
    sed -i '' "s|构建 ${output_name}|构建 Zeta ${output_name}|g" "$zeta_script"
    sed -i '' "s|构建 mGBA|构建 Zeta mGBA|g" "$zeta_script"
    
    # 8. 替换构建定义
    sed -i '' "s|-DPPEMU_BUILD=1|-DZETA_BUILD=1|g" "$zeta_script"
    
    chmod +x "$zeta_script"
    
    log_success "✅ ${core_dir}/build-zeta.sh 创建完成"
    
    return 0
}

# 为多变体核心创建 Zeta 构建脚本
create_multi_variant_zeta() {
    local core_dir=$1
    local output_name=$2
    local bundle_name=$3
    
    log_info "处理多变体核心: ${core_dir}"
    
    if [ ! -d "$core_dir" ]; then
        log_error "目录不存在: $core_dir"
        return 1
    fi
    
    local build_script="$core_dir/build.sh"
    
    if [ ! -f "$build_script" ]; then
        log_warning "$core_dir 没有构建脚本，跳过"
        return 0
    fi
    
    local zeta_script="$core_dir/build-zeta.sh"
    
    log_info "创建 ${zeta_script}..."
    
    cp "$build_script" "$zeta_script"
    
    # 多变体核心需要更复杂的替换
    # 1. 替换 Bundle ID 基础部分
    sed -i '' "s|com.ppemu.core|com.zeta.core|g" "$zeta_script"
    
    # 2. 替换 package 函数中的变体处理
    sed -i '' "s|local bundle_id=\"com.ppemu.core.\${variant_name}\"|local bundle_id=\"com.zeta.core.\${variant_name}\"|g" "$zeta_script"
    
    # 3. 替换标准版和 JIT 版的调用
    sed -i '' "s|package \"${output_name}\" |package \"zeta_${output_name}\" |g" "$zeta_script"
    sed -i '' "s|package \"${output_name}-jit\" |package \"zeta_${output_name}-jit\" |g" "$zeta_script"
    sed -i '' "s|package \"${output_name}-dynarec\" |package \"zeta_${output_name}-dynarec\" |g" "$zeta_script"
    
    # 4. 替换标题
    sed -i '' "s|构建 ${output_name}|构建 Zeta ${output_name}|gi" "$zeta_script"
    sed -i '' "s|构建 PSP|构建 Zeta PSP|g" "$zeta_script"
    
    # 5. 替换构建定义
    sed -i '' "s|-DPPEMU_BUILD=1|-DZETA_BUILD=1|g" "$zeta_script"
    
    chmod +x "$zeta_script"
    
    log_success "✅ ${core_dir}/build-zeta.sh 创建完成"
    
    return 0
}

# 创建主构建脚本
create_main_build_script() {
    log_info "创建主 Zeta 构建脚本..."
    
    cat > "$CORES_DIR/build-zeta.sh" << 'MAINSCRIPT'
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
  "nes"
  "snes"
  "genesis"
  "saturn"
  "arcade"
  "n64"
  "nds"
  "ps1"
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
MAINSCRIPT
    
    chmod +x "$CORES_DIR/build-zeta.sh"
    
    log_success "✅ build-zeta.sh 创建完成"
}

# 主函数
main() {
    log_info "================================"
    log_info "Zeta 构建配置生成脚本"
    log_info "================================"
    echo ""
    
    local success_count=0
    local failed_count=0
    
    # 处理单变体核心
    log_info "处理单变体核心..."
    for core_config in "${SINGLE_CORES[@]}"; do
        IFS=':' read -r core_dir output_name bundle_name <<< "$core_config"
        
        if create_single_variant_zeta "$core_dir" "$output_name" "$bundle_name"; then
            ((success_count++))
        else
            ((failed_count++))
        fi
    done
    
    echo ""
    
    # 处理多变体核心
    log_info "处理多变体核心..."
    for core_config in "${MULTI_CORES[@]}"; do
        IFS=':' read -r core_dir output_name bundle_name <<< "$core_config"
        
        if create_multi_variant_zeta "$core_dir" "$output_name" "$bundle_name"; then
            ((success_count++))
        else
            ((failed_count++))
        fi
    done
    
    echo ""
    
    # 创建主构建脚本
    create_main_build_script
    
    echo ""
    log_info "=========================================="
    log_info "处理完成"
    log_info "=========================================="
    log_success "成功: ${success_count}"
    [ $failed_count -gt 0 ] && log_error "失败: ${failed_count}" || log_info "失败: 0"
    echo ""
    
    log_info "📝 下一步操作："
    echo "1. 测试单个核心的 Zeta 构建："
    echo "   cd mgba && bash build-zeta.sh"
    echo ""
    echo "2. 或者使用主脚本构建所有核心："
    echo "   bash build-zeta.sh"
    echo ""
    echo "3. 构建产物位于各核心的 output/ 目录："
    echo "   - zeta_<name>.framework"
    echo "   - zeta_<name>-framework.zip"
}

main "$@"
