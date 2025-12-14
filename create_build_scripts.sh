#!/bin/bash
# 为剩余核心创建构建脚本

# Genesis
cat > genesis/build.sh << 'SCRIPT'
#!/bin/bash
# Genesis Plus GX 核心构建脚本
# 使用方法: bash build.sh [--project ppemu|zeta]

set -e

CORE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="ppemu"

while [[ $# -gt 0 ]]; do
  case $1 in
    --project) PROJECT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

BUNDLE_PREFIX=$(jq -r ".${PROJECT}.bundle_prefix" "$CORE_DIR/projects.json")
DISPLAY_NAME=$(jq -r ".${PROJECT}.display_name" "$CORE_DIR/projects.json")
MIN_IOS=$(jq -r ".${PROJECT}.min_ios_version" "$CORE_DIR/projects.json")

if [ "$BUNDLE_PREFIX" = "null" ]; then
  echo "❌ 未找到项目: $PROJECT"
  exit 1
fi

BUNDLE_ID="${BUNDLE_PREFIX}.genesis"

echo "🎮 构建 Genesis Plus GX - $DISPLAY_NAME"
echo "  Bundle ID: $BUNDLE_ID"

if [ ! -d "$CORE_DIR/genesis-src" ]; then
  echo "📥 克隆源码..."
  git clone --depth 1 --recursive https://github.com/libretro/Genesis-Plus-GX.git "$CORE_DIR/genesis-src" >/dev/null 2>&1
fi

cd "$CORE_DIR/genesis-src"

echo "  🔨 编译..."
make -f Makefile.libretro clean 2>/dev/null
make -f Makefile.libretro platform=ios-arm64 -j$(sysctl -n hw.ncpu) >/dev/null 2>&1

dylib=$(find . -name "*_libretro_ios.dylib" | head -1)

if [ -z "$dylib" ]; then
  echo "❌ 构建失败"
  exit 1
fi

output_dir="$CORE_DIR/output-${PROJECT}"
framework_path="${output_dir}/genesis.framework"
mkdir -p "$framework_path"

cp "$dylib" "$framework_path/genesis"
install_name_tool -id "@rpath/genesis.framework/genesis" "$framework_path/genesis"

cat > "$framework_path/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>genesis</string>
    <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
    <key>CFBundleName</key><string>genesis</string>
    <key>CFBundlePackageType</key><string>FMWK</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>MinimumOSVersion</key><string>${MIN_IOS}</string>
    <key>CFBundleSupportedPlatforms</key>
    <array><string>iPhoneOS</string></array>
</dict>
</plist>
PLIST

codesign --force --sign - "$framework_path/genesis" 2>/dev/null

cd "$output_dir"
zip -rq genesis-framework.zip genesis.framework

size=$(ls -lh genesis-framework.zip | awk '{print $5}')
echo "✅ genesis ($PROJECT): $size"
SCRIPT

chmod +x genesis/build.sh
echo "✅ genesis/build.sh 已创建"

