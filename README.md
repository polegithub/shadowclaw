# OpenClaw Snapshots

OpenClaw 智能快照同步系统。

## 📦 包含的 Skills

- **openclaw-sync** - 智能快照同步系统
- **file-size-checker** - 大文件检测和过滤工具

## 🚀 快速使用

### 创建快照

```bash
cd workspace-skills/openclaw-sync
./scripts/sync.sh snapshot
```

### 恢复快照

```bash
cd workspace-skills/openclaw-sync
./scripts/sync.sh restore
```

## 📋 快照结构

```
config/              # ~/.openclaw/config
agents/              # ~/.openclaw/agents
workspace-skills/    # ~/.openclaw/workspace/skills
snapshot.json        # 快照元数据
```

## 🔧 详细说明

见 `workspace-skills/openclaw-sync/USAGE.md`
