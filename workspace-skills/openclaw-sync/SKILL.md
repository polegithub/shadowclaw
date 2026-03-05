---
name: openclaw-sync
description: OpenClaw 智能快照同步系统。支持快照生成、智能同步、自动过滤大文件、版本管理。让新的 OpenClaw 可以自动知道如何同步和恢复。
version: 2.0.0
author: Custom Skill
triggers:
  - "sync"
  - "同步"
  - "snapshot"
  - "快照"
metadata:
  {
    "openclaw":
      {
        "requires": { "bins": ["tar", "gzip", "jq", "git"] },
      },
  }
---

# OpenClaw Sync Skill

## 概述

智能快照同步系统，支持：
- ✅ 智能快照生成（自动过滤大文件）
- ✅ 与 OpenClaw 目录结构一致
- ✅ Git 版本管理和同步
- ✅ 大文件自动检测和跳过
- ✅ 快照元数据记录
- ✅ 一键恢复和合并

## 设计原则

1. **目录结构一致** - 快照直接按 `~/.openclaw/` 结构组织
2. **Git 友好** - 使用 Git 做版本管理和同步
3. **智能过滤** - 自动跳过大文件和可重新安装的内容
4. **元数据完整** - 记录快照的所有信息
5. **易于恢复** - 新 OpenClaw 可以直接 clone 并使用

## 快速开始

### 创建快照

```bash
cd ~/.openclaw/workspace/skills/openclaw-sync
./scripts/sync.sh snapshot
```

### 同步到 GitHub

```bash
./scripts/sync.sh push
```

### 从 GitHub 恢复

```bash
# 在新机器上
git clone <repo_url> ~/.openclaw-sync
cd ~/.openclaw-sync
./scripts/sync.sh restore
```

---

## 目录结构

```
~/.openclaw/              # 实际 OpenClaw 目录
├── config/               # ✅ 备份
├── agents/               # ✅ 备份
├── workspace/
│   └── skills/           # ✅ 备份
└── extensions/           # ❌ 跳过（可重新安装）

~/.openclaw-sync/         # 快照 Git 仓库
├── .git/                 # Git 版本控制
├── snapshot.json         # 快照元数据
├── README.md             # 说明文档
├── config/               # 对应 ~/.openclaw/config
├── agents/               # 对应 ~/.openclaw/agents
└── workspace-skills/     # 对应 ~/.openclaw/workspace/skills
```
