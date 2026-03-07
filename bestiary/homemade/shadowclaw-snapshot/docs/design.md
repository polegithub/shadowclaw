# CatClaw v2.0 设计文档

## 背景

ShadowClaw 项目有三套 OpenClaw 快照方案，各有优劣：

| 维度 | KimiClaw v3.0 | HuoshanClaw v2.0 | CatClaw v1.0 |
|------|:---:|:---:|:---:|
| 可执行脚本 | ✅ CLI + lib/ | ❌ 纯文档 | ✅ 复制自 kimiclaw |
| 目录覆盖范围 | 中等 | 最完整 | 较完整 |
| 脱敏机制 | ✅ sed 替换 | ❌ 仅建议 | ✅ |
| Manifest 追踪 | ✅ | ❌ | ✅ |
| 恢复前备份 | ✅ | ❌ | ✅ |
| identity/ 覆盖 | ❌ | ✅ | ✅ |
| .env 覆盖 | ❌ | ✅ | ✅ |
| memory/main.sqlite | ❌ | ✅ | ✅ |
| workspace/memory/ | ❌ | ✅ | ✅ |
| Skills 目录 | ❌ | ✅ workspace/skills | ✅ |
| ~/.openclaw/skills/ | ❌ | ❌ | ❌ |
| feishu 配置 | ❌ | ✅ | ✅ |
| devices/ | ❌ | ❌ | ❌ |
| 代码整洁度 | 中等（大量重复文件） | 高（结构清晰） | 低（复制了 skills） |

## CatClaw v2.0 的改进

### 1. 统一入口

v1.0 有 `lib/snapshot.sh`, `lib/restore.sh`, `lib/push.sh` 三个脚本加上 `skills/bin/` 下的 5 个命令。
v2.0 合并为一个 `bin/shadowclaw`，所有操作通过子命令完成。

### 2. 配置驱动

v1.0 的备份路径硬编码在脚本中。
v2.0 将所有路径、优先级、大小限制、脱敏规则提取到 `config/paths.json`。改需求只改配置。

### 3. 扩大覆盖范围

新增 v1.0 遗漏的：
- `~/.openclaw/skills/` — 通过 ClaHub 安装的全局 Skills
- `feishu/dedup/*.json` — 飞书去重状态
- `devices/*.json` — 设备配对信息
- `identity/device-auth.json` — 设备认证

### 4. 移除非快照内容

v1.0 包含了：
- `skills/cron-executor/` — 这是 OpenClaw 的运行时 skill，不属于快照工具
- `skills/message-deduplication/` — 同上
- `skills/snapshot-sync.js`, `token-tracker.js` 等 — 过于复杂的辅助工具
- `memory/` 下的历史记忆文件 — 应由 kimiclaw 保管，catclaw 只提供工具

v2.0 只保留快照工具本身。

### 5. 新增 verify 命令

可以检查快照完整性和安全性，不需要实际恢复。

## 目录结构对比

```
# v1.0 (30+ 文件)              # v2.0 (4 文件)
catclaw/                        catclaw/
├── catclaw.md                  ├── bin/
├── config/                     │   └── shadowclaw     ← 唯一脚本
│   └── default.json            ├── config/
├── lib/                        │   └── paths.json     ← 配置驱动
│   ├── snapshot.sh             ├── docs/
│   ├── restore.sh              │   └── design.md      ← 本文件
│   └── push.sh                 └── README.md
├── skills/                     
│   ├── bin/ (5 files)          
│   ├── cron-executor/ (3)      
│   ├── message-dedup/ (3)      
│   ├── *.js (2)                
│   ├── *.sh (2)                
│   └── *.md (3)                
├── memory/ (6 files)           
├── workspace/ (1)              
└── README.md                   
```

## 快照输出结构

运行 `shadowclaw snapshot` 后生成的目录镜像 `~/.openclaw/` 的结构：

```
snapshot-20260307-030000/
├── openclaw.json                 🔴 主配置（已脱敏）
├── agents/
│   └── main/
│       ├── agent/
│       │   ├── auth-profiles.json  🔴 API Keys（已脱敏）
│       │   └── models.json         🟡 模型配置
│       └── sessions/
│           ├── sessions.json       🔴 会话索引
│           └── *.jsonl             🟡 对话历史
├── credentials/
│   ├── oauth.json                  🔴 OAuth（已脱敏）
│   ├── feishu-pairing.json         🔴 飞书配对（已脱敏）
│   └── whatsapp/default/creds.json 🔴 WhatsApp（已脱敏）
├── memory/
│   ├── main.sqlite                 🔴 SQLite 记忆
│   └── lancedb/                    🔴 向量记忆
├── workspace/
│   ├── AGENTS.md                   🔴
│   ├── SOUL.md                     🔴
│   ├── USER.md                     🔴
│   ├── IDENTITY.md                 🔴
│   ├── MEMORY.md                   🔴
│   ├── TOOLS.md                    🟡
│   ├── HEARTBEAT.md                🟡
│   ├── memory/*.md                 🔴 每日记忆
│   └── skills/                     🟡 workspace skills
├── skills/                         🟡 全局 skills
├── cron/jobs.json                  🟡
├── identity/
│   ├── device.json                 🟡
│   └── device-auth.json            🟡
├── .env                            🟡（已脱敏）
├── manifest.json                   📋 快照元数据
└── secrets-template.json           📋 凭证填写指南
```

## 恢复流程

```
1. 自动备份当前 ~/.openclaw/ → ~/.openclaw/backup/YYYYMMDD-HHMMSS/
2. 逐目录覆盖：openclaw.json, agents/, credentials/, memory/, workspace/, cron/, identity/, .env
3. 跳过 manifest.json 和 secrets-template.json
4. 提示用户：
   a. 填入真实凭证替换 {{SECRET:xxx}}
   b. 重启 openclaw gateway
   c. 验证 openclaw status
```

## 三方方案如何取长补短

- **KimiClaw** 贡献了 CLI 设计理念和脱敏思路
- **HuoshanClaw** 贡献了最完整的目录覆盖清单
- **CatClaw v2.0** 将两者优点合并，去掉冗余，用最少的代码实现最完整的功能
