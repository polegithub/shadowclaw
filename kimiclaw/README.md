# KimiClaw v4.0

> OpenClaw 环境快照管理工具 - 配置驱动、简洁高效

## 设计哲学

**取长补短，融会贯通**

KimiClaw v4.0 整合了三个方案的优势：
- **继承 KimiClaw v3** 的 CLI 设计理念和 manifest 追踪
- **借鉴 HuoshanClaw** 的完整目录覆盖清单
- **学习 CatClaw** 的配置驱动思想

## 核心特性

| 特性 | 说明 |
|------|------|
| ⚙️ 配置驱动 | `config/default.json` 统一定义所有行为 |
| 📦 完整覆盖 | 支持 ⭐⭐⭐ 必备 / ⭐⭐ 重要 / ⭐ 可选 三级优先级 |
| 🔒 自动脱敏 | 自动替换敏感字段为 `{{SECRET:xxx}}` |
| 📝 Manifest 追踪 | 每个快照附带完整元数据 |
| 🔄 安全恢复 | 恢复前自动备份，支持幂等操作 |
| ☁️ Git 集成 | 一键 push/pull 到远程仓库 |

## 目录结构

```
kimiclaw/
├── bin/
│   └── kimiclaw          # 唯一入口脚本（~500行）
├── config/
│   └── default.json      # 配置驱动核心
├── lib/                  # （可选）高级脚本扩展
├── README.md             # 快速开始
└── kimiclaw.md           # 详细文档

~/.openclaw/              # 快照目标
├── openclaw.json         # ⭐⭐⭐ 主配置
├── agents/               # ⭐⭐⭐ Agent 配置
├── credentials/          # ⭐⭐⭐ 凭证（脱敏）
├── memory/               # ⭐⭐⭐ 记忆数据库
├── workspace/            # ⭐⭐⭐ 工作区
│   ├── AGENTS.md
│   ├── SOUL.md
│   ├── USER.md
│   ├── IDENTITY.md
│   ├── MEMORY.md
│   ├── TOOLS.md
│   ├── HEARTBEAT.md
│   └── memory/
├── skills/               # ⭐⭐ 全局 Skills
├── cron/                 # ⭐⭐ 定时任务
├── identity/             # ⭐⭐ 设备身份
└── .env                  # ⭐⭐ 环境变量
```

## 快速开始

### 安装

```bash
# 添加到 PATH
export PATH="/path/to/kimiclaw/bin:$PATH"

# 或使用软链接
ln -s /path/to/kimiclaw/bin/kimiclaw /usr/local/bin/kimiclaw
```

### 生成快照

```bash
kimiclaw generate              # 默认目录
kimiclaw generate -o ./snap    # 指定目录
kimiclaw generate --dry-run    # 模拟运行
```

### 恢复快照

```bash
kimiclaw restore ./snapshot-xxx      # 交互式恢复
kimiclaw restore ./snapshot-xxx -f   # 强制恢复
```

### Git 同步

```bash
kimiclaw push                  # 推送到远程
kimiclaw push -m "更新说明"    # 自定义提交信息
kimiclaw pull                  # 从远程拉取
```

### 其他命令

```bash
kimiclaw list                  # 列出快照
kimiclaw clean -k 5            # 保留5个最新快照
kimiclaw verify ./snapshot-xxx # 验证快照完整性
kimiclaw config                # 查看配置
```

## 文件优先级

| 优先级 | 标记 | 说明 | 示例 |
|--------|------|------|------|
| ⭐⭐⭐ | 必备 | 丢失后无法恢复 | openclaw.json, auth-profiles.json, SOUL.md |
| ⭐⭐ | 重要 | 丢失后可重建但耗时 | models.json, skills/, cron/jobs.json |
| ⭐ | 可选 | 可自动重建 | logs/, node_modules/ |

完整配置见 `config/default.json`

## 对比其他方案

| 维度 | KimiClaw v4.0 | HuoshanClaw | CatClaw |
|------|:-------------:|:-----------:|:-------:|
| 可执行脚本 | ✅ CLI | ❌ 文档 | ✅ CLI |
| 目录覆盖 | ✅ 完整 | ✅ 最完整 | ✅ 较完整 |
| 脱敏机制 | ✅ 自动 | ❌ 手动 | ✅ 自动 |
| Manifest | ✅ | ❌ | ✅ |
| 配置驱动 | ✅ | ❌ | ✅ |
| 代码简洁 | ✅ 极简 | ✅ 清晰 | ✅ 简洁 |
| 文件数量 | ~5 个 | ~3 个 | ~4 个 |

## 许可证

MIT

---

*KimiClaw - 守护你的 OpenClaw 配置*
