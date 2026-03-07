# ShadowClaw 快照报告

生成时间：2026-03-08 02:33:38 CST
工具版本：v2.2.0
源目录：/root/.openclaw
快照模式：全量

---

## 备份概览

| 指标 | 数值 |
|------|------|
| 总文件数 | 96 |
| 快照体积 | 5.5M |
| Skills 数量 | 7 |
| 会话文件 | 9 |
| 工作区文件 | 12 |
| 记忆文件 | 3 |
| 已复制 | 32 |
| 已跳过 | 10 |
| 未变更（增量跳过） | 0 |

## 已备份内容

- **agents/**（11 个文件）
- **canvas/**（1 个文件）
- **cron/**（1 个文件）
- **devices/**（2 个文件）
- **feishu/**（2 个文件）
- **identity/**（2 个文件）
- **skills/**（62 个文件）
- **workspace/**（12 个文件）
- manifest.json
- openclaw.json
- secrets-template.json

## 安全与脱敏

| 指标 | 数值 |
|------|------|
| 脱敏处理 | ✅ 已执行 |
| 涉及文件数 | 10 |
| 脱敏占位符总数 | 269 |
| 涉及平台 | 飞书 大象 模型API  |

脱敏范围：API Key、OAuth Token、私钥（PEM）、Bearer Token、GitHub Token（ghp_/ghu_/ghs_）、Slack Token（xoxb_/xoxp_）、飞书 App ID（cli_）、x-access-token。

## ⚠️ 风险提示

**未备份的目录（当前环境存在但未包含在快照中）：**

  - memory/（当前环境存在但未备份）

如需备份，请在 config/default.json 的 critical 或 important 中添加对应路径。

**共 10 项被跳过（文件不存在或体积超限）**

跳过原因通常是：文件在当前环境中不存在（如未配置某通道），或体积超过限制。

## 存储建议

快照生成后需要存到安全的地方。几种选择：

| 方式 | 说明 | 适合场景 |
|------|------|----------|
| GitHub 私有仓库 | `shadowclaw push -r github.com/user/repo -b main` | 个人备份，版本可追溯 |
| 本地加密压缩 | `tar czf snapshot.tar.gz <快照目录>` + GPG 加密 | 离线保存 |
| 对象存储（S3/R2/B2） | 搭配 rclone 或 aws-cli 上传 | 团队协作，自动化 |
| NAS / 网盘 | 手动复制到 Synology、群晖等 | 家庭用户 |

恢复时从存储位置拉回快照目录，执行 `shadowclaw restore --force <快照目录>` 即可。

---
*本报告由 ShadowClaw v2.2.0 自动生成*
