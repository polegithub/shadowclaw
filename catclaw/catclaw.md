# CatClaw 快照方案 v1.0

> 基于 KimiClaw v3.0 架构，融合 HuoshanClaw 目录覆盖范围的快照管理方案

---

## 设计原则

1. **可执行优先** — 有实际可运行的脚本，不是纯文档
2. **敏感数据脱敏** — 推送到 Git 前自动清除密钥
3. **恢复前自动备份** — 防止误操作覆盖
4. **manifest 追踪** — 每次快照生成校验和与统计
5. **完整覆盖** — 综合 kimiclaw + huoshanclaw 的目录范围

---

## 目录结构

```
~/.openclaw/                                  ← 根目录 (STATE_DIR)
│
├── openclaw.json                             ⭐⭐⭐ 必备 — 主配置文件
│
├── agents/
│   └── main/
│       ├── agent/
│       │   ├── auth-profiles.json            ⭐⭐⭐ 必备 — 所有 API Key
│       │   └── models.json                   ⭐⭐  重要 — 模型配置
│       └── sessions/
│           ├── sessions.json                 ⭐⭐⭐ 必备 — 会话索引
│           └── *.jsonl                       ⭐⭐  重要 — 对话历史
│
├── credentials/
│   ├── oauth.json                            ⭐⭐⭐ 必备 — OAuth token
│   ├── feishu-pairing.json                   ⭐⭐  重要 — 飞书配对（如有）
│   └── whatsapp/
│       └── default/
│           └── creds.json                    ⭐⭐⭐ 必备 — WhatsApp 登录态
│
├── identity/
│   └── device.json                           ⭐⭐  重要 — 设备身份（来自 huoshanclaw）
│
├── memory/
│   ├── main.sqlite                           ⭐⭐⭐ 必备 — SQLite 记忆库（来自 huoshanclaw）
│   └── lancedb/                              ⭐⭐⭐ 必备 — 向量记忆库
│
├── workspace/                                ⭐⭐⭐ 必备 — 工作区
│   ├── AGENTS.md
│   ├── SOUL.md
│   ├── USER.md
│   ├── IDENTITY.md
│   ├── TOOLS.md
│   ├── HEARTBEAT.md                          ⭐⭐  重要 — 心跳清单（来自 huoshanclaw）
│   ├── MEMORY.md                             ⭐⭐⭐ 必备 — 长期记忆
│   ├── memory/                               ⭐⭐⭐ 必备 — 每日记忆日志
│   │   └── YYYY-MM-DD.md
│   ├── skills/                               ⭐⭐  重要 — 自定义 Skills
│   └── tasks.json                            ⭐⭐  重要 — 任务数据（来自 huoshanclaw）
│
├── cron/
│   └── jobs.json                             ⭐⭐  重要 — 定时任务
│
├── .env                                      ⭐⭐  重要 — 环境变量（来自 huoshanclaw）
│
└── extensions/                               ❌ 跳过 — 可重新安装
    └── node_modules/                         ❌ 跳过
```

---

## 优先级说明

| 优先级 | 标记 | 说明 |
|--------|------|------|
| ⭐⭐⭐ 必备 | 快照必须包含 | 丢失后无法恢复或恢复成本极高 |
| ⭐⭐ 重要 | 建议包含 | 丢失后可重建但耗时 |
| ⭐ 可选 | 按需包含 | 有自动重建机制或体积过大 |
| ❌ 跳过 | 不包含 | extensions/node_modules/logs 等 |

---

## 与 KimiClaw / HuoshanClaw 的差异

| 特性 | KimiClaw | HuoshanClaw | CatClaw |
|:---|:---:|:---:|:---:|
| 可执行脚本 | ✅ | ❌ | ✅ 基于 kimiclaw |
| 敏感数据脱敏 | ✅ sed 替换 | ❌ 仅文档 | ✅ 增强版 |
| manifest 校验 | ✅ | ❌ | ✅ |
| 恢复前备份 | ✅ | ❌ | ✅ |
| identity/ 覆盖 | ❌ | ✅ | ✅ |
| .env 覆盖 | ❌ | ✅ | ✅ |
| main.sqlite 覆盖 | ❌ | ✅ | ✅ |
| workspace/memory/ | ❌ | ✅ | ✅ |
| HEARTBEAT.md | ❌ | ✅ | ✅ |
| tasks.json | ❌ | ✅ | ✅ |
| cron-executor | ✅ | ❌ | ✅ |
| message-dedup | ✅ | ❌ | ✅ |
| Git 推送 | ✅ | 文档描述 | ✅ |

---

## 敏感数据处理

脱敏字段列表（继承自 kimiclaw + 扩展）：

```json
{
  "sensitive_patterns": [
    "api_key", "apikey", "api-key",
    "token", "secret", "password",
    "private_key", "client_secret",
    "access_token", "refresh_token",
    "appSecret", "appId",
    "github_token", "whatsapp_session"
  ]
}
```

---

## 文件大小限制

```json
{
  "max_file_size_mb": 10,
  "always_backup": [
    "openclaw.json",
    "agents/*/agent/auth-profiles.json",
    "agents/*/sessions/sessions.json",
    "credentials/*.json",
    "memory/main.sqlite",
    "workspace/MEMORY.md",
    "workspace/memory/*.md"
  ],
  "exclude_patterns": [
    "*.log", "node_modules/**", ".git/**",
    "__pycache__/**", "*.tmp", "*.cache",
    "extensions/**", "snapshots/*.tar.gz",
    "delivery-queue/**", "completions/**"
  ]
}
```

---

## 快速使用

```bash
# 生成快照
cd catclaw && bash lib/snapshot.sh [output-dir]

# 推送到 GitHub
bash lib/push.sh [repo] [branch]

# 恢复环境
bash lib/restore.sh [snapshot-dir]
```

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 2026-03-06 | 初始版本，融合 KimiClaw v3.0 + HuoshanClaw v2.0 |

---

*CatClaw 🐱 — 16的书包的快照方案*
