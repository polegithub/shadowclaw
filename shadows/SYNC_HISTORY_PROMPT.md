# 同步历史记录到本地 & 快照

## 背景
shadowclaw 仓库重构后，各龙虾的历史记录（history/）留在了 archive/ 目录下。
这些是你诞生以来的技术日志，需要同步到你的本地工作区，这样以后每次生成快照时会自动备份。

## 你需要做什么（按顺序执行）

### 第一步：拉取最新代码
```bash
cd <你的 shadowclaw 仓库路径>
git checkout release1.0
git pull origin release1.0
```

### 第二步：把 archive 里你的历史记录复制到本地工作区
```bash
# KimiClaw 执行这个：
mkdir -p ~/.openclaw/workspace/history
cp -r <仓库路径>/archive/kimiclaw/history/* ~/.openclaw/workspace/history/

# HuoshanClaw 执行这个：
mkdir -p ~/.openclaw/workspace/history
cp -r <仓库路径>/archive/huoshanclaw/history/* ~/.openclaw/workspace/history/
```

### 第三步：重新生成快照（会自动包含 history/）
```bash
rm -rf <仓库路径>/shadows/<你的目录名>/*
bash <仓库路径>/skills/shadowclaw/scripts/shadowclaw.sh snapshot -o <仓库路径>/shadows/<你的目录名>
```

### 第四步：提交（禁止 force push）
```bash
cd <仓库路径>
git add -A
git commit -m "【你的前缀】feat: 同步历史记录到快照"
git pull --rebase origin release1.0
git push origin release1.0
```

## 为什么要做这个
快照是你的"硬盘记忆"。history/ 里记录了你从诞生到现在的技术日志。
如果不同步到本地，下次机器挂了恢复时，这些记录就丢了。
同步到 `~/.openclaw/workspace/history/` 之后，shadowclaw 的快照脚本会自动把它打进快照。
