#!/bin/bash

# Zeta 分支自动化创建脚本
# 为所有 11 个 libretro 核心创建 Zeta 分支并修改配置

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 核心配置映射
# 格式: "目录名:输出名:Bundle ID 名称:是否多变体"
declare -a CORES=(
    "mgba:gba:gba:single"
    "nes:nes:nes:single"
    "snes:snes:snes:single"
    "genesis:genesis:genesis:single"
    "saturn:saturn:saturn:single"
    "arcade:arcade:arcade:single"
    "n64:n64:n64:multi"
    "nds:nds:nds:multi"
    "ps1:ps1:ps1:multi"
    "psp:psp:psp:multi"
    "flycast:dreamcast:dreamcast:multi"
)

# 处理单个核心
process_core() {
    local core_dir=$1
    local output_name=$2
    local bundle_name=$3
    local variant_type=$4
    
    log_info "处理核心: ${core_dir} (${output_name})"
    
    # 检查目录是否存在
    if [ ! -d "$core_dir" ]; then
        log_error "目录不存在: $core_dir"
        return 1
    fi
    
    cd "$core_dir"
    
    # 检查是否有未提交的更改
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_warning "$core_dir 有未提交的更改，跳过"
        cd ..
        return 0
    fi
    
    # 切换到 PPEMU 分支
    log_info "切换到 PPEMU 分支..."
    if ! git checkout PPEMU 2>/dev/null; then
        log_error "无法切换到 PPEMU 分支"
        cd ..
        return 1
    fi
    
    # 拉取最新代码
    log_info "拉取最新代码..."
    git pull origin PPEMU || log_warning "拉取失败，使用本地版本"
    
    # 检查 Zeta 分支是否已存在
    if git rev-parse --verify Zeta >/dev/null 2>&1; then
        log_warning "Zeta 分支已存在，切换到该分支"
        git checkout Zeta
    else
        # 创建 Zeta 分支
        log_info "创建 Zeta 分支..."
        git checkout -b Zeta
    fi
    
    # 修改 workflow 文件
    local workflow_file=".github/workflows/build-ios.yml"
    
    if [ ! -f "$workflow_file" ]; then
        log_error "Workflow 文件不存在: $workflow_file"
        cd ..
        return 1
    fi
    
    log_info "修改 workflow 文件..."
    
    # 创建备份
    cp "$workflow_file" "${workflow_file}.bak"
    
    # 使用 sed 进行替换
    # 1. 替换触发分支 PPEMU -> Zeta
    sed -i '' 's/branches: \[ PPEMU, main \]/branches: [ Zeta, main ]/g' "$workflow_file"
    
    # 2. 替换 OUTPUT_NAME (添加 zeta_ 前缀)
    sed -i '' "s/OUTPUT_NAME: ${output_name}/OUTPUT_NAME: zeta_${output_name}/g" "$workflow_file"
    
    # 3. 替换 BUNDLE_ID
    sed -i '' "s/com\.ppemu\.core\.${bundle_name}/com.zeta.core.${bundle_name}/g" "$workflow_file"
    
    # 4. 替换 Release 条件中的分支检查
    sed -i '' "s/refs\/heads\/PPEMU/refs\/heads\/Zeta/g" "$workflow_file"
    
    # 5. 替换 Info.plist 中的硬编码值 (对于单变体核心)
    if [ "$variant_type" = "single" ]; then
        sed -i '' "s/<string>${output_name}<\/string>/<string>zeta_${output_name}<\/string>/g" "$workflow_file"
    fi
    
    # 6. 替换 Release 标题
    sed -i '' "s/name: ${output_name}\.framework/name: Zeta ${output_name} Core/g" "$workflow_file"
    sed -i '' "s/name: PSP Cores/name: Zeta PSP Cores/g" "$workflow_file"
    
    # 7. 对于多变体核心，需要处理 matrix 中的变体名称
    if [ "$variant_type" = "multi" ]; then
        # 替换 matrix 中的变体名称
        sed -i '' "s/- name: ${output_name}$/- name: zeta_${output_name}/g" "$workflow_file"
        sed -i '' "s/- name: ${output_name}-jit$/- name: zeta_${output_name}-jit/g" "$workflow_file"
        sed -i '' "s/- name: ${output_name}-dynarec$/- name: zeta_${output_name}-dynarec/g" "$workflow_file"
    fi
    
    # 检查是否有实际修改
    if git diff --quiet "$workflow_file"; then
        log_warning "没有检测到修改，可能已经是 Zeta 配置"
        rm "${workflow_file}.bak"
        cd ..
        return 0
    fi
    
    # 显示修改差异
    log_info "修改差异:"
    git diff "$workflow_file" | head -50
    
    # 提交更改
    log_info "提交更改..."
    git add "$workflow_file"
    git commit -m "feat: create Zeta branch with rebranded workflow

- Change trigger branch from PPEMU to Zeta
- Update OUTPUT_NAME to zeta_${output_name}
- Update BUNDLE_ID to com.zeta.core.${bundle_name}
- Update Release configuration for Zeta branch"
    
    # 推送到远程
    log_info "推送到远程..."
    if git push origin Zeta; then
        log_success "✅ ${core_dir} 处理完成"
    else
        log_warning "推送失败，可能需要手动推送"
    fi
    
    # 清理备份文件
    rm -f "${workflow_file}.bak"
    
    cd ..
    return 0
}

# 主函数
main() {
    log_info "================================"
    log_info "Zeta 分支批量创建脚本"
    log_info "================================"
    log_info "将处理 ${#CORES[@]} 个核心"
    echo ""
    
    # 统计
    local success_count=0
    local failed_count=0
    local skipped_count=0
    
    # 遍历所有核心
    for core_config in "${CORES[@]}"; do
        IFS=':' read -r core_dir output_name bundle_name variant_type <<< "$core_config"
        
        echo ""
        log_info "=========================================="
        log_info "开始处理: ${core_dir}"
        log_info "=========================================="
        
        if process_core "$core_dir" "$output_name" "$bundle_name" "$variant_type"; then
            ((success_count++))
        else
            ((failed_count++))
        fi
    done
    
    # 输出总结
    echo ""
    log_info "=========================================="
    log_info "处理完成"
    log_info "=========================================="
    log_success "成功: ${success_count}"
    [ $failed_count -gt 0 ] && log_error "失败: ${failed_count}" || log_info "失败: 0"
    log_info "总计: ${#CORES[@]}"
    echo ""
    
    # 显示下一步操作
    log_info "下一步操作："
    echo "1. 检查每个核心的 Zeta 分支是否正确推送"
    echo "2. 在 GitHub 上手动触发一次构建测试"
    echo "   cd mgba && gh workflow run build-ios.yml --ref Zeta"
    echo "3. 验证构建产物的 Bundle ID 和命名"
    echo "4. 更新主仓库 README.md"
}

# 执行主函数
main "$@"








