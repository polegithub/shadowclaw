# CatClaw — OpenClaw Snapshot & Restore

> 让一个全新的 OpenClaw 实例在几分钟内恢复到上一次的完整状态，就像 Mac 的 Time Machine。

## 设计理念

1. **一个脚本搞定一切** — `bin/shadowclaw` 是唯一入口，snapshot / restore / push 三合一
2. **配置驱动** — `config/paths.json` 定义备份范围和优先级，改配置不改代码
3. **安全第一** — 自动脱敏敏感字段，推送前检查泄漏，恢复前自动备份
4. **幂等恢复** — 多次恢复不会破坏状态，缺失文件跳过而非报错

## 快速使用

```bash
# 生成快照
./bin/shadowclaw snapshot

# 增量快照（仅备份变更文件）
./bin/shadowclaw snapshot --incremental

# 生成快照到指定目录
./bin/shadowclaw snapshot -o /tmp/my-snapshot

# 模拟运行（不实际操作）
./bin/shadowclaw snapshot --dry-run

# 恢复环境
./bin/shadowclaw restore /path/to/snapshot

# 强制恢复（跳过确认）
./bin/shadowclaw restore --force /path/to/snapshot

# 推送到 GitHub
./bin/shadowclaw push

# 推送到指定仓库
./bin/shadowclaw push -r github.com/user/repo -b main

# 配置定时自动快照（每6小时）
./bin/shadowclaw cron --interval 6h

# 移除定时快照
./bin/shadowclaw cron --remove

# 对比快照与当前环境差异
./bin/shadowclaw diff /path/to/snapshot
```

## 目录结构

```
catclaw/
├── bin/
│   └── shadowclaw          # 主入口脚本（snapshot/restore/push/cron/diff）
├── config/
│   └── paths.json          # 备份路径 & 优先级配置
├── docs/
│   └── design.md           # 方案设计文档 & 三方对比
├── skills/                  # 附属 skills（排查工具等）
└── README.md               # 本文件
```

## 它恢复什么？

| 优先级 | 内容 | 丢了会怎样 |
|--------|------|-----------|
| 🔴 必备 | 主配置、API Key、凭证、记忆库、workspace 核心文件 | 无法运行或完全失忆 |
| 🟡 重要 | 模型配置、对话历史、定时任务、Skills、设备身份 | 能运行但功能不全 |
| 🟢 可选 | 环境变量、心跳配置、任务数据 | 可重建 |
| ⚫ 跳过 | extensions/、node_modules/、logs/、缓存 | 自动重建 |

完整路径列表见 `config/paths.json`。

## 从其他方案继承了什么？

| 来自 | 继承内容 |
|------|---------|
| **KimiClaw** | CLI 入口设计、脱敏机制 (`{{SECRET:xxx}}`)、manifest 追踪、安全检查 |
| **HuoshanClaw** | 完整目录覆盖（identity/、.env、memory/main.sqlite、workspace/memory/、feishu 配对） |

## 环境变量

```bash
GITHUB_TOKEN=ghp_xxx   # 或 GH_TOKEN，推送到 GitHub 需要
OPENCLAW_DIR=~/.openclaw   # 覆盖默认 state 目录（可选）
```

## License

MIT
