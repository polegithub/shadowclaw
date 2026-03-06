# snapshot-sync

OpenClaw 快照管理与同步 Skill。自动生成快照、同步配置、恢复环境。

## 功能

- 📸 **自动生成快照**：打包配置、skills、记忆、文件
- 🔄 **同步快照**：从 GitHub 恢复环境
- 📊 **文件大小检查**：自动排除大文件
- 🔒 **敏感信息处理**：自动脱敏

## 安装

```bash
clawhub install snapshot-sync
```

## 使用

### 生成快照

```bash
# 生成当前环境快照
openclaw skills run snapshot-sync generate

# 推送到 GitHub
openclaw skills run snapshot-sync push --repo polegithub/shadowclaw --branch kimiclaw
```

### 同步快照

```bash
# 从 GitHub 恢复快照
openclaw skills run snapshot-sync pull --repo polegithub/shadowclaw --branch kimiclaw

# 自动恢复环境
openclaw skills run snapshot-sync restore
```

## 配置

在 `~/.openclaw/openclaw.json` 中添加：

```json
{
  "skills": {
    "snapshot-sync": {
      "github_repo": "polegithub/shadowclaw",
      "github_branch": "kimiclaw",
      "github_token": "ghp_xxxxxxxx",
      "max_file_size_mb": 10,
      "exclude_patterns": ["node_modules", ".git", "*.log", "*.tmp"]
    }
  }
}
```

## 快照内容

| 类型 | 路径 | 说明 |
|------|------|------|
| 配置 | `~/.openclaw/openclaw.json` | 主配置（脱敏） |
| Skills | `~/.openclaw/workspace/skills/` | 所有技能 |
| 记忆 | `~/.openclaw/workspace/memory/` | 对话记忆 |
| 文档 | `~/.openclaw/workspace/*.md` | SOUL, AGENTS, USER 等 |
| 扩展 | `~/.openclaw/extensions/` | 扩展插件 |

## License

MIT