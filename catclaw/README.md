# CatClaw 🐱

16的书包的 OpenClaw 快照方案。

## 基于

- **KimiClaw v3.0** — 可执行脚本、脱敏机制、manifest 追踪
- **HuoshanClaw v2.0** — 更完整的目录覆盖范围

## 目录结构

```
catclaw/
├── catclaw.md              # 方案文档
├── README.md               # 本文件
├── config/
│   └── default.json        # 快照配置
├── lib/
│   ├── snapshot.sh         # 生成快照
│   ├── restore.sh          # 恢复环境
│   └── push.sh             # 推送到 Git
├── skills/
│   ├── snapshot-sync/      # 快照同步 Skill
│   ├── cron-executor/      # Cron 健壮执行器
│   └── message-deduplication/  # 消息去重
├── memory/                 # 继承的记忆文件
│   ├── daily-news/
│   └── *.md
├── workspace/
│   └── REFERENCE-SOUL.md   # 灵感参考
└── snapshot/               # 快照输出目录
```

## 快速使用

```bash
# 生成快照
bash lib/snapshot.sh [output-dir]

# 推送到 GitHub
bash lib/push.sh

# 恢复
bash lib/restore.sh [snapshot-dir]
```

## 特性

- ✅ 自动脱敏敏感数据（API Key、Token、Secret）
- ✅ 推送前安全检查（检测未脱敏的密钥）
- ✅ 恢复前自动备份当前环境
- ✅ manifest.json 追踪快照元数据
- ✅ 覆盖 identity/、.env、main.sqlite、workspace/memory/（来自 HuoshanClaw）
- ✅ 继承 cron-executor、message-dedup skills（来自 KimiClaw）
