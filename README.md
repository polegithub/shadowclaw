# ShadowClaw — OpenClaw 环境快照与恢复

机器挂了、换机器、重装系统——你的 OpenClaw 龙虾不用从零开始。ShadowClaw 把 `~/.openclaw` 里的配置、记忆、会话、凭证、skills 打成一份快照，恢复时一条命令回到原来的状态。

## 这个仓库里有什么

```
shadowclaw/
├── skills/shadowclaw/          ← 核心 skill（可直接安装到 OpenClaw）
│   ├── SKILL.md                ← skill 入口（触发词：快照/备份/恢复）
│   ├── scripts/shadowclaw.sh   ← 主脚本（833行，全功能）
│   ├── config/default.json     ← 默认配置（备份范围、脱敏规则）
│   ├── docs/design.md          ← 方案设计
│   └── tests/run_tests.sh      ← 34项自动化测试
│
├── shadows/                    ← 真实快照落地（每个龙虾一个目录）
├── archive/                    ← 历史方案存档（三套旧方案 + 评测记录）
└── README.md
```

## 前置条件

- OpenClaw 已安装并运行（`openclaw status` 能正常返回）
- bash、jq、git 已安装

---

## 怎么用

### 场景一：通过 ClawHub 安装（skill 已发布）

如果 ShadowClaw 已发布到 ClawHub，你只需要跟龙虾说一句话。

**第一步：安装 skill**

跟你的龙虾说：

> 帮我安装 shadowclaw skill

龙虾会执行：

```bash
clawhub install shadowclaw
```

skill 会被安装到 `~/.openclaw/skills/shadowclaw/`。下次会话开始时，龙虾自动加载这个 skill。

**第二步：使用**

直接跟龙虾对话就行：

> 帮我做一份环境快照

> 把快照恢复到当前环境

> 做一个增量备份

> 设置每6小时自动快照

龙虾读到 SKILL.md 里的触发词（快照、备份、恢复、snapshot、backup、restore），会自动调用 `scripts/shadowclaw.sh`。

**龙虾内部怎么工作的：**

1. OpenClaw 启动时扫描 `~/.openclaw/skills/` 目录
2. 读到 `shadowclaw/SKILL.md` 的 frontmatter（name + description）
3. 用户消息命中触发词时，加载 SKILL.md 正文中的命令说明
4. 龙虾按说明执行 `bash {baseDir}/scripts/shadowclaw.sh snapshot -o ...`
5. `{baseDir}` 会被替换为 skill 实际安装路径

---

### 场景二：手动安装（clone 仓库）

如果 skill 还没上 ClawHub，或者你想自己掌控版本。

**第一步：clone 仓库**

```bash
git clone https://github.com/polegithub/shadowclaw.git
```

**第二步：把 skill 复制到 OpenClaw 能识别的位置**

两种放法，选一种：

方法 A：放到全局 skills（所有龙虾共享）

```bash
cp -r shadowclaw/skills/shadowclaw ~/.openclaw/skills/shadowclaw
```

方法 B：放到工作区 skills（仅当前龙虾）

```bash
cp -r shadowclaw/skills/shadowclaw ~/.openclaw/workspace/skills/shadowclaw
```

工作区优先级更高。如果两个位置都有同名 skill，工作区的会覆盖全局的。

**第三步：重启或等下一轮会话**

OpenClaw 在每次会话开始时重新扫描 skills 目录。你可以等龙虾下次醒来，也可以手动重启：

```bash
openclaw gateway restart
```

**第四步：使用**

跟龙虾说话，方式和场景一完全一样：

> 帮我做一份快照

> 恢复到上次的快照

**龙虾如果没反应？** 可能是 skill 没被加载。让龙虾确认一下：

> 你能看到 shadowclaw skill 吗？

---

## 不想跟龙虾说话，自己手动跑也行

```bash
# 生成快照
bash skills/shadowclaw/scripts/shadowclaw.sh snapshot -o ~/my-snapshot

# 恢复
bash skills/shadowclaw/scripts/shadowclaw.sh restore --force ~/my-snapshot

# 增量快照（只备份变更文件）
bash skills/shadowclaw/scripts/shadowclaw.sh snapshot --incremental -o ~/my-snapshot

# 验证快照完整性
bash skills/shadowclaw/scripts/shadowclaw.sh verify ~/my-snapshot

# 对比快照和当前环境差异
bash skills/shadowclaw/scripts/shadowclaw.sh diff ~/my-snapshot

# 定时快照（每6小时）
bash skills/shadowclaw/scripts/shadowclaw.sh cron --interval 6h

# 查看帮助
bash skills/shadowclaw/scripts/shadowclaw.sh help
```

## 快照报告

每次快照完成后自动生成 `SNAPSHOT_REPORT.md`，内容包括：

- 备份概览：总文件数、体积、skills 数量、会话数、记忆文件数
- 安全与脱敏：脱敏了哪些平台（飞书/Telegram/Discord/大象/GitHub 等）、占位符总数
- 风险提示：哪些目录未备份、哪些文件体积过大被跳过、跳过原因
- 存储建议：GitHub 私有仓库 / 加密压缩 / 对象存储 / NAS

## 快照存到哪里

快照是你龙虾的"硬盘记忆"，需要存到安全的地方。

**推荐方案（按安全性排序）：**

| 方案 | 命令 | 特点 |
|------|------|------|
| GitHub 私有仓库 | `shadowclaw push -r github.com/你/repo` | 版本可追溯，恢复时 git clone 就行 |
| Backblaze B2 | 搭配 rclone：`rclone sync ./snapshot b2:bucket` | 便宜（$0.005/GB），社区有 openclaw-b2-backup 方案 |
| Cloudflare R2 | 搭配 rclone：`rclone sync ./snapshot r2:bucket` | 免出站流量费 |
| AWS S3 / 阿里云 OSS | 搭配 aws-cli 或 ossutil | 企业级，配合 IAM 权限 |
| 本地加密压缩 | `tar czf snap.tar.gz <目录>` + `gpg -c snap.tar.gz` | 离线保存，U盘/NAS |

**恢复时怎么拿回快照：**

```bash
# 从 GitHub 私有仓库
git clone git@github.com:你/repo.git my-snapshot
shadowclaw restore --force my-snapshot

# 从对象存储
rclone copy b2:bucket/latest-snapshot ./my-snapshot
shadowclaw restore --force ./my-snapshot

# 从本地加密备份
gpg -d snap.tar.gz.gpg | tar xzf -
shadowclaw restore --force ./snap
```

## 安全

快照自动脱敏。API Key、Token、私钥等敏感字段会被替换为 `{{SECRET:field_name}}`。恢复后参考 `secrets-template.json` 填入真实值。

推送到 GitHub 之前会做深度扫描。如果发现明文密钥，推送会被拦截。

## 跑测试

```bash
# skill 自带的 34 项测试
bash skills/shadowclaw/tests/run_tests.sh

# 脚本内置的 12 项自测
bash skills/shadowclaw/scripts/shadowclaw.sh test
```

## 项目背景

2026年3月，三个 OpenClaw 龙虾（CatPawClaw、KimiClaw、HuoshanClaw）各自做了一套快照方案，经过统一评测和 PK，最终合并为这一个 skill。历史方案和评测记录保留在 `archive/` 目录。
