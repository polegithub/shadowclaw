# OpenClaw Sync 系统 - 使用指南

## 📦 已创建的 Skills

| Skill | 功能 | 位置 |
|-------|------|------|
| **openclaw-sync** | 智能快照同步系统 | `~/.openclaw/workspace/skills/openclaw-sync/` |
| **file-size-checker** | 大文件检测和过滤 | `~/.openclaw/workspace/skills/file-size-checker/` |

---

## 🎯 设计原则（按你的要求）

### ✅ 1. 新 OpenClaw 知道如何同步和恢复

- 快照仓库包含完整的 `README.md` 和使用说明
- 提供 `sync.sh restore` 一键恢复命令
- 元数据 `snapshot.json` 记录所有信息

### ✅ 2. 快照格式与 OpenClaw 一致

```
~/.openclaw-sync/          # 快照仓库
├── config/               # → ~/.openclaw/config
├── agents/               # → ~/.openclaw/agents
└── workspace-skills/     # → ~/.openclaw/workspace/skills
```

### ✅ 3. 快照内容完整

| 内容 | 说明 |
|------|------|
| ✅ config/ | 配置文件 |
| ✅ agents/ | 会话和记忆（MEMORY.md等） |
| ✅ workspace-skills/ | 自定义 Skills |
| ❌ extensions/ | 可重新安装，跳过 |
| ❌ node_modules/ | 可重新安装，跳过 |
| ❌ 大文件 | 自动检测并跳过 |

### ✅ 4. 大文件自动检测和过滤

- 独立的 `file-size-checker` skill
- 可配置阈值（默认 50MB）
- 支持白名单/黑名单
- 快照前自动扫描和报告

---

## 🚀 快速使用

### 在当前机器上：创建快照

```bash
# 1. 先检查大文件
cd ~/.openclaw/workspace/skills/file-size-checker
./scripts/check.sh pre-snapshot

# 2. 创建快照
cd ~/.openclaw/workspace/skills/openclaw-sync
./scripts/sync.sh snapshot

# 3. 推送到 GitHub
export GIT_REPO=https://github.com/polegithub/shadowclaw.git
./scripts/sync.sh push
```

### 在新机器上：恢复快照

```bash
# 1. 克隆仓库
git clone https://github.com/polegithub/shadowclaw.git ~/.openclaw-sync
cd ~/.openclaw-sync

# 2. 切换到 huoshanclaw 分支
git checkout huoshanclaw

# 3. 检查是否有 workspace-skills 目录（包含 openclaw-sync skill）
if [ -d "workspace-skills/openclaw-sync" ]; then
    # 如果有，先复制到正确位置
    mkdir -p ~/.openclaw/workspace/skills
    cp -r workspace-skills/* ~/.openclaw/workspace/skills/
    
    # 然后使用 skill 恢复
    cd ~/.openclaw/workspace/skills/openclaw-sync
    chmod +x scripts/sync.sh
    ./scripts/sync.sh restore
else
    # 如果没有，手动恢复
    echo "手动恢复..."
    [ -d "config" ] && cp -r config/* ~/.openclaw/config/ 2>/dev/null || true
    [ -d "agents" ] && cp -r agents/* ~/.openclaw/agents/ 2>/dev/null || true
    [ -d "workspace-skills" ] && cp -r workspace-skills/* ~/.openclaw/workspace/skills/ 2>/dev/null || true
    echo "恢复完成！"
fi
```

---

## 📋 完整命令参考

### openclaw-sync

| 命令 | 说明 |
|------|------|
| `./scripts/sync.sh snapshot` | 创建快照 |
| `./scripts/sync.sh push` | 推送到 GitHub |
| `./scripts/sync.sh restore` | 从快照恢复 |
| `./scripts/sync.sh status` | 显示状态 |
| `./scripts/sync.sh help` | 显示帮助 |

### file-size-checker

| 命令 | 说明 |
|------|------|
| `./scripts/check.sh scan <dir>` | 扫描指定目录 |
| `./scripts/check.sh pre-snapshot` | 快照前检查 |
| `./scripts/check.sh help` | 显示帮助 |

---

## 🔧 配置选项

### 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `GIT_REPO` | Git 仓库 URL | - |
| `MAX_FILE_SIZE_MB` | 最大文件大小（MB） | 50 |
| `WHITELIST` | 白名单文件 | - |
| `BLACKLIST` | 黑名单文件 | - |

---

## 📊 对比之前的方案

| 项目 | 之前 | 现在 |
|------|------|------|
| 快照格式 | tar.gz 压缩包 | Git 仓库，目录结构一致 |
| 大文件处理 | 手动优化 | 自动检测和过滤 |
| 版本管理 | 无 | Git 完整历史 |
| 恢复难度 | 需要解压 | 一键恢复 |
| 元数据 | 简单 | 完整的 snapshot.json |

---

## ✅ 完成的工作

1. ✅ **openclaw-sync skill** - 智能快照同步系统
2. ✅ **file-size-checker skill** - 大文件检测工具
3. ✅ **目录结构一致** - 与 OpenClaw 完全一致
4. ✅ **Git 友好** - 使用 Git 做版本管理
5. ✅ **智能过滤** - 自动跳过大文件和可重装内容

---

需要我帮你测试一下新的快照系统吗？
