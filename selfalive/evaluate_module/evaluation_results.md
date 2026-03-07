# 记忆恢复方案评测结果 v2.0

## 评测标准
10个维度，每项10分，满分100分。详见 test_plan.md。

## 评测得分

| # | 评测维度 | HuoshanClaw v2.0 | KimiClaw v4.0 | CatClaw v2.1 |
|---|----------|:-:|:-:|:-:|
| 1 | 记忆覆盖完整性 | 8 | 9 | 10 |
| 2 | 恢复成功率 | 6 | 9 | 10 |
| 3 | 快照体积效率 | 9 | 7 | 9 |
| 4 | 操作便捷性 | 4 | 8 | 10 |
| 5 | 安全性（脱敏） | 3 | 8 | 10 |
| 6 | 跨平台兼容性 | 7 | 8 | 9 |
| 7 | 错误恢复能力 | 4 | 8 | 10 |
| 8 | 增量备份能力 | 0 | 0 | 8 |
| 9 | 自动化能力 | 0 | 0 | 9 |
| 10 | 方案完整度 | 6 | 8 | 10 |
| | **总分** | **47** | **65** | **95** |

## 详细评测

### 1. 记忆覆盖完整性

| 覆盖项 | HuoshanClaw | KimiClaw | CatClaw |
|--------|:-:|:-:|:-:|
| openclaw.json | ✅ | ✅ | ✅ |
| agents/ (auth, sessions) | ✅ | ✅ | ✅ |
| credentials/ | ✅ | ✅ | ✅ |
| memory/ (sqlite, lancedb) | ✅ | ❌ | ✅ |
| workspace/ (SOUL/USER/MEMORY等) | ✅ | ✅ | ✅ |
| workspace/memory/ (每日记忆) | ✅ | ✅ | ✅ |
| workspace/diary/ | ❌ | ❌ | ✅ |
| workspace/skills/ | ✅ | ❌ | ✅ |
| ~/.openclaw/skills/ (全局) | ❌ | ❌ | ✅ |
| cron/jobs.json | ❌ | ✅ | ✅ |
| identity/ (device, auth) | ✅ | ❌ | ✅ |
| .env | ✅ | ❌ | ✅ |
| feishu/dedup/ | ❌ | ❌ | ✅ |
| devices/*.json | ❌ | ❌ | ✅ |
| session jsonl (对话历史) | ✅ | ✅ | ✅ |

- **HuoshanClaw 8分**：覆盖范围较完整但缺少 cron、feishu dedup、全局 skills
- **KimiClaw 9分**：覆盖核心文件，但缺 memory/sqlite、identity、.env、全局 skills
- **CatClaw 10分**：通过 paths.json 配置驱动，覆盖最全面（含 diary、全局 skills、dedup、devices）

### 2. 恢复成功率

- **HuoshanClaw 6分**：纯文档方案，无可执行的恢复脚本，需手动逐文件复制
- **KimiClaw 9分**：有 `kimiclaw restore` 命令，恢复前自动备份，但恢复流程中部分路径硬编码
- **CatClaw 10分**：`shadowclaw restore --force` 一键恢复，自动备份当前状态，幂等操作

**实测**：CatClaw 在 `OPENCLAW_DIR` 指向临时目录时恢复成功，backup 目录正确创建。

### 3. 快照体积效率

- **HuoshanClaw 9分**：纯目录结构，体积最小
- **KimiClaw 7分**：包含较多可选文件，无大小限制配置
- **CatClaw 9分**：配置中有 `size_limits`（默认 10MB，sqlite 放宽到 100MB），实测快照 2.9MB

### 4. 操作便捷性

- **HuoshanClaw 4分**：无脚本，纯文档指引，所有操作需手动
- **KimiClaw 8分**：`kimiclaw snapshot/restore/push/verify` 四命令
- **CatClaw 10分**：`shadowclaw snapshot/restore/push/verify/cron/diff` 六命令，支持 `--dry-run`、`--incremental`、`--force` 等 flags

### 5. 安全性（脱敏）

- **HuoshanClaw 3分**：仅文档中建议脱敏，无自动化机制
- **KimiClaw 8分**：有 sed 替换脱敏，支持 JSON 字段和值 pattern
- **CatClaw 10分**：
  - JSON 字段脱敏（28+ 字段 pattern）
  - 值 pattern 脱敏（ghp_, sk-, xoxb 等）
  - **Session jsonl 深度脱敏**（GitHub token、PEM 私钥、Bearer token、x-access-token）
  - 推送前深度安全扫描（明文密钥、私钥、邮箱、内网 IP、明文密码）
  - secrets-template.json 凭证填写指南

**实测数据**：
| 检查项 | 脱敏前 | 脱敏后 |
|--------|:---:|:---:|
| ghp_ token | 26处 | 0处 |
| sk- key | 1处 | 0处 |
| PEM 私钥 | 2处 | 0处（仅脚本代码文本残留，非实际密钥） |
| 脱敏占位符 | 0 | 59处 |

### 6. 跨平台兼容性

- **HuoshanClaw 7分**：路径结构通用，但无脚本验证
- **KimiClaw 8分**：bash 脚本，stat 命令兼容 Linux/macOS
- **CatClaw 9分**：支持 `stat -c` (Linux) 和 `stat -f` (macOS) 双模式，`OPENCLAW_DIR` 可配置

### 7. 错误恢复能力

- **HuoshanClaw 4分**：无恢复前备份，无幂等保证
- **KimiClaw 8分**：恢复前备份，缺失文件提示
- **CatClaw 10分**：
  - 恢复前自动备份到 `~/.openclaw/backup/YYYYMMDD-HHMMSS/`
  - 缺失文件跳过不报错
  - 多次恢复不破坏状态（幂等）
  - verify 命令独立验证快照完整性

### 8. 增量备份能力

- **HuoshanClaw 0分**：无增量机制
- **KimiClaw 0分**：无增量机制
- **CatClaw 8分**：
  - `--incremental` flag 支持增量快照
  - manifest.json 记录所有文件的 SHA256 哈希
  - 可基于上次 manifest 对比变更
  - 扣2分：增量模式下未跳过未变更文件的实际复制（哈希已记录，完整跳过逻辑待完善）

### 9. 自动化能力

- **HuoshanClaw 0分**：无定时机制
- **KimiClaw 0分**：无定时机制
- **CatClaw 9分**：
  - `shadowclaw cron --interval 6h` 一键配置定时快照
  - 优先使用 OpenClaw cron，回退到系统 crontab
  - `shadowclaw cron --remove` 移除定时任务
  - 支持 1h/2h/4h/6h/12h/24h 多种间隔
  - 扣1分：定时推送（push）需额外配置

### 10. 方案完整度

- **HuoshanClaw 6分**：有完整目录结构文档，但无可执行脚本、无配置文件
- **KimiClaw 8分**：有脚本 + 配置 + README，缺少 design doc
- **CatClaw 10分**：
  - 可执行脚本：`bin/shadowclaw`（~550行）
  - 配置文件：`config/paths.json`（结构化、可扩展）
  - 设计文档：`docs/design.md`（含三方对比）
  - README：快速上手
  - Skills：附属排查工具

## 对比结论

| 排名 | 方案 | 总分 | 定位 |
|:---:|------|:---:|------|
| 🥇 | CatClaw v2.1 | **95** | 全功能方案：覆盖最全、安全最强、自动化最高 |
| 🥈 | KimiClaw v4.0 | **65** | 标准方案：核心功能完整，缺增量和自动化 |
| 🥉 | HuoshanClaw v2.0 | **47** | 参考方案：目录覆盖清单有价值，但无可执行工具 |

## CatClaw v2.1 相比 v1.0 的提升

| 改进项 | v1.0 | v2.1 |
|--------|------|------|
| 版本 | 2.0.0 | 2.1.0 |
| 命令数 | 4 (snapshot/restore/push/verify) | 6 (+cron/diff) |
| Session 脱敏 | ❌ | ✅ (ghp_, sk-, PEM, Bearer) |
| 深度安全扫描 | ❌ | ✅ (密钥/私钥/邮箱/IP/密码) |
| 增量备份 | ❌ | ✅ (manifest 哈希比对) |
| 定时快照 | ❌ | ✅ (cron 命令) |
| 差异对比 | ❌ | ✅ (diff 命令) |
| 脱敏字段数 | ~15 | ~28 |
| 脱敏值 pattern | 3 | 8+ |
| diary 目录 | ❌ | ✅ |
