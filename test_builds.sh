#!/bin/bash
# 批量测试多项目构建

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 批量测试多项目构建"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SUCCESS=0
FAIL=0

test_core() {
  local core=$1
  local project=$2
  
  echo "📦 测试 $core - $project"
  cd "$core"
  
  if bash build.sh --project "$project" >/dev/null 2>&1; then
    echo "  ✅ 成功"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "  ❌ 失败"
    FAIL=$((FAIL + 1))
  fi
  
  cd ..
}

# 测试单核心
for core in mgba nes snes; do
  test_core "$core" "ppemu"
  test_core "$core" "zeta"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 测试结果: ✅ $SUCCESS  ❌ $FAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
