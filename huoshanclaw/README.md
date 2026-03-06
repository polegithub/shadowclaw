# HuoshanClaw 快照方案

**版本：** v2.0  
**创建日期：** 2026-03-06  
**描述：** OpenClaw 优化后的快照备份与恢复方案

---

## 📁 完整目录结构

```
huoshanclaw/                                  ← 根目录
│
├── openclaw.json                             ⭐⭐⭐ 必备 — 主配置文件（渠道、模型、Agent、Hook）
├── openclaw.json.bak                         ⭐    可选 — 配置备份（自动生成）
├── .env                                      ⭐⭐  重要 — 环境变量
├── update-check.json                         ⭐    可选 — 更新检查状态
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
│   ├── feishu-pairing.json                   ⭐⭐  重要 — 飞书配对信息
│   └── whatsapp/
│       └── default/
│           ├── creds.json                    ⭐⭐⭐ 必备 — WhatsApp Web 登录态（扫码后）
│           └── creds.json.bak                ⭐    可选 — 自动备份
│
├── memory/
│   ├── main.sqlite                           ⭐⭐⭐ 必备 — 主记忆数据库（SQLite）
│   └── lancedb/                              ⭐⭐⭐ 必备 — 向量记忆数据库（如启用了 memory-lancedb 插件）
│       └── README.md
│
├── workspace/
│   ├── AGENTS.md                             ⭐⭐⭐ 必备 — Agent 工作区配置
│   ├── SOUL.md                               ⭐⭐⭐ 必备 — Agent 人格和灵魂
│   ├── USER.md                               ⭐⭐⭐ 必备 — 用户信息
│   ├── IDENTITY.md                           ⭐⭐⭐ 必备 — Agent 身份
│   ├── TOOLS.md                              ⭐⭐  重要 — 工具配置
│   ├── HEARTBEAT.md                          ⭐⭐  重要 — 心跳检查清单
│   ├── BOOTSTRAP.md                          ⭐    可选 — 初始化引导（如存在）
│   ├── README.md                             ⭐    可选 — 工作区说明
│   │
│   ├── memory/                               ⭐⭐⭐ 必备 — 短期记忆日志
│   │   └── YYYY-MM-DD.md                    ⭐⭐⭐ 必备 — 每日对话日志
│   │
│   ├── skills/                               ⭐⭐  重要 — 自定义 Skills
│   │   └── <skill-name>/
│   │       ├── SKILL.md
│   │       ├── USAGE.md
│   │       └── scripts/
│   │
│   ├── tasks.json                            ⭐⭐  重要 — 任务管理数据库
│   ├── message-cache.json                    ⭐    可选 — 消息去重缓存（可重新生成）
│   ├── chat_ids.md                           ⭐    可选 — 聊天 ID 映射
│   ├── fetch-openclaw-news.sh                ⭐    可选 — 辅助脚本
│   └── .openclaw/
│       └── workspace-state.json              ⭐    可选 — 工作区状态
│
├── cron/
│   └── jobs.json                             ⭐⭐  重要 — 定时任务配置
│
├── identity/
│   └── device.json                           ⭐⭐  重要 — 设备身份信息
│
├── logs/                                     ⭐    可选 — 日志文件（通常较大，可跳过）
│   └── *.log
│
├── canvas/                                   ⭐    可选 — Canvas 临时文件
├── completions/                              ⭐    可选 — 补全缓存（可重新生成）
├── delivery-queue/                           ⭐    可选 — 消息投递队列（临时）
├── extensions/                               ❌    跳过 — 可重新安装
│   └── <extension-name>/
│       ├── package.json
│       ├── openclaw.plugin.json
│       └── node_modules/                     ❌    跳过 — 可重新安装
│
└── snapshots/                                ❌    跳过 — 快照本身不备份
```

---

## 🎯 文件优先级说明

### ⭐⭐⭐ 必备（Critical）
**丢失后无法恢复，必须备份：**

| 文件/目录 | 说明 |
|----------|------|
| `openclaw.json` | 主配置（渠道、模型、Agent、Hook） |
| `agents/main/agent/auth-profiles.json` | 所有 API Key |
| `agents/main/sessions/sessions.json` | 会话索引 |
| `credentials/*.json` | OAuth / 配对信息 |
| `credentials/whatsapp/default/creds.json` | WhatsApp 登录态 |
| `memory/main.sqlite` | 主记忆数据库 |
| `memory/lancedb/` | 向量记忆数据库 |
| `workspace/AGENTS.md` | Agent 配置 |
| `workspace/SOUL.md` | Agent 人格 |
| `workspace/USER.md` | 用户信息 |
| `workspace/IDENTITY.md` | Agent 身份 |
| `workspace/memory/YYYY-MM-DD.md` | 每日记忆日志 |

### ⭐⭐ 重要（Important）
**丢失后可以重建，但备份省时：**

| 文件/目录 | 说明 |
|----------|------|
| `.env` | 环境变量 |
| `agents/main/agent/models.json` | 模型配置 |
| `agents/main/sessions/*.jsonl` | 对话历史 |
| `workspace/TOOLS.md` | 工具配置 |
| `workspace/HEARTBEAT.md` | 心跳清单 |
| `workspace/skills/` | 自定义 Skills |
| `workspace/tasks.json` | 任务数据库 |
| `cron/jobs.json` | 定时任务 |
| `identity/device.json` | 设备身份 |

### ⭐ 可选（Optional）
**可以忽略或重新生成：**

| 文件/目录 | 说明 |
|----------|------|
| `openclaw.json.bak*` | 配置备份（自动生成） |
| `update-check.json` | 更新检查状态 |
| `workspace/BOOTSTRAP.md` | 初始化引导 |
| `workspace/README.md` | 工作区说明 |
| `workspace/message-cache.json` | 消息去重缓存 |
| `workspace/chat_ids.md` | 聊天 ID 映射 |
| `workspace/fetch-openclaw-news.sh` | 辅助脚本 |
| `workspace/.openclaw/` | 工作区状态 |

### ❌ 跳过（Skip）
**完全不需要备份：**

| 文件/目录 | 说明 |
|----------|------|
| `extensions/` | 插件（可重新安装） |
| `*/node_modules/` | Node 依赖（可重新安装） |
| `logs/*.log` | 日志文件（通常较大） |
| `canvas/` | Canvas 临时文件 |
| `completions/` | 补全缓存 |
| `delivery-queue/` | 消息投递队列 |
| `snapshots/*.tar.gz` | 快照本身 |

---

## 📊 文件大小过滤建议

### 默认阈值
| 文件类型 | 建议阈值 | 处理方式 |
|---------|----------|---------|
| `node_modules/` | 任何大小 | ❌ 跳过（可重新安装） |
| `extensions/*/node_modules/` | 任何大小 | ❌ 跳过 |
| `logs/*.log` | > 10MB | ⚠️ 可选备份 |
| `agents/*/sessions/*.jsonl` | > 50MB | ⚠️ 可选备份 |
| `snapshots/*.tar.gz` | 任何大小 | ❌ 跳过（快照本身） |
| `memory/main.sqlite` | 任何大小 | ✅ 始终备份 |
| `workspace/memory/*.md` | 任何大小 | ✅ 始终备份 |

### 白名单（始终备份）
```
openclaw.json
agents/*/agent/auth-profiles.json
agents/*/sessions/sessions.json
credentials/*.json
memory/main.sqlite
memory/lancedb/
workspace/AGENTS.md
workspace/SOUL.md
workspace/USER.md
workspace/IDENTITY.md
workspace/memory/*.md
```

---

## 🚀 快速开始

### 创建快照

```bash
# 方式一：手动组织（推荐）
cd ~/.openclaw
mkdir -p ~/huoshanclaw-snapshot

# 复制必备文件
cp openclaw.json ~/huoshanclaw-snapshot/
cp -r agents/ ~/huoshanclaw-snapshot/
cp -r credentials/ ~/huoshanclaw-snapshot/
cp -r memory/ ~/huoshanclaw-snapshot/
cp -r workspace/ ~/huoshanclaw-snapshot/
# ... 选择性复制其他重要文件

# 方式二：使用 Git（推荐用于版本管理）
cd ~/huoshanclaw-snapshot
git init
git add .
git commit -m "快照：$(date +%Y-%m-%d)"
```

### 恢复快照

```bash
# 停止 Gateway  first
cd ~/.openclaw

# 备份当前状态（可选但推荐）
mv ~/.openclaw ~/.openclaw.backup.$(date +%Y%m%d_%H%M%S)

# 从快照恢复
cp -r ~/huoshanclaw-snapshot/* ~/.openclaw/

# 重新安装 extensions
#（如果需要）
```

---

## 📝 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v2.0 | 2026-03-06 | 完整目录结构，添加 workspace/、cron/、identity/、logs/ 等 |
| v1.0 | 2026-03-06 | 初始版本，基础快照结构 |

---

*最后更新：2026-03-06*
