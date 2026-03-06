---
name: token-tracker
description: OpenClaw Token 消耗追踪器。实时记录、累计统计、与快照集成。
version: 1.0.0
author: Kimi Claw
license: MIT
---

# Token Tracker

## 概述

解决 OpenClaw 原生 token 统计不准确的问题（compaction 后 output token 重置为 0）。

本工具提供：
- ✅ 准确的累计 token 统计（不受 compaction 影响）
- ✅ 按模型、按天分类统计
- ✅ 与 snapshot-sync 集成，自动备份到 GitHub
- ✅ 支持导入/导出，换机器不丢数据

## 问题背景

OpenClaw 自带的 `session_status` 显示的 token 数有问题：
- **输入 token**（12k）看起来对，因为是重新计算的
- **输出 token**（94）只显示最后一次，因为 compaction 后被重置为 `void 0`

**根本原因**（源码分析）：
```javascript
// /usr/lib/node_modules/openclaw/dist/reply-DRsqbakU.js
if (tokensAfter != null && tokensAfter > 0) {
    updates.totalTokens = tokensAfter;
    updates.totalTokensFresh = true;
    updates.inputTokens = void 0;    // ← 重置！
    updates.outputTokens = void 0;   // ← 重置！
}
```

当上下文压缩（compaction）发生时，OpenClaw 会重置 input/output token，只保留 total。

## 解决方案

我们自己记录，不依赖 OpenClaw 的统计。

### 数据存储

```
~/.openclaw/token-tracker/
├── token-log.jsonl      # 每次调用的详细记录
├── token-summary.json   # 累计统计
└── report.json          # 生成的报告
```

### 统计维度

1. **总计（全部时间）**
   - 总输入 token
   - 总输出 token
   - 总调用次数

2. **按模型统计**
   - kimi-k2p5
   - gpt-4
   - claude-3 等

3. **按天统计**
   - 每日输入/输出/调用次数

## 安装

### 方法 1：从快照恢复（推荐）

```bash
# 克隆快照
git clone -b kimiclaw https://github.com/polegithub/shadowclaw.git /tmp/shadowclaw

# 复制 token-tracker
cp -r /tmp/shadowclaw/skills/snapshot-sync/token-tracker* ~/.openclaw/workspace/skills/snapshot-sync/

# 恢复历史数据（如果有）
~/.openclaw/workspace/skills/snapshot-sync/token-tracker-wrapper.sh import /tmp/shadowclaw
```

### 方法 2：手动安装

```bash
cd ~/.openclaw/workspace/skills/snapshot-sync

# 创建 token-tracker.js（复制本文档中的代码）
# 创建 token-tracker-wrapper.sh（复制本文档中的代码）

chmod +x token-tracker-wrapper.sh
```

## 使用方法

### 1. 手动记录一次调用

```bash
# 记录 1000 输入, 500 输出, kimi-k2p5 模型
~/.openclaw/workspace/skills/snapshot-sync/token-tracker-wrapper.sh record 1000 500 kimi-k2p5 kimi-coding
```

### 2. 查看当前统计

```bash
~/.openclaw/workspace/skills/snapshot-sync/token-tracker-wrapper.sh stats
```

输出示例：
```
📊 Token 消耗统计 (最近 24 小时)
=====================================
输入 Tokens:  45,230
输出 Tokens:  12,456
总计 Tokens:  57,686
API 调用次数: 23
=====================================

📈 累计消耗 (全部时间)
输入:  1,234,567
输出:  456,789
总计:  1,691,356
调用: 567
```

### 3. 生成详细报告

```bash
# 最近 7 天
node ~/.openclaw/workspace/skills/snapshot-sync/token-tracker.js report 7

# 最近 30 天
node ~/.openclaw/workspace/skills/snapshot-sync/token-tracker.js report 30
```

### 4. 导出到快照（用于备份）

```bash
# 在生成快照时自动调用
~/.openclaw/workspace/skills/snapshot-sync/token-tracker-wrapper.sh export ~/.openclaw/snapshots/latest
```

### 5. 从快照恢复

```bash
# 恢复历史数据
~/.openclaw/workspace/skills/snapshot-sync/token-tracker-wrapper.sh import /path/to/snapshot
```

## 与快照系统集成

`snapshot-sync.js` 已集成 token-tracker：

```javascript
// 生成快照时自动导出 token 数据
await exportForSnapshot(snapshotPath);

// 恢复时自动导入
await importFromSnapshot(snapshotPath);
```

数据会备份到：
```
snapshot/
├── token-tracker/
│   ├── token-log.jsonl
│   ├── token-summary.json
│   └── report.json
```

## 自动化建议

### 方案 1：Heartbeat 定时记录

在 `HEARTBEAT.md` 中添加：
```markdown
## Token 统计检查
- [ ] 每小时记录一次当前 session 的 token 消耗
  ```bash
  ~/.openclaw/workspace/skills/snapshot-sync/token-tracker-wrapper.sh check
  ```
```

### 方案 2：Cron 定时任务

```bash
# 每小时检查一次
0 * * * * ~/.openclaw/workspace/skills/snapshot-sync/token-tracker-wrapper.sh check

# 每天生成报告
0 9 * * * ~/.openclaw/workspace/skills/snapshot-sync/token-tracker-wrapper.sh stats
```

### 方案 3：包装 OpenClaw 命令

创建别名：
```bash
alias openclaw='~/.openclaw/workspace/skills/snapshot-sync/token-tracker-wrapper.sh check; openclaw'
```

## 数据结构

### 单条记录（token-log.jsonl）

```json
{
  "timestamp": "2026-03-06T01:30:00.000Z",
  "inputTokens": 1000,
  "outputTokens": 500,
  "totalTokens": 1500,
  "model": "kimi-k2p5",
  "provider": "kimi-coding",
  "sessionKey": "agent:main:main"
}
```

### 汇总数据（token-summary.json）

```json
{
  "totalInput": 1234567,
  "totalOutput": 456789,
  "totalTokens": 1691356,
  "callCount": 567,
  "firstCall": "2026-03-01T00:00:00.000Z",
  "lastCall": "2026-03-06T01:30:00.000Z",
  "byModel": {
    "kimi-k2p5": {
      "input": 1000000,
      "output": 400000,
      "total": 1400000,
      "calls": 500
    }
  },
  "byDay": {
    "2026-03-06": {
      "input": 45230,
      "output": 12456,
      "total": 57686,
      "calls": 23
    }
  }
}
```

## 故障排除

**问题：统计数据为 0**
- 确认已运行 `record` 命令记录数据
- 检查 `~/.openclaw/token-tracker/` 目录是否存在

**问题：导入失败**
- 确认快照目录包含 `token-tracker/` 子目录
- 检查文件权限

**问题：统计不准确**
- 这是正常的，因为我们只记录手动/自动捕获的数据
- 要 100% 准确需要拦截所有 API 调用（需要修改 OpenClaw 源码）

## 未来改进

1. **自动拦截**：修改 OpenClaw Gateway，在每次 API 调用后自动记录
2. **实时推送**：WebSocket 实时推送 token 消耗到前端
3. **成本估算**：根据模型价格自动计算消耗金额
4. **告警**：设置每日/每周 token 上限，超限时通知

## License

MIT