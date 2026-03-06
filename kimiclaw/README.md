# KimiClaw

OpenClaw 环境快照管理工具

> 记住一切，随时恢复

## 简介

KimiClaw 是一个用于管理 OpenClaw 环境快照的工具，支持：

- 📦 **生成快照** - 打包当前环境为可恢复格式
- ☁️ **推送到云端** - 备份到 GitHub/Gitee 等仓库
- ⬇️ **从云端拉取** - 在新机器快速恢复
- 🔄 **恢复环境** - 一键还原完整配置

## 目录结构

```
kimiclaw/
├── bin/
│   └── kimiclaw              # 主入口脚本
├── lib/
│   ├── snapshot.sh           # 快照生成
│   ├── push.sh               # 推送到远程
│   ├── pull.sh               # 从远程拉取
│   └── restore.sh            # 恢复环境
├── config/
│   └── default.json          # 默认配置
└── kimiclaw.md               # 详细文档

~/.openclaw/                  # 快照目标目录结构
├── openclaw.json             # ⭐⭐⭐ 主配置
├── agents/                   # ⭐⭐⭐ Agent 配置
├── credentials/              # ⭐⭐⭐ 凭证（脱敏）
├── memory/                   # ⭐⭐⭐ 记忆文件
├── cron/                     # ⭐⭐ 定时任务
└── ...
```

## 安装

```bash
# 克隆仓库
git clone https://github.com/polegithub/shadowclaw.git
cd shadowclaw

# 添加到 PATH
export PATH="$PWD/kimiclaw/bin:$PATH"

# 或使用软链接
ln -s "$PWD/kimiclaw/bin/kimiclaw" /usr/local/bin/kimiclaw
```

## 使用

### 生成快照

```bash
# 生成到默认目录 (~/.openclaw/snapshots/)
kimiclaw generate

# 指定输出目录
kimiclaw generate -o ./my-snapshot

# 模拟运行（不实际执行）
kimiclaw generate --dry-run
```

### 推送到远程

```bash
# 使用默认配置
kimiclaw push

# 指定仓库和分支
kimiclaw push -r github.com/user/repo -b main
```

### 从远程拉取

```bash
kimiclaw pull

# 指定分支
kimiclaw pull -b feature-branch
```

### 恢复环境

```bash
# 使用最新快照
kimiclaw restore

# 指定快照目录
kimiclaw restore /path/to/snapshot

# 强制覆盖
kimiclaw restore -f
```

### 其他命令

```bash
kimiclaw list          # 列出本地快照
kimiclaw clean -k 5    # 清理旧快照，保留最近5个
kimiclaw config        # 查看配置
kimiclaw help          # 显示帮助
```

## 配置

编辑 `kimiclaw/config/default.json`：

```json
{
  "github": {
    "repo": "github.com/username/repo",
    "branch": "kimiclaw"
  },
  "snapshot": {
    "max_file_size_mb": 10,
    "exclude_patterns": ["*.log", "node_modules/**"]
  },
  "auto_backup": {
    "enabled": true,
    "cron": "0 2 * * *",
    "keep_count": 7
  }
}
```

## 环境变量

```bash
export GITHUB_TOKEN="ghp_xxxxxxxx"  # GitHub 访问令牌
```

## 工作原理

### 快照生成

1. 扫描 `~/.openclaw/` 目录
2. 按优先级分类文件（必备/重要/可选）
3. 脱敏处理敏感字段
4. 排除超大文件（>10MB）
5. 生成 `manifest.json`

### 恢复流程

1. 备份当前环境
2. 复制快照文件到目标位置
3. 提示用户填入凭证
4. 建议重启 OpenClaw

## 文件优先级

| 优先级 | 标记 | 说明 |
|--------|------|------|
| ⭐⭐⭐ | 必备 | 丢失后无法恢复或恢复成本极高 |
| ⭐⭐ | 重要 | 丢失后可重建但耗时 |
| ⭐ | 可选 | 有自动重建机制或体积过大 |

## 许可证

MIT

---

*KimiClaw - 守护你的 OpenClaw 配置*
