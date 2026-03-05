# OpenClaw Snapshots

自动备份的 OpenClaw 快照（优化版）。

## 快照说明

这是优化版快照，排除了大文件（extensions 目录），只包含核心数据：

- ✅ 配置文件
- ✅ Agents 会话和记忆
- ✅ 自定义 Skills
- ❌ Extensions（可重新安装）

## 快照列表

- `openclaw_lean_20260306_001950.tar.gz` (204K) - 2026-03-06 00:20

## 恢复说明

1. 下载快照文件
2. 解压到 `~/.openclaw/` 目录
3. 重新安装需要的 extensions

需要恢复时，extensions 可以通过 OpenClaw 重新安装！
