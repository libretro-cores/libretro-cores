#!/bin/bash

# 一键上传所有已构建的核心到 GitHub Release
# 自动检测所有产物并上传
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

SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# 自动检测所有构建产物
find . -path "*/output/*-framework.zip" -type f 2>/dev/null | sort | while read zip_file; do
  core_dir=$(dirname $(dirname "$zip_file"))
  core_name=$(basename "$core_dir")
  variant=$(basename "$zip_file" | sed 's/-framework.zip//')
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 处理: $core_name/$variant"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  cd "$CORES_DIR/$core_name"
  
  # 检查是否是 git 仓库（.git 可能是文件或目录）
  if [ ! -e .git ]; then
    echo "⏭️  跳过（不是 git 仓库）"
    continue
  fi
  
  # 获取远程仓库信息
  REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
  if [ -z "$REMOTE_URL" ]; then
    echo "⏭️  跳过（无远程仓库）"
    continue
  fi
  
  # 解析仓库 owner 和 name
  if [[ "$REMOTE_URL" =~ github.com[:/]([^/]+)/([^/.]+) ]]; then
    REPO_OWNER="${BASH_REMATCH[1]}"
    REPO_NAME="${BASH_REMATCH[2]}"
  else
    echo "❌ 无法解析仓库信息: $REMOTE_URL"
    continue
  fi
  
  # 获取当前分支
  BRANCH=$(git branch --show-current)
  
  # 读取 Bundle ID 和架构
  PLIST_FILE="output/${variant}.framework/Info.plist"
  if [ -f "$PLIST_FILE" ]; then
    BUNDLE_ID=$(grep -A1 "CFBundleIdentifier" "$PLIST_FILE" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    MIN_IOS=$(grep -A1 "MinimumOSVersion" "$PLIST_FILE" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
  else
    BUNDLE_ID="com.ppemu.core.$variant"
    MIN_IOS="15.0"
  fi
  
  # 获取文件大小
  SIZE=$(ls -lh "output/${variant}-framework.zip" | awk '{print $5}')
  
  echo ""
  echo "  仓库: $REPO_OWNER/$REPO_NAME"
  echo "  分支: $BRANCH"
  echo "  变体: $variant"
  echo "  大小: $SIZE"
  echo "  Bundle ID: $BUNDLE_ID"
  echo ""
  
  # 构建 Release 信息
  RELEASE_TITLE="iOS Framework - $variant - $TAG"
  RELEASE_BODY="## 📦 $variant Framework

### 📊 构建信息
- **核心**: $variant
- **版本**: $TAG
- **分支**: $BRANCH
- **大小**: $SIZE
- **架构**: arm64
- **Bundle ID**: \`$BUNDLE_ID\`
- **最低 iOS**: $MIN_IOS+

### 📥 使用方法
\`\`\`swift
// 解压后将 ${variant}.framework 添加到 Xcode 项目
// Embed & Sign 该 Framework
\`\`\`

---
🤖 自动构建于 $(date '+%Y-%m-%d %H:%M:%S')
"
  
  # 检查 Release 是否存在
  echo "🔍 检查 Release: $TAG"
  if gh release view "$TAG" --repo "$REPO_OWNER/$REPO_NAME" >/dev/null 2>&1; then
    echo "✅ Release 已存在，追加上传..."
    
    # 删除旧资产（如果存在）
    gh release delete-asset "$TAG" "${variant}-framework.zip" \
      --repo "$REPO_OWNER/$REPO_NAME" --yes 2>/dev/null || true
    
    # 上传资产
    if gh release upload "$TAG" "output/${variant}-framework.zip" \
      --repo "$REPO_OWNER/$REPO_NAME" --clobber; then
      echo "✅ 上传成功: ${variant}-framework.zip"
    else
      echo "❌ 上传失败"
      exit 1
    fi
  else
    echo "📝 创建新 Release..."
    
    if gh release create "$TAG" \
      "output/${variant}-framework.zip" \
      --repo "$REPO_OWNER/$REPO_NAME" \
      --title "$RELEASE_TITLE" \
      --notes "$RELEASE_BODY" \
      --target "$BRANCH"; then
      echo "✅ Release 创建成功"
    else
      echo "❌ Release 创建失败"
      exit 1
    fi
  fi
  
  echo "✅ $core_name/$variant 完成！"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 上传完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
