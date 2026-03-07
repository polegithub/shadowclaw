# KimiClaw 敏感信息清单

> 融入快照前必须清除/替换的 Kimi 特有密钥和账号信息

## ⚠️ 需要清除的敏感信息

### 1. Kimi API Keys（出现在多个文件中）

| 字段 | 值（部分脱敏） | 所在文件 |
|:---|:---|:---|
| KIMI_API_KEY | `sk-kimi-raOJcf...dY0KL0L9` | `openclaw-config.json` → `env.KIMI_API_KEY` |
| KIMI_PLUGIN_API_KEY | `sk-kimi-raOJcf...dY0KL0L9` | `openclaw-config.json` → `env.KIMI_PLUGIN_API_KEY` |
| kimi-coding apiKey | `sk-kimi-raOJcf...dY0KL0L9` | `openclaw-config.json` → `models.providers.kimi-coding.apiKey` |
| kimiCodeAPIKey | `sk-kimi-raOJcf...dY0KL0L9` | `openclaw-config.json` → `plugins.entries.kimi-claw.config.bridge.kimiCodeAPIKey` |
| kimiPluginAPIKey | `sk-kimi-raOJcf...dY0KL0L9` | `openclaw-config.json` → `plugins.entries.kimi-claw.config.bridge.kimiPluginAPIKey` |
| defaultModel apiKey | `sk-kimi-raOJcf...dY0KL0L9` | `openclaw-config.json` → `plugins.entries.kimi-claw.config.defaultModel.apiKey` |

> 同一个 key 复制了 6 处，实际是 1 个值：`sk-kimi-raOJcflbclzY73MAR7yZCKlVMAP4di9c9PckqWRi8Cw7KWccwaknavkZdY0KL0L9`

### 2. Kimi Bridge Token

| 字段 | 值（部分脱敏） | 所在文件 |
|:---|:---|:---|
| bridge.token | `sk-KWWA3XZB...UGSHCI` | `openclaw-config.json` → `plugins.entries.kimi-claw.config.bridge.token` |

### 3. 飞书（Feishu）凭证

| 字段 | 值（部分脱敏） | 所在文件 |
|:---|:---|:---|
| feishu appId | `cli_a9225fcd57bb5cd3` | `openclaw-config.json` → `channels.feishu.appId` |
| feishu appSecret | `Zfv6YRaY...DumRZy` | `openclaw-config.json` → `channels.feishu.appSecret` |

### 4. Gateway Auth Token

| 字段 | 值（部分脱敏） | 所在文件 |
|:---|:---|:---|
| gateway.auth.token | `1ba823b2...22095a` | `openclaw-config.json` → `gateway.auth.token` |
| gateway token (plugin) | 同上 | `openclaw-config.json` → `plugins.entries.kimi-claw.config.gateway.token` |

### 5. Kimi Claw 设备标识

| 字段 | 值 | 所在文件 |
|:---|:---|:---|
| X-Kimi-Claw-ID | `19cb8831-02d2-86a1-8000-0000337ebf33` | `openclaw-config.json` → models headers |
| instanceId | `connector-c-kimiclaw-test` | `openclaw-config.json` → plugins bridge |
| deviceId | `c-kimiclaw-test` | `openclaw-config.json` → plugins bridge |

### 6. 飞书群组 ID

| 字段 | 值 | 所在文件 |
|:---|:---|:---|
| 默认发送群 ID | `oc_40efcf271da2a542291ab9b83d2eea97` | `workspace/TOOLS.md` |

---

## 📂 受影响的文件清单

| 文件 | 敏感级别 | 说明 |
|:---|:---:|:---|
| `openclaw-config.json` | 🔴 高 | 包含所有真实密钥，**不可直接使用** |
| `snapshot/openclaw-config.json` | 🔴 高 | 同上，另一份副本 |
| `config-backup/openclaw.json` | 🟡 中 | 已部分脱敏但仍有结构信息 |
| `workspace/TOOLS.md` | 🟡 中 | 含飞书群组 ID |
| `secrets-template.json` | ✅ 安全 | 已是占位符模板 |
| `snapshot/secrets-template.json` | ✅ 安全 | 同上 |

---

## ✅ 可以安全融入的文件（无敏感信息）

| 文件/目录 | 内容 |
|:---|:---|
| `workspace/IDENTITY.md` | Kimi 的人格定义（参考用） |
| `workspace/SOUL.md` | Kimi 的灵魂文件（有价值的写作理念） |
| `workspace/AGENTS.md` | 工作流配置（和我们的基本一致） |
| `memory/2026-03-04.md` | 每日新闻收集记录 |
| `memory/2026-03-04-v2.md` | 每日新闻 v2 |
| `memory/daily-news/` | 新闻存档 |
| `skills/snapshot-sync/` | 快照同步 Skill |
| `skills/cron-executor/` | Cron 执行器 Skill |
| `skills/message-deduplication/` | 消息去重 Skill |
| `lib/snapshot.sh` | 快照生成脚本 |
| `lib/restore.sh` | 恢复脚本 |
| `lib/push.sh` | 推送脚本 |
| `kimiclaw.md` | 方案文档 |
| `manifest.json` | 快照元数据 |

---

## 🔧 融入时的处理策略

1. **配置文件** → 不直接复制，仅参考结构（browser、agents、commands 等通用配置）
2. **密钥** → 全部清除，替换为 `{{SECRET:xxx}}` 占位符
3. **Kimi 特有插件** → `kimi-claw`、`kimi-search` 插件配置跳过（我们用不上）
4. **飞书配置** → 跳过（我们用大象）
5. **Skills** → 复制 snapshot-sync、cron-executor、message-deduplication（通用能力）
6. **记忆文件** → 选择性融入有价值的内容
7. **工具脚本** → 复制 lib/ 下的 shell 脚本（通用快照工具）
