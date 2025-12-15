# Libretro 核心 iOS 构建项目

## 📦 包含的核心（12个）

### 🎮 有多变体支持的核心（5个）

1. **Flycast (Dreamcast)** - `/flycast`
   - ✅ `dreamcast.framework` - 标准版（解释器，iOS 推荐）
   - ⚠️ `dreamcast-jit.framework` - JIT 版（iOS 不可用）
   - 文件：406 行

2. **PSP (PPSSPP)** - `/psp`
   - ✅ `psp.framework` - 标准版（解释器，iOS 推荐）
   - ⚠️ `psp-jit.framework` - JIT 版（iOS 可能不稳定）
   - 文件：469 行

3. **N64 (Mupen64Plus)** - `/n64`
   - ✅ `n64.framework` - 标准版（解释器，iOS 推荐）
   - ⚠️ `n64-dynarec.framework` - Dynarec 版（iOS 不可用）
   - 文件：305 行

4. **PS1 (Beetle PSX)** - `/ps1`
   - ✅ `ps1.framework` - 标准版（解释器，iOS 推荐）
   - ⚠️ `ps1-dynarec.framework` - Dynarec 版（iOS 不可用）
   - 文件：307 行

5. **NDS (melonDS)** - `/nds`
   - ✅ `nds.framework` - 标准版（解释器，iOS 推荐）
   - ⚠️ `nds-jit.framework` - JIT 版（iOS 不可用）
   - 文件：305 行

### 📱 单版本核心（7个）

6. **Genesis (Genesis Plus GX)** - `/genesis` - 363 行
7. **Arcade (MAME 2003+)** - `/arcade` - 373 行
8. **mGBA (Game Boy Advance)** - `/mgba` - 233 行
9. **NES (Nestopia)** - `/nes` - 241 行
10. **Saturn (Yabause)** - `/saturn` - 241 行
11. **SNES (SNES9x)** - `/snes` - 241 行
12. **PCE (Beetle PCE FAST)** - `/pce` - PC Engine/TurboGrafx-16 - 95 行

## 🔧 构建配置

### GitHub Actions 配置
- 每个核心都有 `.github/workflows/build-ios.yml`
- 已配置飞书通知
- 已配置自动 Release（PPEMU 分支）

### 变体命名规则
- **标准版**（无后缀）= 解释器/无 JIT - ✅ iOS 可用
- **特殊版**（-jit/-dynarec）= JIT/Dynarec - ⚠️ iOS 受限

### 最低 iOS 版本
- 所有核心：iOS 15.0+

## 🚀 手动构建

每个核心目录下的 workflow 文件包含完整的构建步骤。

## 📝 状态

- ✅ 所有本地改动已推送到远程
- ✅ Workflow 文件已验证（200-469 行）
- ✅ 已复制到本地工作目录

## 🔗 远程仓库

所有核心都在 `libretro-cores` organization 下：
- `PPEMU` 分支包含最新的多变体构建配置
- 远程地址：`github.com:libretro-cores/{core-name}.git`






