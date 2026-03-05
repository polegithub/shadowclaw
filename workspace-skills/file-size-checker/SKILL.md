---
name: file-size-checker
description: 智能文件大小检测和过滤工具。在快照前自动扫描并标记大文件，提供报告和跳过建议。可配置大小阈值，支持白名单/黑名单。
version: 1.0.0
author: Custom Skill
triggers:
  - "大文件"
  - "large file"
  - "文件大小"
metadata:
  {
    "openclaw":
      {
        "requires": { "bins": ["du", "find"] },
      },
  }
---

# File Size Checker Skill

## 概述

智能文件大小检测工具，用于：
- 扫描目录并找出大文件
- 生成文件大小报告
- 在快照前提供跳过建议
- 可配置阈值和白名单

## 快速开始

### 扫描 OpenClaw 目录

```bash
cd ~/.openclaw/workspace/skills/file-size-checker
./scripts/check.sh scan ~/.openclaw
```

### 生成快照前检查报告

```bash
./scripts/check.sh pre-snapshot
```

### 使用自定义阈值

```bash
export MAX_SIZE_MB=100
./scripts/check.sh scan ~/.openclaw
```

---

## 配置

| 环境变量 | 默认值 | 说明 |
|---------|--------|------|
| `MAX_SIZE_MB` | 50 | 超过此大小的文件视为大文件 |
| `WHITELIST` | - | 白名单文件（即使大也备份） |
| `BLACKLIST` | - | 黑名单文件（即使小也跳过） |

---

## 输出格式

```
📊 文件大小报告
================

大文件（超过 50MB）:
1. extensions/qqbot/node_modules/xxx (1.2G) - 建议跳过
2. agents/main/sessions/large.jsonl (85MB) - 可选备份
3. logs/debug.log (120MB) - 建议跳过

可安全备份:
- config/ (1.2MB)
- agents/main/memory/ (890KB)
- workspace/skills/ (688KB)

建议:
- 跳过: 3 个文件 (1.4G)
- 备份: 其余所有 (2.8MB)
```
