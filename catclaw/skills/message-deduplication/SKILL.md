---
name: message-deduplication
description: OpenClaw 消息去重与重试控制 Skill。防止重复消息处理和重试风暴，确保消息只被处理一次。
version: 1.0.0
author: Kimi Claw
license: MIT
---

# Message Deduplication - 消息去重与重试控制

## 问题背景

在 OpenClaw 运行中经常遇到两类问题：

1. **消息重复投递** - 由于网络抖动或 IM 平台重试，同一条消息被发送多次
2. **重试风暴** - 当 AI 服务过载时，系统连续重试导致消息重复回复

## 解决方案

本 Skill 提供消息指纹去重和智能重试控制机制。

## 核心功能

### 1. 消息指纹去重

为每条消息生成唯一指纹，相同指纹的消息只处理一次。

```bash
# 检查消息是否已处理
message-dedup check --content "消息内容" --sender "user_id"

# 标记消息已处理
message-dedup mark --content "消息内容" --sender "user_id"
```

### 2. 重试冷却控制

防止短时间内对同一问题的重复回复。

```bash
# 设置回复冷却期（默认60秒）
message-dedup cooldown --topic "topic_name" --seconds 60

# 检查是否在冷却期内
message-dedup is-cooldown --topic "topic_name"
```

### 3. Cron 任务状态保护

防止 cron 任务在服务过载时的重试风暴。

```bash
# 标记 cron 任务开始
message-dedup cron-start --job "job_name"

# 标记 cron 任务完成（成功或失败）
message-dedup cron-end --job "job_name" --status success|failed

# 检查 cron 任务是否已在运行
message-dedup cron-check --job "job_name"
```

## 使用场景

### 场景1：防止消息重复处理

在 agent 处理消息前调用：

```bash
#!/bin/bash
MESSAGE_CONTENT="$1"
SENDER_ID="$2"

# 检查是否已处理
if message-dedup check --content "$MESSAGE_CONTENT" --sender "$SENDER_ID"; then
    echo "消息已处理，跳过"
    exit 0
fi

# 处理消息
process_message "$MESSAGE_CONTENT"

# 标记已处理
message-dedup mark --content "$MESSAGE_CONTENT" --sender "$SENDER_ID"
```

### 场景2：Cron 任务防重入

```bash
#!/bin/bash
JOB_NAME="daily-news"

# 检查是否已在运行
if message-dedup cron-check --job "$JOB_NAME"; then
    echo "任务已在运行，跳过"
    exit 0
fi

# 标记开始
message-dedup cron-start --job "$JOB_NAME"

# 执行任务
if do_work; then
    message-dedup cron-end --job "$JOB_NAME" --status success
else
    message-dedup cron-end --job "$JOB_NAME" --status failed
    # 记录失败时间，用于指数退避
    message-dedup backoff --job "$JOB_NAME"
fi
```

### 场景3：AI 服务过载时的退避

```bash
#!/bin/bash
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if call_ai_service; then
        exit 0
    fi
    
    # 检查是否需要退避
    if message-dedup should-backoff --error "rate_limit"; then
        BACKOFF_SECONDS=$(message-dedup get-backoff --attempt $RETRY_COUNT)
        echo "AI 服务过载，退避 ${BACKOFF_SECONDS} 秒..."
        sleep $BACKOFF_SECONDS
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

echo "达到最大重试次数，放弃"
exit 1
```

## 实现原理

### 消息指纹生成

```python
import hashlib
import time

def generate_fingerprint(content, sender, timestamp_tolerance=60):
    """
    生成消息指纹
    - 内容哈希
    - 发送者ID
    - 时间戳取整（允许小范围时间差）
    """
    normalized_content = content.strip().lower()
    content_hash = hashlib.sha256(normalized_content.encode()).hexdigest()[:16]
    
    # 时间戳取整到分钟级别
    normalized_time = int(time.time() / timestamp_tolerance)
    
    fingerprint = f"{sender}:{content_hash}:{normalized_time}"
    return fingerprint
```

### 存储结构

```
~/.openclaw/dedup/
├── fingerprints.json     # 已处理消息指纹（LRU缓存，保留最近1000条）
├── cooldowns.json        # 主题冷却状态
├── cron-locks/           # Cron 任务锁文件
│   ├── job_name.lock
│   └── job_name.status
└── backoff.json          # 退避记录
```

### 指纹存储策略

- **内存缓存**：最近100条指纹，用于快速查重
- **磁盘持久化**：最近1000条指纹，重启后仍有效
- **自动清理**：24小时前的指纹自动清除

## 与 OpenClaw 集成

### 方案1：Gateway 层面拦截（推荐）

修改 gateway 配置，在处理消息前自动进行去重检查。

### 方案2：Agent 层面处理

在 agent 的 prompt 中添加指令：

```
在处理每条用户消息前：
1. 调用 message-dedup check 检查是否已处理
2. 如果已处理，回复 NO_REPLY
3. 如果未处理，正常回复并调用 message-dedup mark
```

### 方案3：Skill 自动拦截

本 skill 启动守护进程，监控消息流并自动去重。

## 配置文件

`~/.openclaw/message-dedup.json`:

```json
{
  "fingerprint": {
    "max_memory_cache": 100,
    "max_disk_cache": 1000,
    "ttl_seconds": 86400,
    "timestamp_tolerance": 60
  },
  "cooldown": {
    "default_seconds": 60,
    "topics": {
      "heartbeat_response": 30,
      "cron_failure_notice": 300
    }
  },
  "backoff": {
    "strategy": "exponential",
    "base_seconds": 10,
    "max_seconds": 300,
    "max_retries": 3
  },
  "cron": {
    "lock_timeout_seconds": 600,
    "cleanup_interval_seconds": 3600
  }
}
```

## 故障排查

### 消息被误判为重复

```bash
# 清除特定指纹
message-dedup clear --fingerprint "xxx"

# 清除所有缓存
message-dedup clear-all
```

### Cron 任务卡死

```bash
# 强制释放锁
message-dedup cron-force-unlock --job "job_name"
```

### 查看统计

```bash
# 查看缓存状态
message-dedup stats

# 查看活跃锁
message-dedup locks
```

## 最佳实践

1. **合理设置时间容差** - 根据消息类型调整 `timestamp_tolerance`
2. **区分敏感操作** - 对于重要操作（如发送邮件），使用更严格的去重
3. **监控重复率** - 定期检查 `message-dedup stats` 了解重复消息比例
4. **清理策略** - 设置合理的 TTL，防止缓存无限增长

## 相关 Skill

- `snapshot-sync` - 环境快照管理
- `cron-monitor` - Cron 任务监控

## 更新日志

### v1.0.0 (2026-03-06)
- 初始版本，消息指纹去重
- Cron 任务防重入
- 指数退避重试控制
