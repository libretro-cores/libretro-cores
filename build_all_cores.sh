#!/bin/bash

# Libretro 核心批量本地构建脚本
# 使用方法: ./build_all_cores.sh [core_name]
# 不带参数则构建所有核心

set -e

CORES_DIR="/Users/coffee/Code/business/libretro-cores"
VERSION="$(date +%Y%m%d)-local"
TAG="v${VERSION}"

# 核心配置
declare -A CORE_INFO
CORE_INFO[genesis]="Genesis-Plus-GX:genesis:com.ppemu.core.genesis"
CORE_INFO[arcade]="mame2003-plus:arcade:com.ppemu.core.arcade"
CORE_INFO[mgba]="mgba:mgba:com.ppemu.core.mgba"
CORE_INFO[nes]="nestopia:nes:com.ppemu.core.nes"
CORE_INFO[snes]="snes9x:snes:com.ppemu.core.snes"
CORE_INFO[saturn]="yabause:saturn:com.ppemu.core.saturn"

# 有多变体的核心
declare -A MULTI_VARIANT_CORES
MULTI_VARIANT_CORES[psp]="ppsspp"
MULTI_VARIANT_CORES[n64]="mupen64plus-libretro-nx"
MULTI_VARIANT_CORES[ps1]="beetle-psx-libretro"
MULTI_VARIANT_CORES[nds]="melonDS"
MULTI_VARIANT_CORES[flycast]="flycast"

build_single_core() {
  local core=$1
  local repo=$2
  local output_name=$3
  local bundle_id=$4
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎮 构建 $output_name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  cd "$CORES_DIR/$core"
  
  # 克隆源码
  echo "📥 克隆源码..."
  rm -rf ${core}-src
  
  case $core in
    mgba)
      git clone --depth 1 --recursive https://github.com/libretro/mgba.git ${core}-src
      ;;
    genesis)
      git clone --depth 1 https://github.com/libretro/Genesis-Plus-GX.git ${core}-src
      ;;
    arcade)
      git clone --depth 1 https://github.com/libretro/mame2003-plus-libretro.git ${core}-src
      ;;
    nes)
      git clone --depth 1 https://github.com/libretro/nestopia.git ${core}-src
      ;;
    snes)
      git clone --depth 1 https://github.com/libretro/snes9x.git ${core}-src
      ;;
    saturn)
      git clone --depth 1 --recursive https://github.com/libretro/yabause.git ${core}-src
      ;;
  esac
  
  cd ${core}-src
  
  # 修复 mGBA 的 locale_t 问题
  if [ "$core" = "mgba" ]; then
    sed -i '' 's|^typedef const char\* locale_t;|// typedef const char* locale_t;|' include/mgba-util/formatting.h 2>/dev/null || true
  fi
  
  # 构建
  echo "🔨 构建中..."
  make clean 2>/dev/null || true
  
  if [ "$core" = "genesis" ]; then
    make -f Makefile.libretro platform=ios-arm64 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu)
  elif [ "$core" = "snes" ]; then
    cd libretro
    make platform=ios-arm64 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu)
    cd ..
  elif [ "$core" = "nes" ]; then
    cd libretro
    make platform=ios-arm64 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu)
    cd ..
  elif [ "$core" = "saturn" ]; then
    cd yabause/src/libretro
    make platform=ios-arm64 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu)
    cd ../../..
  else
    make platform=ios-arm64 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu)
  fi
  
  # 查找产物
  DYLIB_PATH=$(find . -name "*_libretro_ios.dylib" | head -1)
  
  if [ -z "$DYLIB_PATH" ]; then
    echo "❌ 构建失败：未找到产物"
    return 1
  fi
  
  echo "✅ 构建成功: $(ls -lh "$DYLIB_PATH" | awk '{print $5}')"
  
  cd ..
  
  # 创建 Framework
  echo "📦 创建 Framework..."
  FRAMEWORK_PATH="output/${output_name}.framework"
  rm -rf output
  mkdir -p "$FRAMEWORK_PATH"
  
  cp "$DYLIB_PATH" "$FRAMEWORK_PATH/${output_name}"
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
  
  SIZE=$(ls -lh output/${output_name}-framework.zip | awk '{print $5}')
  echo "✅ Framework 已打包: $SIZE"
  
  # 上传到 GitHub Release
  echo "🚀 上传到 GitHub..."
  
  # 检查 release 是否存在
  if gh release view "$TAG" --repo "libretro-cores/$core" &>/dev/null; then
    # 已存在，添加文件
    gh release upload "$TAG" output/${output_name}-framework.zip --clobber --repo "libretro-cores/$core"
  else
    # 创建新 release
    gh release create "$TAG" \
      output/${output_name}-framework.zip \
      --title "${output_name} iOS Framework ${VERSION}" \
      --notes "## ${output_name} iOS Framework

- **Bundle ID**: ${bundle_id}
- **架构**: iOS arm64
- **最低版本**: iOS 15.0
- **构建时间**: ${VERSION}
- **文件大小**: $SIZE

🔧 本地构建" \
      --repo "libretro-cores/$core"
  fi
  
  echo "✅ $output_name 完成！"
}

# 主函数
main() {
  if [ $# -eq 0 ]; then
    echo "=== 🚀 批量构建所有单核心（6个）==="
    for core in genesis arcade mgba nes snes saturn; do
      IFS=':' read -r repo output_name bundle_id <<< "${CORE_INFO[$core]}"
      build_single_core "$core" "$repo" "$output_name" "$bundle_id" || echo "⚠️  $core 构建失败，继续下一个..."
    done
  else
    # 构建指定核心
    core=$1
    IFS=':' read -r repo output_name bundle_id <<< "${CORE_INFO[$core]}"
    build_single_core "$core" "$repo" "$output_name" "$bundle_id"
  fi
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎉 所有构建任务完成！"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

main "$@"

