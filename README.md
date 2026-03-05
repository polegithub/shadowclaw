# OpenClaw Snapshots

OpenClaw 智能快照同步系统。

## 📦 包含的 Skills

- **openclaw-sync** - 智能快照同步系统
- **file-size-checker** - 大文件检测和过滤工具
- **token-tracker** - Token 累计统计工具（解决 session_status 输出 token 不累计的问题）

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

### 查看真实 Token 累计统计

```bash
cd workspace-skills/token-tracker
python3 scripts/parse-session.py
```

**注意**：`session_status` 只显示单次输出，不是累计的！用这个脚本查看真实累计值。

## 📋 快照结构

```
config/              # ~/.openclaw/config
agents/              # ~/.openclaw/agents
workspace-skills/    # ~/.openclaw/workspace/skills
snapshot.json        # 快照元数据
```

## 🔧 详细说明

- openclaw-sync: 见 `workspace-skills/openclaw-sync/USAGE.md`
- token-tracker: 解决 session_status 输出 token 不累计的问题
