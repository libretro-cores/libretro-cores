#!/bin/bash

# Libretro 核心批量本地构建和上传脚本
# 使用方法: ./build_and_upload.sh [core_name]

CORES_DIR="/Users/coffee/Code/business/libretro-cores"
VERSION="$(date +%Y%m%d)-local"
TAG="v${VERSION}"

build_core() {
  local core=$1
  local output_name=$2  
  local bundle_id=$3
  local git_url=$4
  local makefile=$5
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎮 构建 $output_name ($core)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  cd "$CORES_DIR/$core"
  
  # 1. 克隆源码
  echo "📥 克隆源码..."
  rm -rf ${core}-src
  git clone --depth 1 --recursive "$git_url" ${core}-src
  
  cd ${core}-src
  
  # 2. 特殊修复
  if [ "$core" = "mgba" ]; then
    sed -i '' 's|^typedef const char\* locale_t;|// typedef const char* locale_t;|' include/mgba-util/formatting.h 2>/dev/null || true
  fi
  
  # 3. 构建
  echo "🔨 构建中..."
  make clean 2>/dev/null || true
  
  if [ -n "$makefile" ]; then
    make -f "$makefile" platform=ios-arm64 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu)
  else
    make platform=ios-arm64 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu)
  fi
  
  # 4. 查找产物
  DYLIB_PATH=$(find . -name "*_libretro_ios.dylib" -o -name "*_libretro.dylib" | head -1)
  
  if [ -z "$DYLIB_PATH" ]; then
    echo "❌ 未找到构建产物"
    echo "尝试查找的文件："
    find . -name "*.dylib" | head -5
    cd ..
    return 1
  fi
  
  SIZE=$(ls -lh "$DYLIB_PATH" | awk '{print $5}')
  echo "✅ 构建成功: $SIZE"
  
  # 获取绝对路径
  DYLIB_FULL_PATH="$(pwd)/$DYLIB_PATH"
  
  cd ..
  
  # 5. 创建 Framework
  echo "📦 创建 Framework..."
  FRAMEWORK_PATH="output/${output_name}.framework"
  rm -rf output
  mkdir -p "$FRAMEWORK_PATH"
  
  cp "$DYLIB_FULL_PATH" "$FRAMEWORK_PATH/${output_name}"
  install_name_tool -id "@rpath/${output_name}.framework/${output_name}" "$FRAMEWORK_PATH/${output_name}"
  
  cat > "$FRAMEWORK_PATH/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${output_name}</string>
    <key>CFBundleIdentifier</key>
    <string>${bundle_id}</string>
    <key>CFBundleName</key>
    <string>${output_name}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>15.0</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>iPhoneOS</string>
    </array>
</dict>
</plist>
PLIST
  
  codesign --force --sign - "$FRAMEWORK_PATH/${output_name}"
  
  cd output
  zip -rq ${output_name}-framework.zip ${output_name}.framework
  cd ..
  
  ZIP_SIZE=$(ls -lh output/${output_name}-framework.zip | awk '{print $5}')
  echo "✅ 已打包: $ZIP_SIZE"
  
  # 6. 上传到 GitHub
  echo "🚀 上传到 GitHub..."
  
  if gh release view "$TAG" --repo "libretro-cores/$core" &>/dev/null; then
    gh release upload "$TAG" output/${output_name}-framework.zip --clobber --repo "libretro-cores/$core"
  else
    gh release create "$TAG" \
      output/${output_name}-framework.zip \
      --title "${output_name} iOS Framework ${VERSION}" \
      --notes "## ${output_name} iOS Framework

- **Bundle ID**: ${bundle_id}
- **架构**: iOS arm64
- **最低版本**: iOS 15.0
- **构建时间**: ${VERSION}
- **文件大小**: $ZIP_SIZE

🔧 本地构建" \
      --repo "libretro-cores/$core"
  fi
  
  echo "✅ $output_name 完成！"
}

# 主函数
if [ $# -eq 0 ]; then
  echo "=== 🚀 构建所有单核心（6个）==="
  echo "时间: $(date)"
  
  build_core "genesis" "genesis" "com.ppemu.core.genesis" "https://github.com/libretro/Genesis-Plus-GX.git" "Makefile.libretro"
  build_core "arcade" "arcade" "com.ppemu.core.arcade" "https://github.com/libretro/mame2003-plus-libretro.git" ""
  build_core "nes" "nes" "com.ppemu.core.nes" "https://github.com/libretro/nestopia.git" ""
  build_core "snes" "snes" "com.ppemu.core.snes" "https://github.com/libretro/snes9x.git" ""
  build_core "saturn" "saturn" "com.ppemu.core.saturn" "https://github.com/libretro/yabause.git" ""
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎉 所有核心构建完成！"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
  # 构建指定核心
  case $1 in
    genesis) build_core "genesis" "genesis" "com.ppemu.core.genesis" "https://github.com/libretro/Genesis-Plus-GX.git" "Makefile.libretro" ;;
    arcade) build_core "arcade" "arcade" "com.ppemu.core.arcade" "https://github.com/libretro/mame2003-plus-libretro.git" "" ;;
    mgba) build_core "mgba" "mgba" "com.ppemu.core.mgba" "https://github.com/libretro/mgba.git" "" ;;
    nes) build_core "nes" "nes" "com.ppemu.core.nes" "https://github.com/libretro/nestopia.git" "" ;;
    snes) build_core "snes" "snes" "com.ppemu.core.snes" "https://github.com/libretro/snes9x.git" "" ;;
    saturn) build_core "saturn" "saturn" "com.ppemu.core.saturn" "https://github.com/libretro/yabause.git" "" ;;
    *) echo "❌ 未知核心: $1"; exit 1 ;;
  esac
fi

