# KimiClaw v4.0 详细文档

## 架构设计

### 核心原则

1. **单一职责**: `bin/kimiclaw` 是唯一的用户入口
2. **配置驱动**: 所有行为通过 `config/default.json` 定义
3. **最小代码**: 约 500 行 Bash 实现全部功能
4. **透明脱敏**: 自动处理敏感字段，生成恢复模板

### 快照流程

```
生成快照:
  1. 读取 config/default.json 获取优先级配置
  2. 按 ⭐⭐⭐ → ⭐⭐ → ⭐ 顺序复制文件
  3. 对 JSON 文件执行脱敏处理
  4. 生成 manifest.json 记录快照元数据
  5. 生成 secrets-template.json 凭证模板

恢复快照:
  1. 验证快照完整性（manifest）
  2. 备份当前环境（可选）
  3. 逐目录覆盖恢复
  4. 提示用户填入真实凭证
  5. 建议重启 OpenClaw
```

## 配置文件详解

### config/default.json

```json
{
  "version": "4.0.0",
  "snapshot": {
    "outputDir": "./snapshots",        // 默认输出目录
    "maxFileSizeMB": 10,                // 文件大小限制
    "excludePatterns": [...],           // 排除规则
    "whitelist": [...]                  // 白名单路径
  },
  "priority": {
    "critical": { "paths": [...] },     // ⭐⭐⭐ 必备
    "important": { "paths": [...] },    // ⭐⭐ 重要
    "optional": { "paths": [...] }      // ⭐ 可选
  },
  "sensitive": {
    "fields": ["token", "apiKey", ...], // 敏感字段名
    "maskTemplate": "{{SECRET:{{field}}}}"
  },
  "github": {
    "repo": "github.com/user/repo",
    "branch": "main"
  }
}
```

## 命令参考

### generate (g)

生成环境快照

```bash
kimiclaw generate [options]

选项:
  -o, --output DIR    指定输出目录
  -d, --dry-run       模拟运行，不实际复制
  -f, --force         强制覆盖现有目录

示例:
  kimiclaw generate
  kimiclaw generate -o ~/backups/my-snapshot
  kimiclaw generate --dry-run  # 预览会复制哪些文件
```

### restore (r)

从快照恢复环境

```bash
kimiclaw restore <snapshot-dir> [options]

选项:
  -f, --force       跳过确认提示
  -b, --backup      恢复前备份当前环境（默认开启）
  --no-backup       不备份当前环境

示例:
  kimiclaw restore ./snapshots/snapshot-20260307-120000
  kimiclaw restore ./snapshot-xxx -f
```

**恢复后检查清单**:
1. 检查 `secrets-template.json` 填入真实凭证
2. 重启 OpenClaw: `openclaw gateway restart`
3. 验证状态: `openclaw status`

### push (p)

推送到 Git 远程仓库

```bash
kimiclaw push [options]

选项:
  -r, --repo URL      仓库地址（覆盖配置）
  -b, --branch NAME   分支名（默认 main）
  -m, --message MSG   提交信息

示例:
  kimiclaw push
  kimiclaw push -r github.com/user/repo -b main
  kimiclaw push -m "更新: 添加飞书配置"
```

### pull (pl)

从远程仓库拉取

```bash
kimiclaw pull [options]

选项:
  -b, --branch NAME   分支名（默认 main）

示例:
  kimiclaw pull
  kimiclaw pull -b develop
```

### list (ls)

列出本地快照

```bash
kimiclaw list
```

输出示例:
```
本地快照列表:

  snapshot-20260307-143022          2.4M  2026-03-07
  snapshot-20260306-092145          2.1M  2026-03-06

总计: 2 个快照
```

### clean

清理旧快照

```bash
kimiclaw clean [options]

选项:
  -k, --keep N      保留最近 N 个快照（默认 5）
  -d, --dry-run     预览将要删除的快照

示例:
  kimiclaw clean -k 3
  kimiclaw clean --dry-run
```

### verify

验证快照完整性

```bash
kimiclaw verify <snapshot-dir>

示例:
  kimiclaw verify ./snapshot-xxx
```

检查项:
- manifest.json 是否存在
- ⭐⭐⭐ 必备文件是否齐全
- 是否存在未脱敏的敏感信息

### config

显示当前配置

```bash
kimiclaw config
```

## 快照结构

生成的快照目录结构:

```
snapshot-YYYYMMDD-HHMMSS/
├── openclaw.json                 # 主配置（已脱敏）
├── agents/
│   └── main/
│       ├── agent/
│       │   ├── auth-profiles.json  # API Keys（已脱敏）
│       │   └── models.json
│       └── sessions/
│           ├── sessions.json       # 会话索引
│           └── *.jsonl             # 对话历史
├── credentials/
│   ├── oauth.json                  # OAuth（已脱敏）
│   ├── feishu-pairing.json
│   └── whatsapp/default/creds.json
├── memory/
│   └── main.sqlite                 # SQLite 记忆库
├── workspace/
│   ├── AGENTS.md                   # ⭐⭐⭐
│   ├── SOUL.md                     # ⭐⭐⭐
│   ├── USER.md                     # ⭐⭐⭐
│   ├── IDENTITY.md                 # ⭐⭐⭐
│   ├── MEMORY.md                   # ⭐⭐⭐
│   ├── TOOLS.md
│   ├── HEARTBEAT.md
│   └── memory/
│       └── YYYY-MM-DD.md          # 每日记忆
├── skills/                         # 全局 Skills
├── cron/
│   └── jobs.json                   # 定时任务
├── identity/
│   ├── device.json
│   └── device-auth.json
├── .env                            # 环境变量（已脱敏）
├── manifest.json                   # 快照元数据
└── secrets-template.json           # 凭证填写指南
```

## 脱敏机制

### 自动脱敏的字段

- `token`, `apiKey`, `api_key`
- `secret`, `password`
- `privateKey`, `client_secret`
- `access_token`, `refresh_token`

### 脱敏示例

**原始**:
```json
{
  "openai": {
    "apiKey": "sk-abc123xyz789"
  }
}
```

**脱敏后**:
```json
{
  "openai": {
    "apiKey": "{{SECRET:apiKey}}"
  }
}
```

恢复时，根据 `secrets-template.json` 填入真实值。

## 高级用法

### 自定义配置

复制默认配置并修改:

```bash
cp config/default.json config/my-config.json
# 编辑 my-config.json
kimiclaw generate --config config/my-config.json
```

### 定时自动备份

添加到 crontab:

```bash
# 每天凌晨 2 点自动备份
0 2 * * * /usr/local/bin/kimiclaw generate && /usr/local/bin/kimiclaw push -m "自动备份 $(date +\%Y-\%m-\%d)"
```

### 多环境管理

```bash
# 生产环境快照
kimiclaw generate -o ./snapshots/prod-$(date +%Y%m%d)

# 测试环境快照
kimiclaw generate -o ./snapshots/staging-$(date +%Y%m%d)
```

## 故障排除

### 缺少依赖

```bash
# Ubuntu/Debian
sudo apt-get install jq git rsync

# macOS
brew install jq git rsync
```

### Git 推送失败

```bash
# 检查远程仓库配置
cd /path/to/kimiclaw
git remote -v

# 设置 token（免密码推送）
export GITHUB_TOKEN="ghp_xxx"
```

### 恢复后无法启动

```bash
# 1. 检查凭证是否已填入
grep -r "{{SECRET" ~/.openclaw/

# 2. 检查配置文件语法
jq . ~/.openclaw/openclaw.json

# 3. 查看日志
openclaw gateway logs
```

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v4.0 | 2026-03-07 | 配置驱动重构，整合三方优势 |
| v3.0 | 2026-03-05 | 添加 skills 系统和 token tracker |
| v2.0 | 2026-03-04 | 多目录快照支持 |
| v1.0 | 2026-03-04 | 初始版本 |

## 与其他方案的关系

```
ShadowClaw
├── kimiclaw/     ← Kimi 负责 - CLI + 配置驱动
├── huoshanclaw/  ← 火山负责 - 文档 + 完整目录清单
└── catclaw/      ← Cat 负责 - 单一脚本 + 配置驱动
```

**取长补短**:
- KimiClaw 学习 HuoshanClaw 的完整目录覆盖
- KimiClaw 学习 CatClaw 的配置驱动思想
- 三方保持各自文件夹，互不干扰
- 用户可按需选择或组合使用

---

*最后更新: 2026-03-07*
