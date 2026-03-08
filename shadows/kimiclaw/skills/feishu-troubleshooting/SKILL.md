---
name: feishu-troubleshooting
description: OpenClaw 飞书插件排查与修复指南。当飞书通道出现连接异常、插件加载失败、配置死锁、版本不兼容、消息重复等问题时激活此 skill。触发词：飞书插件报错、feishu plugin error、plugin not found feishu、duplicate plugin、config deadlock、飞书掉线排查。
---

# OpenClaw 飞书插件排查 Skill

## 适用场景

飞书通道出现以下任何一种问题时使用本 skill：
- 插件加载失败
- 配置校验死锁
- 版本不兼容
- 连接不稳定 / 断线重连
- 消息重复
- 依赖缺失

---

## 排查流程（按顺序执行）

### Step 0：收集基础信息

```bash
openclaw --version                    # 核心版本
openclaw status 2>&1 | head -30       # 整体状态
ls ~/.openclaw/extensions/            # 已安装的插件
cat ~/.openclaw/openclaw.json | grep -A20 "feishu"  # 飞书配置
```

### Step 1：检查配置死锁

**症状**：任何 `openclaw` 命令都报 `Invalid config` / `plugin not found: feishu`

**原因**：`openclaw.json` 中引用了 feishu 配置，但插件未安装。CLI 执行前强制校验配置，形成死锁。

**修复**：
```bash
# 临时删除 openclaw.json 中的 feishu 相关配置节点
# 然后再安装插件
openclaw plugins install @openclaw/feishu
# 安装完成后恢复 feishu 配置
openclaw gateway restart
```

**预防**：永远先装插件，再写配置。不要反过来。

### Step 2：检查版本兼容性

**症状**：`createFixedWindowRateLimiter is not a function` 或其他 `is not a function` 报错

**原因**：OpenClaw 核心版本和飞书插件版本不匹配。

**修复**：
```bash
openclaw --version
# 查看插件要求的最低版本
cat ~/.openclaw/extensions/feishu/package.json | grep "peerDependencies" -A3
# 如果核心版本低于要求，升级：
npm install -g openclaw@latest
```

**规则**：`@m1heng-clawd/feishu` 插件要求 OpenClaw `>=2026.3.1`。

### Step 3：检查重复插件

**症状**：`duplicate plugin id detected`

**原因**：`~/.openclaw/extensions/` 目录下有多个飞书插件（包括备份文件夹）。OpenClaw 会深度扫描该目录。

**修复**：
```bash
# 找出所有飞书相关目录
find ~/.openclaw/extensions/ -name "package.json" -exec grep -l "feishu" {} \;
# 把备份移到 extensions 目录外面
mv ~/.openclaw/extensions/feishu_backup ~/feishu_backup_20260308
mv ~/.openclaw/extensions/feishu.bak* ~/
```

**规则**：`~/.openclaw/extensions/` 下不能有任何同 id 的备份文件夹。备份必须移到该目录外。

### Step 4：检查依赖完整性

**症状**：`Cannot find module '@larksuiteoapi/node-sdk'` 或 `Cannot find module 'xxx'`

**原因**：`openclaw plugins install` 未成功触发 npm 依赖安装。

**修复**：
```bash
# 找到插件实际路径
FEISHU_DIR=$(find ~/.openclaw/extensions /usr/lib/node_modules/openclaw/extensions -name "feishu" -type d 2>/dev/null | head -1)
cd "$FEISHU_DIR"
npm install
```

### Step 5：检查 SDK 路径解析

**症状**：`Cannot find module '.../plugin-sdk/index.js/feishu'`

**原因**：插件 `import "openclaw/plugin-sdk"` 的路径解析失败，通常是 peer dependency 未正确链接。

**修复方案 A（推荐）**：直接 link 到内置插件
```bash
mv ~/.openclaw/extensions/feishu ~/.openclaw/extensions/feishu.bak
# 找到内置插件路径（以下二选一）
ln -s /app/extensions/feishu ~/.openclaw/extensions/feishu
# 或
ln -s /usr/lib/node_modules/openclaw/extensions/feishu ~/.openclaw/extensions/feishu
```

**修复方案 B**：重新安装插件
```bash
rm -rf ~/.openclaw/extensions/feishu
openclaw plugins install @openclaw/feishu
```

### Step 6：检查连接稳定性

**症状**：飞书消息间歇性收不到、夜间掉线、恢复后重复回复

**排查**：
```bash
# 检查去重文件是否存在且持久化
ls -la ~/.openclaw/feishu/dedup/
cat ~/.openclaw/feishu/dedup/default.json | python3 -m json.tool | head -20

# 检查代理设置（代理可能导致 WS 空闲断连）
echo "HTTPS_PROXY=$HTTPS_PROXY"
echo "HTTP_PROXY=$HTTP_PROXY"

# 开详细日志
# 在 openclaw.json 中加：
# "logging": { "level": "debug" },
# "diagnostics": { "enabled": true, "flags": ["feishu.*"] }
# 然后重启 gateway，搜索日志中的 disconnect/error/reconnect
```

### Step 7：检查第三方插件心跳 bug

**症状**：日志中每 5 分钟出现 `[feishu-trace] Heartbeat failed: TypeError: Cannot read properties of undefined`

**原因**：第三方插件 `@m1heng-clawd/feishu` 的 `trace-heartbeat.ts` 调用 `resolveFeishuAccount` 时 `params.cfg` 为 undefined。

**修复**：切换到官方内置插件（见 Step 5 方案 A）。

---

## 全新部署检查清单

如果从零开始部署，按以下顺序操作可避开所有已知坑：

1. ✅ 安装 Node.js v22+
2. ✅ `npm install -g openclaw@latest`（确认版本 >=2026.3.1）
3. ✅ `openclaw plugins install @openclaw/feishu`
4. ✅ 进入插件目录 `npm install` 补齐依赖
5. ✅ `openclaw channels add` 配置飞书（先装插件再配置，不要反过来）
6. ✅ `openclaw doctor --fix`
7. ✅ `openclaw gateway start`
8. ✅ `openclaw status` 确认无报错

---

## 经验总结（铁律）

| 编号 | 规则 | 原因 |
|---|---|---|
| 1 | **先装插件，再写配置** | 反过来会导致配置死锁 |
| 2 | **备份文件夹必须移出 extensions/** | OpenClaw 深度扫描会导致 duplicate plugin |
| 3 | **升级核心前检查插件兼容性** | Breaking change 会导致运行时崩溃 |
| 4 | **插件安装后手动 npm install** | CLI 的 npm 钩子不总是可靠 |
| 5 | **优先用内置插件 link，不用 npm 安装** | 避免 peer dependency 路径解析问题 |
| 6 | **不要在生产环境用逆向 API** | 随时会被风控拦截 |

---

*本 skill 基于 2026-03-08 Kimi龙虾实际排查经验整理。如有新的故障模式，请更新此文档。*
