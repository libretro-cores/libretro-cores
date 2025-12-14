#!/bin/bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 检查所有子模块状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for core in mgba psp flycast nes snes genesis arcade saturn n64 ps1 nds; do
  cd "$core"
  
  # 检查分支
  branch=$(git branch --show-current)
  
  # 检查 projects.json
  has_config="❌"
  if git ls-files --error-unmatch projects.json >/dev/null 2>&1; then
    has_config="✅"
  fi
  
  # 检查未推送提交
  ahead=$(git rev-list @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
  push_status="✅"
  if [ "$ahead" -gt 0 ]; then
    push_status="📤 $ahead"
  fi
  
  # 检查未提交修改
  dirty=""
  if [ -n "$(git status --porcelain)" ]; then
    dirty=" 🔧"
  fi
  
  printf "%-10s | 分支: %-10s | Config: %s | 推送: %-6s%s\n" \
    "$core" "$branch" "$has_config" "$push_status" "$dirty"
  
  cd ..
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
