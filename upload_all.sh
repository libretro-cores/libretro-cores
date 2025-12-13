#!/bin/bash

# 一键上传所有已构建的核心到 GitHub Release
# 自动读取每个核心的 git 分支和远程仓库
# 使用方法: bash upload_all.sh

set -e

CORES_DIR="/Users/coffee/Code/business/libretro-cores"
VERSION="$(date +%Y%m%d)-local"
TAG="v${VERSION}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 批量上传 Libretro iOS 核心到 GitHub"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 版本信息:"
echo "  Tag: $TAG"
echo "  时间: $(date)"
echo ""

cd "$CORES_DIR"

# 核心列表（只需指定目录名和输出名）
declare -a CORES=(
  "mgba:mgba:Game Boy Advance"
  "genesis:genesis:Sega Genesis/Mega Drive"
  "nes:nes:Nintendo Entertainment System"
  "snes:snes:Super Nintendo"
  "ps1:ps1:PlayStation 1"
  "nds:nds:Nintendo DS"
  "saturn:saturn:Sega Saturn"
  "arcade:arcade:Arcade (MAME 2003+)"
  "n64:n64:Nintendo 64"
)

SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

for core_info in "${CORES[@]}"; do
  IFS=':' read -r core_dir output_name description <<< "$core_info"
  
  ZIP_FILE="$core_dir/output/${output_name}-framework.zip"
  
  # 检查文件是否存在
  if [ ! -f "$ZIP_FILE" ]; then
    echo "⏭️  跳过 $output_name（未找到构建产物）"
    ((SKIP_COUNT++))
    continue
  fi
  
  # 读取 git 信息
  cd "$core_dir"
  
  if [ ! -d ".git" ]; then
    echo "⏭️  跳过 $output_name（不是 git 仓库）"
    ((SKIP_COUNT++))
    cd ..
    continue
  fi
  
  BRANCH=$(git branch --show-current 2>/dev/null)
  REMOTE_URL=$(git remote get-url origin 2>/dev/null)
  
  if [ -z "$BRANCH" ] || [ -z "$REMOTE_URL" ]; then
    echo "⏭️  跳过 $output_name（无法读取 git 信息）"
    ((SKIP_COUNT++))
    cd ..
    continue
  fi
  
  # 从远程 URL 提取仓库信息
  # 支持格式: git@github.com:owner/repo.git 或 https://github.com/owner/repo.git
  if [[ "$REMOTE_URL" =~ git@github\.com:(.+)\.git ]]; then
    REPO="${BASH_REMATCH[1]}"
  elif [[ "$REMOTE_URL" =~ github\.com/(.+)\.git ]]; then
    REPO="${BASH_REMATCH[1]}"
  elif [[ "$REMOTE_URL" =~ github\.com/(.+)$ ]]; then
    REPO="${BASH_REMATCH[1]}"
  else
    echo "⏭️  跳过 $output_name（无法解析远程 URL: $REMOTE_URL）"
    ((SKIP_COUNT++))
    cd ..
    continue
  fi
  
  # 读取 Bundle ID
  BUNDLE_ID=$(grep -A 1 "CFBundleIdentifier" "output/${output_name}.framework/Info.plist" 2>/dev/null | grep -o "com\.ppemu\.core\.[^<]*" || echo "com.ppemu.core.${output_name}")
  
  cd ..
  
  SIZE=$(ls -lh "$ZIP_FILE" | awk '{print $5}')
  
  echo ""
  echo "━━━ 上传 $output_name ($description) ━━━"
  echo "  文件: $ZIP_FILE"
  echo "  大小: $SIZE"
  echo "  仓库: $REPO"
  echo "  分支: $BRANCH"
  echo "  Bundle ID: $BUNDLE_ID"
  
  # 检查 release 是否已存在
  if gh release view "$TAG" --repo "$REPO" &>/dev/null; then
    echo "  📝 Release 已存在，上传文件..."
    if gh release upload "$TAG" "$ZIP_FILE" --clobber --repo "$REPO" 2>&1 | grep -v "Uploading"; then
      echo "  ✅ $output_name 上传成功！"
      ((SUCCESS_COUNT++))
    else
      echo "  ❌ $output_name 上传失败"
      ((FAIL_COUNT++))
    fi
  else
    echo "  📝 创建新 Release..."
    if gh release create "$TAG" \
      "$ZIP_FILE" \
      --title "$description iOS Framework ${VERSION}" \
      --notes "## $description iOS Framework

- **Bundle ID**: $BUNDLE_ID
- **架构**: iOS arm64
- **最低版本**: iOS 15.0
- **构建时间**: ${VERSION}
- **文件大小**: $SIZE
- **分支**: $BRANCH

🔧 本地构建并上传" \
      --repo "$REPO" 2>&1 | grep -v "Uploading"; then
      echo "  ✅ $output_name 上传成功！"
      ((SUCCESS_COUNT++))
    else
      echo "  ❌ $output_name 上传失败"
      ((FAIL_COUNT++))
    fi
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 上传完成统计"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  ✅ 成功: $SUCCESS_COUNT"
echo "  ❌ 失败: $FAIL_COUNT"
echo "  ⏭️  跳过: $SKIP_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ] && [ $SUCCESS_COUNT -gt 0 ]; then
  echo "🎉 所有核心上传成功！"
  echo ""
  echo "查看 Releases:"
  for core_info in "${CORES[@]}"; do
    IFS=':' read -r core_dir output_name _ <<< "$core_info"
    if [ -f "$core_dir/output/${output_name}-framework.zip" ]; then
      cd "$core_dir"
      REMOTE_URL=$(git remote get-url origin 2>/dev/null)
      if [[ "$REMOTE_URL" =~ git@github\.com:(.+)\.git ]] || [[ "$REMOTE_URL" =~ github\.com/(.+)\.git ]] || [[ "$REMOTE_URL" =~ github\.com/(.+)$ ]]; then
        REPO="${BASH_REMATCH[1]}"
        echo "  • https://github.com/$REPO/releases/tag/$TAG"
      fi
      cd ..
    fi
  done
elif [ $SUCCESS_COUNT -eq 0 ] && [ $SKIP_COUNT -gt 0 ]; then
  echo "ℹ️  没有需要上传的核心"
else
  echo "⚠️  部分核心上传失败，请检查错误信息"
  exit 1
fi
