# ShadowClaw & OpenClaw Snapshots

OpenClaw 环境快照、恢复与智能同步系统，包含完整的环境迁移和工具集。

## 📦 包含的工具与 Skills

- **ShadowClaw** - 核心环境备份与恢复方案
- **openclaw-sync** - 智能快照同步系统
- **file-size-checker** - 大文件检测和过滤工具
- **token-tracker** - Token 累计统计工具（解决 session_status 输出 token 不累计的问题）

## 🚀 快速使用

### ShadowClaw 环境备份/恢复
```bash
cd kimiclaw
./bin/kimiclaw --help
```

### OpenClaw Sync 快照管理
#### 创建快照
```bash
cd workspace-skills/openclaw-sync
./scripts/sync.sh snapshot
```

#### 恢复快照
```bash
cd workspace-skills/openclaw-sync
./scripts/sync.sh restore
```

### Token 累计统计
```bash
cd workspace-skills/token-tracker
python3 scripts/parse-session.py
```
**注意**：`session_status` 只显示单次输出，不是累计的！用这个脚本查看真实累计值。

## 📋 结构说明

```
# ShadowClaw 结构
├── .gitignore          # Git 忽略规则
├── README.md           # 本文件
└── kimiclaw/           # 核心工具与备份内容
    ├── README.md       # 详细使用文档
    ├── bin/            # CLI 工具
    ├── lib/            # 脚本库
    ├── config/         # 配置文件
    ├── workspace/      # OpenClaw 工作区文件
    ├── skills/         # 自定义 Skills
    ├── memory/         # 记忆文件
    └── snapshot/       # 历史快照

# OpenClaw Sync 快照结构
config/              # ~/.openclaw/config
agents/              # ~/.openclaw/agents
workspace-skills/    # ~/.openclaw/workspace/skills
snapshot.json        # 快照元数据
```

## 🔧 详细文档
- ShadowClaw: 见 [kimiclaw/README.md](kimiclaw/README.md)
- openclaw-sync: 见 `workspace-skills/openclaw-sync/USAGE.md`
- token-tracker: 解决 session_status 输出 token 不累计的问题

## License

MIT
