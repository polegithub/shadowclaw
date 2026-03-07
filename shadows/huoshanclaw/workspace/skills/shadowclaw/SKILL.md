---
name: shadowclaw
description: OpenClaw 环境快照与恢复。备份 ~/.openclaw 状态（配置、记忆、会话、credentials、skills），支持脱敏、增量备份、定时快照、GitHub 推送、恢复验证。当用户提到快照、备份、恢复 OpenClaw 环境、snapshot、backup、restore 时激活。
triggers:
  - "快照"
  - "备份"
  - "恢复"
  - "snapshot"
  - "backup"
  - "restore"
  - "shadowclaw"
metadata: {"clawdbot":{"emoji":"📸","requires":{"bins":["bash","jq","git"]}}}
---

# ShadowClaw — OpenClaw 快照与恢复

对 `~/.openclaw` 做文件级快照，支持脱敏、增量、定时、推送、恢复。

## 命令

```bash
# 完整快照
bash {baseDir}/scripts/shadowclaw.sh snapshot -o /path/to/output

# 增量快照（仅变更文件）
bash {baseDir}/scripts/shadowclaw.sh snapshot --incremental -o /path/to/output

# 恢复
bash {baseDir}/scripts/shadowclaw.sh restore --force /path/to/snapshot

# 验证快照完整性
bash {baseDir}/scripts/shadowclaw.sh verify /path/to/snapshot

# 对比快照与当前状态
bash {baseDir}/scripts/shadowclaw.sh diff /path/to/snapshot

# 推送到 GitHub
bash {baseDir}/scripts/shadowclaw.sh push -r github.com/user/repo -b main

# 定时快照
bash {baseDir}/scripts/shadowclaw.sh cron --interval 6h

# 自测
bash {baseDir}/scripts/shadowclaw.sh test
```

## 配置

默认配置在 `{baseDir}/config/default.json`。可通过环境变量 `SHADOWCLAW_CONFIG` 指定自定义配置路径。

## 环境变量

| 变量 | 说明 |
|------|------|
| `OPENCLAW_DIR` | 覆盖默认 state 目录（默认 `~/.openclaw`） |
| `SHADOWCLAW_CONFIG` | 覆盖默认配置文件路径 |
| `GH_TOKEN` / `GITHUB_TOKEN` | GitHub 推送令牌 |

## 脱敏

快照自动脱敏：JSON 字段名匹配（28+ 模式）、值 pattern 替换（ghp_, sk-, xoxb- 等）、session jsonl 深度扫描、推送前安全扫描。占位符格式：`{{SECRET:field_name}}`。
