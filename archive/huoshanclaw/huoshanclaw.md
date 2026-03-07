# HuoshanClaw 快照方案

**版本：** v1.0  
**创建日期：** 2026-03-06  
**描述：** OpenClaw 优化后的快照备份与恢复方案

---

## 📁 目录结构

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
└── memory/
    └── lancedb/                              ⭐⭐⭐ 必备 — 向量记忆数据库（如启用了 memory-lancedb 插件）
```

---

## 🎯 文件优先级说明

### ⭐⭐⭐ 必备（Critical）
**丢失后无法恢复，必须备份：**
- `openclaw.json` - 主配置
- `agents/main/agent/auth-profiles.json` - API Keys
- `agents/main/sessions/sessions.json` - 会话索引
- `credentials/oauth.json` - OAuth tokens
- `credentials/whatsapp/default/creds.json` - WhatsApp 登录态
- `memory/lancedb/` - 向量记忆数据库

### ⭐⭐ 重要（Important）
**丢失后可以重建，但备份省时：**
- `agents/main/agent/models.json` - 模型配置
- `agents/main/sessions/*.jsonl` - 对话历史

### ⭐ 可选（Optional）
**可以忽略：**
- `credentials/whatsapp/default/creds.json.bak` - 自动备份

---

## 🚀 快速开始

### 创建快照

```bash
# 使用优化后的快照脚本
cd ~/.openclaw/workspace/skills/openclaw-snapshot/scripts
./snapshot-lean.sh
```

### 查看快照列表

```bash
ls -lh ~/.openclaw/snapshots/
```

### 恢复快照

```bash
# 停止 Gateway  first
cd ~/.openclaw/workspace/skills/openclaw-snapshot/scripts
./restore.sh <snapshot_name>
```

---

## 📊 快照内容对比

### 旧方案（完整快照）
- ✅ 包含所有文件
- ❌ 文件大（~500MB+）
- ❌ 备份/恢复慢
- ❌ 包含很多临时文件

### 新方案（优化快照）
- ✅ 只包含必备文件
- ✅ 文件小（预计 ~50MB）
- ✅ 备份/恢复快
- ✅ 忽略临时和缓存文件

---

## 🔧 高级配置

### 自定义快照内容

编辑 `~/.openclaw/workspace/skills/openclaw-snapshot/config/snapshot-paths.json`：

```json
{
  "include": [
    "openclaw.json",
    "agents/main/agent/auth-profiles.json",
    "agents/main/sessions/sessions.json"
  ],
  "exclude": [
    "*.log",
    "*.tmp",
    "node_modules/"
  ]
}
```

### 定时备份

```bash
# 每天凌晨 2 点自动备份
crontab -e
# 添加：
0 2 * * * cd ~/.openclaw/workspace/skills/openclaw-snapshot/scripts && ./snapshot-lean.sh
```

---

## ⚠️ 注意事项

1. **安全性** - 快照包含 API Keys，请妥善保管
2. **加密** - 敏感环境建议加密快照
3. **验证** - 恢复后验证配置完整性
4. **清理** - 定期清理旧快照，节省空间

---

## 📝 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2026-03-06 | 初始版本，优化快照结构 |

---

*最后更新：2026-03-06*
