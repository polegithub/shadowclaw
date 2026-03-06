---
name: snapshot-sync
description: OpenClaw 快照管理与同步 Skill。自动生成快照、同步配置、恢复环境。
version: 1.0.0
author: Kimi Claw
license: MIT
---

# 快照管理 Skill

## 概述

本 Skill 用于管理 OpenClaw 环境的完整快照，包括：
- 配置信息（自动脱敏）
- 已安装的 Skills
- 记忆文件
- 工作区文档
- 扩展插件

## 使用场景

**场景 1：新机器恢复**
用户：在新机器上恢复我的 OpenClaw 环境
→ 执行：snapshot-sync pull + restore

**场景 2：定期备份**
用户：备份当前环境到 GitHub
→ 执行：snapshot-sync generate + push

**场景 3：同步更新**
用户：同步最新的配置变更
→ 执行：snapshot-sync sync

## 指令

### 生成快照

当用户要求生成快照时：
1. 检查 `~/.openclaw/workspace/` 目录结构
2. 收集所有配置文件
3. 检查文件大小，排除超过限制的文件
4. 脱敏处理（移除 API keys, secrets）
5. 生成 `snapshot-manifest.json`
6. 打包为快照格式

**触发词：**
- "生成快照"
- "备份当前环境"
- "snapshot generate"

### 推送快照

当用户要求推送快照到 GitHub 时：
1. 检查是否已生成快照
2. 读取配置中的 github_repo 和 github_token
3. 创建或切换到指定分支
4. 上传所有快照文件
5. 返回 GitHub 链接

**触发词：**
- "推送快照"
- "上传备份"
- "snapshot push"

### 拉取快照

当用户要求从 GitHub 恢复快照时：
1. 克隆指定仓库和分支
2. 验证快照完整性
3. 显示即将恢复的内容列表
4. 等待用户确认

**触发词：**
- "拉取快照"
- "同步备份"
- "snapshot pull"

### 恢复环境

当用户要求恢复环境时：
1. 检查快照目录结构
2. 备份当前配置（防止覆盖）
3. 复制配置文件到正确位置
4. 安装缺失的 skills
5. 重启 gateway 应用变更

**触发词：**
- "恢复快照"
- "应用备份"
- "snapshot restore"

## 文件大小限制

默认排除超过 10MB 的文件：
- 大型模型文件
- 日志文件
- 缓存文件
- 二进制依赖

## 敏感信息脱敏

自动移除或替换：
- API Keys（替换为占位符）
- App Secrets（替换为占位符）
- 访问令牌（替换为占位符）
- 个人身份信息（PII）

## 快照结构

```
snapshot/
├── manifest.json          # 快照元数据
├── config/
│   ├── openclaw.json      # 主配置（脱敏）
│   └── secrets-template.json  # 敏感信息模板
├── skills/
│   ├── skill-list.json    # 技能清单
│   └── [skill-name]/      # 各技能目录
├── memory/
│   └── [date].md          # 记忆文件
├── workspace/
│   ├── AGENTS.md
│   ├── SOUL.md
│   ├── USER.md
│   ├── TOOLS.md
│   └── ...
├── extensions/
│   └── extension-list.json
└── restore.sh             # 恢复脚本
```

## 最佳实践

1. **定期备份**：建议每天自动生成快照
2. **分支管理**：不同环境使用不同分支（dev/prod）
3. **敏感信息**：恢复后手动填入真实凭证
4. **大文件排除**：使用配置调整大小限制

## 故障排除

**问题：推送失败**
- 检查 GitHub Token 是否有 repo 权限
- 确认仓库地址正确

**问题：恢复后无法启动**
- 检查 secrets 是否已正确填入
- 查看 gateway 日志：openclaw logs --follow

**问题：文件过大**
- 调整 max_file_size_mb 配置
- 手动排除特定文件