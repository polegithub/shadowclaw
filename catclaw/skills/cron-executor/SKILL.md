---
name: cron-executor
description: OpenClaw Cron 任务健壮执行器。提供服务过载保护、指数退避重试、防重入机制和失败通知。
version: 1.0.0
author: Kimi Claw
license: MIT
---

# Cron Executor - Cron 任务健壮执行器

## 问题背景

用户反馈的两个问题：

1. **9点新闻未发送** - AI 服务过载时任务失败，没有有效重试和通知
2. **重复回复4次** - 可能是消息重复投递或重试风暴导致

## 解决方案

本 Skill 提供健壮的 cron 任务执行框架。

## 核心功能

### 1. 防重入保护

防止同一任务并发执行：

```bash
# 在 cron 任务脚本开头调用
source ~/.openclaw/workspace/skills/cron-executor/bin/cron-helper.sh

cron_guard "daily-news" || exit 0
```

### 2. 指数退避重试

当 AI 服务过载时自动退避：

```bash
# 包装 AI 调用
with_backoff --max-retries 3 --base-delay 30 \
    kimi_search "OpenClaw news"
```

退避策略：
- 第1次重试：等待 30 秒
- 第2次重试：等待 60 秒  
- 第3次重试：等待 120 秒
- 超过最大重试：标记失败，发送通知

### 3. 失败通知

任务失败时立即通知用户：

```bash
# 在脚本末尾调用
if [ $SUCCESS -eq 0 ]; then
    notify_user "❌ 每日新闻收集失败" \
        "AI 服务持续过载，将在下次定时重试。\n\n错误详情：$ERROR_MSG"
fi
```

### 4. 优雅降级

当主服务不可用时，使用备用方案：

```bash
# 尝试主服务
if ! primary_search; then
    log_warn "主服务失败，使用备用方案"
    fallback_search
fi
```

## 使用示例

### 改造前的每日新闻任务

```json
{
  "payload": {
    "message": "搜索 OpenClaw 新闻...",
    "timeoutSeconds": 300
  }
}
```

### 改造后的每日新闻任务

```json
{
  "payload": {
    "message": "执行 OpenClaw 每日新闻收集任务（使用 cron-executor 保护）。\n\n执行流程：\n1. 检查防重入锁\n2. 尝试搜索新闻（最多3次，指数退避）\n3. 成功：发送新闻给用户\n4. 失败：发送失败通知，记录状态\n\n具体脚本见 skills/cron-executor/scripts/daily-news.sh"
  }
}
```

## 集成方法

### 方法1：修改现有 cron 任务

1. 在 payload 中调用 cron-executor 包装
2. 使用提供的 helper 函数

### 方法2：替换为 executor 脚本

```bash
# cron 配置改为调用脚本
{
  "payload": {
    "message": "执行 ~/.openclaw/workspace/skills/cron-executor/scripts/daily-news-wrapper.sh"
  }
}
```

## 关键改进点

| 问题 | 改进前 | 改进后 |
|------|--------|--------|
| 服务过载 | 连续重试导致429 | 指数退避，合理等待 |
| 并发执行 | 无保护，可能重复 | 文件锁防重入 |
| 失败通知 | 静默失败 | 立即通知用户 |
| 状态跟踪 | 无法知道上次状态 | 持久化状态记录 |

## 状态持久化

```
~/.openclaw/cron-executor/
├── locks/              # 锁文件
│   └── {job_name}.lock
├── status/             # 执行状态
│   └── {job_name}.json
└── logs/               # 执行日志
    └── {job_name}-{date}.log
```

## 状态文件格式

```json
{
  "job_name": "daily-news",
  "last_run": "2026-03-06T09:00:00Z",
  "last_status": "failed",
  "fail_count": 2,
  "last_error": "rate_limit_exceeded",
  "next_retry": "2026-03-06T09:05:00Z"
}
```

## 监控命令

```bash
# 查看所有 cron 任务状态
cron-executor status

# 查看特定任务详情
cron-executor status --job daily-news

# 重置任务状态
cron-executor reset --job daily-news

# 强制解锁
cron-executor unlock --job daily-news
```

## 最佳实践

1. **所有 cron 任务都使用 executor 包装**
2. **设置合理的超时时间**（考虑退避延迟）
3. **失败时总是通知用户**
4. **定期查看状态统计**

## 相关 Skill

- `message-deduplication` - 消息去重
- `snapshot-sync` - 环境快照

## 更新日志

### v1.0.0 (2026-03-06)
- 初始版本，防重入保护
- 指数退避重试
- 失败通知机制
