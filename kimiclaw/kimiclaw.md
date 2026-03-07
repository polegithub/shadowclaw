# KimiClaw 快照方案 v3.0

> 基于 `~/.openclaw/` 标准状态目录的快照管理规范

---

## 目录结构

```
~/.openclaw/                                  ← 根目录 (STATE_DIR)
│
├── openclaw.json                             ⭐⭐⭐ 必备 — 主配置文件（渠道、模型、Agent、Hook）
│
├── agents/
│   └── main/
│       ├── agent/
│       │   ├── auth-profiles.json            ⭐⭐⭐ 必备 — 所有 API Key（OpenAI/Anthropic/etc）
│       │   └── models.json                   ⭐⭐  重要 — 模型配置（可重新生成，但备份省时）
│       └── sessions/
│           ├── sessions.json                 ⭐⭐⭐ 必备 — 会话索引（记录所有对话的元信息）
│           └── *.jsonl                       ⭐⭐  重要 — 对话 transcript（对话历史本身）
│
├── credentials/
│   ├── oauth.json                            ⭐⭐⭐ 必备 — Web/OAuth token
│   └── whatsapp/
│       └── default/
│           ├── creds.json                    ⭐⭐⭐ 必备 — WhatsApp Web 登录态（扫码后）
│           └── creds.json.bak                ⭐    可选 — 自动备份
│
├── memory/
│   ├── MEMORY.md                             ⭐⭐⭐ 必备 — 长期记忆主文件
│   ├── YYYY-MM-DD.md                         ⭐⭐  重要 — 每日记忆日志
│   └── lancedb/                              ⭐⭐⭐ 必备 — 向量记忆数据库（如启用了 memory-lancedb 插件）
│
├── workspace/                                ⭐⭐⭐ 必备 — 工作区文件
│   ├── AGENTS.md
│   ├── SOUL.md
│   ├── USER.md
│   ├── TOOLS.md
│   ├── IDENTITY.md
│   ├── BOOTSTRAP.md
│   ├── HEARTBEAT.md
│   └── skills/                               ⭐⭐⭐ 必备 — 自定义 Skills
│       └── [skill-name]/
│           ├── SKILL.md
│           └── ...
│
├── cron/                                     ⭐⭐  重要 — 定时任务配置
│   ├── jobs.json
│   └── runs/
│
├── plugins/                                  ⭐    可选 — 插件配置
│
├── canvas/                                   ⭐    可选 — Canvas 相关文件
│
└── snapshots/                                ⭐    可选 — 本地快照存储
```

---

## 优先级说明

| 优先级 | 标记 | 说明 |
|--------|------|------|
| ⭐⭐⭐ 必备 | 快照必须包含 | 丢失后无法恢复或恢复成本极高 |
| ⭐⭐ 重要 | 建议包含 | 丢失后可重建但耗时 |
| ⭐ 可选 | 按需包含 | 有自动重建机制或体积过大 |

---

## 敏感数据处理

### 脱敏字段列表

以下字段在快照中会被替换为 `{{SECRET:field_name}}` 占位符：

```json
{
  "sensitive_patterns": [
    "api_key",
    "apikey", 
    "api-key",
    "token",
    "secret",
    "password",
    "private_key",
    "client_secret",
    "access_token",
    "refresh_token",
    "openai_api_key",
    "anthropic_api_key",
    "kimi_api_key",
    "feishu_app_secret",
    "github_token",
    "whatsapp_session"
  ]
}
```

### 恢复时手动填入

恢复后需要根据 `secrets-template.json` 手动填入真实凭证。

---

## 文件大小限制

```json
{
  "max_file_size_mb": 10,
  "exclude_patterns": [
    "*.log",
    "node_modules/**",
    ".git/**",
    "__pycache__/**",
    "*.tmp",
    "*.cache",
    "*.bin",
    "*.exe",
    "*.dll",
    "*.so"
  ],
  "exclude_large_extensions": [".bin", ".exe", ".dll", ".so", ".pth", ".ckpt", ".safetensors"]
}
```

---

## 快照生成流程

```bash
# 1. 生成快照
snapshot-sync generate

# 2. 推送到远程
snapshot-sync push --repo github.com/polegithub/shadowclaw --branch main

# 3. 自动创建 PR 或提交（可选）
snapshot-sync push --auto-commit
```

---

## 快照恢复流程

```bash
# 1. 拉取快照
snapshot-sync pull --repo github.com/polegithub/shadowclaw --branch main

# 2. 恢复环境
snapshot-sync restore

# 3. 填入凭证
# 编辑 ~/.openclaw/agents/main/agent/auth-profiles.json
# 编辑 ~/.openclaw/credentials/oauth.json

# 4. 重启服务
openclaw gateway restart
```

---

## manifest.json 格式

```json
{
  "version": "3.0.0",
  "name": "kimiclaw",
  "generated_at": "2026-03-06T10:56:00+08:00",
  "generated_by": "ou_196dc9353a11da18b0cec3c11213f173",
  "openclaw_version": "1.2.3",
  "state_dir_structure": {
    "openclaw.json": "present",
    "agents/main/agent/auth-profiles.json": "present",
    "agents/main/sessions/sessions.json": "present",
    "credentials/oauth.json": "desensitized",
    "memory/lancedb/": "excluded"
  },
  "stats": {
    "total_files": 42,
    "total_size_mb": 3.2,
    "desensitized_files": 3,
    "excluded_large_files": [
      {
        "path": "memory/lancedb/index.bin",
        "size_mb": 45,
        "reason": "exceeds_max_size"
      }
    ]
  },
  "checksums": {
    "openclaw.json": "sha256:abc123...",
    "agents/main/agent/auth-profiles.json": "sha256:def456...",
    "memory/MEMORY.md": "sha256:ghi789..."
  }
}
```

---

## 自动化建议

### 每日自动备份

```bash
# 设置定时任务
cron add --name "daily-kimiclaw-backup" --schedule "0 2 * * *" \
  --command "snapshot-sync generate && snapshot-sync push --silent"
```

### 重要变更触发备份

```bash
# 监听文件变化
watchman watch ~/.openclaw/
watchman trigger ~/.openclaw/ kimiclaw-backup 'openclaw.json' -- \
  snapshot-sync generate --incremental
```

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v3.0 | 2026-03-06 | 重构为基于 STATE_DIR 的标准目录结构 |
| v2.0 | 2026-03-05 | 新增自举模式，优化快照格式 |
| v1.0 | 2026-03-01 | 初始版本 |

---

*KimiClaw - 记住一切，随时恢复*
