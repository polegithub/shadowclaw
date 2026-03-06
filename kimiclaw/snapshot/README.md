# Kimi Claw 快照备份

## 生成时间
$(date)

## 包含内容
- ✅ OpenClaw 配置（已脱敏）
- ✅ 已安装 Skills 列表
- ✅ 扩展插件列表
- ✅ Workspace 文件结构
- ✅ 记忆文件（MEMORY.md, SOUL.md, USER.md 等）
- ✅ 恢复脚本

## 快速恢复

```bash
cd ~/.openclaw/workspace
./snapshot/restore.sh
```

## 手动配置

恢复后需要填入以下敏感信息：
1. Kimi API Key
2. 飞书 App Secret
3. 其他 channel 的凭证

参考 `secrets-template.json`

## Channel 配置

- Feishu: 已配置，App ID: cli_a9225fcd57bb5cd3
- DingTalk: 已启用但未配置

## Skills

查看 `skills-list.txt` 了解已安装的技能

## 备注

此快照由 Kimi Claw 自动生成，用于系统恢复和迁移。
