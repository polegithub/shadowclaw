---
name: token-tracker
description: Token 累计统计和追踪工具。记录每次调用的 token 使用量，提供累计统计、历史趋势、按会话/技能分类统计等功能。
version: 1.0.0
author: Custom Skill
triggers:
  - "token"
  - "tokens"
  - "统计"
  - "usage"
metadata:
  {
    "openclaw":
      {
        "requires": { "bins": ["jq"] },
      },
  }
---

# Token Tracker Skill

## 概述

解决 OpenClaw 不显示累计输出 token 的问题。

## 功能

- ✅ 记录每次调用的 token 使用量
- ✅ 累计输入/输出 token 统计
- ✅ 按会话分类统计
- ✅ 按日期/时间趋势
- ✅ 可视化报告

## 快速开始

### 查看累计统计

```bash
cd ~/.openclaw/workspace/skills/token-tracker
./scripts/tracker.sh stats
```

### 记录当前状态（基准线）

```bash
./scripts/tracker.sh record
```

### 查看历史趋势

```bash
./scripts/tracker.sh history
```

---

## 数据存储

```
~/.openclaw/token-stats/
├── current.json          # 当前状态
├── history.jsonl         # 历史记录
└── sessions/             # 按会话统计
    ├── main.json
    └── ...
```
