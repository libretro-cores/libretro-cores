#!/bin/bash

# Libretro 核心智能构建脚本
# 使用方法:
#   bash build.sh          - 构建所有核心
#   bash build.sh ppemu    - 只构建 PPEMU 相关核心
#   bash build.sh core_name - 构建指定核心

set -e

CORES_DIR="/Users/coffee/Code/business/libretro-cores"
VERSION="$(date +%Y%m%d)-local"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔨 Libretro iOS 核心构建脚本"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd "$CORES_DIR"

# 打包函数
package_core() {
  local core_dir=$1
  local output_name=$2
  local bundle_id=$3
  local dylib_path=$4
  
  cd "$core_dir"
  
  FRAMEWORK_PATH="output/${output_name}.framework"
  rm -rf output
  mkdir -p "$FRAMEWORK_PATH"
  
  cp "$dylib_path" "$FRAMEWORK_PATH/${output_name}"
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
  
  codesign --force --sign - "$FRAMEWORK_PATH/${output_name}" 2>/dev/null
  
  cd output
  zip -rq ${output_name}-framework.zip ${output_name}.framework
  cd ..
  
  SIZE=$(ls -lh "output/${output_name}-framework.zip" | awk '{print $5}')
  echo "✅ $output_name: $SIZE"
  
  cd ..
}

# 构建单个核心
build_core() {
  local core_name=$1
  
  case $core_name in
    mgba)
      echo "━━━ 构建 mGBA ━━━"
      cd mgba
      rm -rf mgba-src
      git clone --depth 1 --recursive https://github.com/libretro/mgba.git mgba-src
      cd mgba-src
      sed -i '' 's|^typedef const char\* locale_t;|// typedef const char* locale_t;|' include/mgba-util/formatting.h 2>/dev/null || true
      make platform=ios-arm64 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu) >/dev/null 2>&1
      cd ../..
      package_core "mgba" "mgba" "com.ppemu.core.mgba" "mgba-src/mgba_libretro_ios.dylib"
      ;;
      
    genesis)
      echo "━━━ 构建 Genesis ━━━"
      cd genesis
      rm -rf genesis-src
      git clone --depth 1 https://github.com/libretro/Genesis-Plus-GX.git genesis-src
      cd genesis-src
      make -f Makefile.libretro platform=ios-arm64 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu) >/dev/null 2>&1
      cd ../..
      package_core "genesis" "genesis" "com.ppemu.core.genesis" "genesis-src/genesis_plus_gx_libretro_ios.dylib"
      ;;
      
    nes)
      echo "━━━ 构建 NES ━━━"
      cd nes
      rm -rf nes-src
      git clone --depth 1 https://github.com/libretro/nestopia.git nes-src
      cd nes-src/libretro
      make platform=ios-arm64 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu) >/dev/null 2>&1
      cd ../../..
      package_core "nes" "nes" "com.ppemu.core.nes" "nes-src/libretro/nestopia_libretro_ios.dylib"
      ;;
      
    snes)
      echo "━━━ 构建 SNES ━━━"
      cd snes
      rm -rf snes-src
      git clone --depth 1 https://github.com/libretro/snes9x.git snes-src
      cd snes-src/libretro
      make platform=ios-arm64 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu) >/dev/null 2>&1
      cd ../../..
      package_core "snes" "snes" "com.ppemu.core.snes" "snes-src/libretro/snes9x_libretro_ios.dylib"
      ;;
      
    ps1)
      echo "━━━ 构建 PS1 ━━━"
      cd ps1
      rm -rf ps1-src
      git clone --depth 1 https://github.com/libretro/beetle-psx-libretro.git ps1-src
      cd ps1-src
      make platform=ios-arm64 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu) >/dev/null 2>&1
      cd ../..
      package_core "ps1" "ps1" "com.ppemu.core.ps1" "ps1-src/mednafen_psx_libretro_ios.dylib"
      ;;
      
    nds)
      echo "━━━ 构建 NDS ━━━"
      cd nds
      rm -rf nds-src
      git clone --depth 1 https://github.com/libretro/melonDS.git nds-src
      cd nds-src
      make platform=ios-arm64 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu) >/dev/null 2>&1
      cd ../..
      package_core "nds" "nds" "com.ppemu.core.nds" "nds-src/melonds_libretro_ios.dylib"
      ;;
      
    saturn)
      echo "━━━ 构建 Saturn ━━━"
      cd saturn
      rm -rf saturn-src
      git clone --depth 1 --recursive https://github.com/libretro/yabause.git saturn-src
      cd saturn-src
      find . -name "zutil.h" -path "*/zlib*" | while read zutil; do
        sed -i '' 's/^#.*define fdopen(fd,mode)/\/\/ &/' "$zutil"
      done
      cd yabause/src/libretro
      make platform=ios-arm64 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu) >/dev/null 2>&1
      cd ../../../../..
      package_core "saturn" "saturn" "com.ppemu.core.saturn" "saturn-src/yabause/src/libretro/yabause_libretro_ios.dylib"
      ;;
      
    arcade)
      echo "━━━ 构建 Arcade ━━━"
      cd arcade
      rm -rf arcade-src
      git clone --depth 1 https://github.com/libretro/mame2003-plus-libretro.git arcade-src
      cd arcade-src
      sed -i '' 's/^#.*define fdopen(fd,mode)/\/\/ &/' src/libretro-common/include/compat/zlib/zutil.h 2>/dev/null || true
      sed -i '' 's/^#.*define fdopen(fd,mode)/\/\/ &/' src/lib/zlib/zutil.h 2>/dev/null || true
      make platform=ios-arm64 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu) >/dev/null 2>&1
      cd ../..
      package_core "arcade" "arcade" "com.ppemu.core.arcade" "arcade-src/mame2003_plus_libretro_ios.dylib"
      ;;
      
    n64)
      echo "━━━ 构建 N64 ━━━"
      cd n64
      rm -rf n64-src
      git clone --depth 1 --recursive https://github.com/libretro/mupen64plus-libretro-nx.git n64-src
      cd n64-src
      sed -i '' '/#.*include <fp.h>/d' custom/dependencies/libpng/pngpriv.h 2>/dev/null || true
      sed -i '' 's/^#.*define fdopen(fd,mode)/\/\/ &/' custom/dependencies/libzlib/zutil.h 2>/dev/null || true
      make platform=ios-arm64 DYNAREC=0 PLATFORM_DEFINES="-DPPEMU_BUILD=1 -fvisibility=hidden" -j$(sysctl -n hw.ncpu) >/dev/null 2>&1
      cd ../..
      package_core "n64" "n64" "com.ppemu.core.n64" "n64-src/mupen64plus_next_libretro_ios.dylib"
      ;;
      
    *)
      echo "❌ 未知核心: $core_name"
      return 1
      ;;
  esac
}

# 解析参数
MODE="${1:-all}"

if [ "$MODE" = "ppemu" ]; then
  echo "📋 模式: 构建 PPEMU 核心"
  echo ""
  CORES_TO_BUILD=("mgba" "genesis" "nes" "snes" "ps1" "nds" "saturn" "arcade" "n64")
elif [ "$MODE" = "all" ]; then
  echo "📋 模式: 构建所有核心"
  echo ""
  CORES_TO_BUILD=("mgba" "genesis" "nes" "snes" "ps1" "nds" "saturn" "arcade" "n64")
else
  echo "📋 模式: 构建单个核心 ($MODE)"
  echo ""
  CORES_TO_BUILD=("$MODE")
fi

# 执行构建
SUCCESS=0
FAILED=0

for core in "${CORES_TO_BUILD[@]}"; do
  if build_core "$core" 2>&1 | grep -v "^warning:" | grep -E "(━━━|✅|❌)"; then
    ((SUCCESS++))
  else
    ((FAILED++))
    echo "❌ $core 构建失败"
  fi
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 构建完成统计"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  ✅ 成功: $SUCCESS"
echo "  ❌ 失败: $FAILED"
echo ""
echo "📦 所有产物位置: */output/*-framework.zip"
echo ""

