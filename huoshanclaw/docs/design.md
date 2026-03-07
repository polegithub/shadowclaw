# HuoshanClaw 快照方案设计

## 核心思路
基于 OpenClaw `~/.openclaw` 目录的文件级快照，支持全量/增量备份、脱敏、压缩、加密、恢复。

## 命令列表
| 命令 | 说明 |
|------|------|
| backup | 全量/增量快照 |
| restore | 一键恢复（支持多格式） |
| verify | 校验完整性（SHA256） |
| diff | 对比快照差异 |
| cron | 定时备份 |

## 脱敏策略
- JSON 字段名匹配（30+ 敏感模式）
- 值 pattern 替换（ghp_, sk- 等）
- 占位符格式：`{{SECRET:field_name}}`

## 压缩与加密
- zstd level 19 压缩（回退到 gzip）
- AES-256-CBC 加密（可选）
