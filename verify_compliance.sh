#!/usr/bin/env bash
# verify_compliance.sh - 验证 App Store 4.3 合规性
# 使用方法: bash verify_compliance.sh [PPCores路径]

CORES_DIR="${1:-/Users/coffee/Code/business/EmulatorApp/PPEmulator/PPCores}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}✅ $1${NC}"; }
fail() { echo -e "${RED}🔴 $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "=========================================="
echo "  App Store 4.3 合规性检查"
echo "=========================================="
echo "检查目录: $CORES_DIR"
echo ""

TOTAL=0
PASSED=0
FAILED=0

echo "--- 1. 配置键前缀检查 ---"
echo ""

check_config_keys() {
    local fw="$1"
    local pattern="$2"
    local binary="$CORES_DIR/${fw}.framework/${fw}"

    if [ ! -f "$binary" ]; then
        warn "$fw: 未找到 framework"
        return
    fi

    ((TOTAL++)) || true
    local count=$(strings "$binary" 2>/dev/null | grep -cE "$pattern" || echo "0")

    if [ "$count" -gt 0 ]; then
        fail "$fw: 发现 $count 个原始配置键 ($pattern)"
        strings "$binary" | grep -E "$pattern" | head -3 | sed 's/^/    /'
        ((FAILED++)) || true
    else
        pass "$fw: 无原始配置键"
        ((PASSED++)) || true
    fi
}

check_config_keys "dreamcast" "^reicast_"
check_config_keys "psp" "^ppsspp_"
check_config_keys "n64" "^mupen64plus"
check_config_keys "saturn" "^beetle_saturn_"
check_config_keys "saturn2" "^yabause_"
check_config_keys "saturn3" "^yabasanshiro_"

echo ""
echo "--- 2. 编译路径检查 ---"
echo ""

for fw in dreamcast psp n64 saturn saturn2 saturn3; do
    binary="$CORES_DIR/${fw}.framework/${fw}"

    if [ ! -f "$binary" ]; then
        continue
    fi

    count=$(strings "$binary" 2>/dev/null | grep -c "^/Users/" || echo "0")

    if [ "$count" -gt 0 ]; then
        fail "$fw: 发现 $count 个路径暴露"
        strings "$binary" | grep "^/Users/" | head -2 | sed 's/^/    /'
    else
        pass "$fw: 无路径暴露"
    fi
done

echo ""
echo "--- 3. Bundle ID 检查 ---"
echo ""

for fw in dreamcast psp n64 saturn saturn2 saturn3; do
    plist="$CORES_DIR/${fw}.framework/Info.plist"

    if [ ! -f "$plist" ]; then
        continue
    fi

    bundle_id=$(plutil -extract CFBundleIdentifier raw "$plist" 2>/dev/null || echo "未知")

    if [[ "$bundle_id" == com.ppemu.* ]]; then
        pass "$fw: $bundle_id"
    else
        fail "$fw: $bundle_id (应为 com.ppemu.*)"
    fi
done

echo ""
echo "--- 4. 品牌字符串检查 ---"
echo ""

check_brand() {
    local fw="$1"
    local pattern="$2"
    local binary="$CORES_DIR/${fw}.framework/${fw}"

    if [ ! -f "$binary" ]; then
        return
    fi

    local count=$(strings "$binary" 2>/dev/null | grep -cE "$pattern" || echo "0")

    if [ "$count" -gt 0 ]; then
        warn "$fw: 发现 $count 个品牌字符串"
        strings "$binary" | grep -E "$pattern" | head -2 | sed 's/^/    /'
    else
        pass "$fw: 无明显品牌字符串"
    fi
}

check_brand "dreamcast" "Flycast-emu"
check_brand "psp" "^PPSSPP"
check_brand "saturn" "Beetle Saturn"
check_brand "saturn3" "YabaSanshiro"

echo ""
echo "--- 5. MetalANGLE 检查 ---"
echo ""

metal_plist="$CORES_DIR/MetalANGLE.xcframework/ios-arm64/MetalANGLE.framework/Info.plist"
if [ -f "$metal_plist" ]; then
    bundle_id=$(plutil -extract CFBundleIdentifier raw "$metal_plist" 2>/dev/null || echo "未知")
    if [[ "$bundle_id" == *"google"* ]]; then
        fail "MetalANGLE: $bundle_id (包含 google)"
    else
        pass "MetalANGLE: $bundle_id"
    fi
else
    warn "MetalANGLE: 未找到"
fi

echo ""
echo "=========================================="
echo "  检查结果"
echo "=========================================="
echo "  配置键检查: $PASSED / $TOTAL 通过"
echo ""

if [ "$FAILED" -gt 0 ]; then
    echo -e "${RED}存在 4.3 风险，请参考 APPSTORE_4.3_COMPLIANCE.md 进行修复${NC}"
else
    echo -e "${GREEN}配置键检查通过！${NC}"
fi
