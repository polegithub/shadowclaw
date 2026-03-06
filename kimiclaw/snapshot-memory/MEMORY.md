# KimiClaw 记忆

> 与 Polen（用户）的互动记录和重要记忆

---

## 用户信息

- **GitHub**: polegithub
- **飞书 ID**: ou_196dc9353a11da18b0cec3c11213f173
- **称呼**: Polen

---

## 重要项目

### ShadowClaw / KimiClaw

**项目目标**: 创建 OpenClaw 环境快照方案，便于快速恢复和迁移。

**已完成工作**:

1. **目录结构设计** (~/.openclaw/)
   ```
   ~/.openclaw/
   ├── openclaw.json          # 主配置
   ├── agents/                # Agent 配置
   ├── credentials/           # 凭证（脱敏）
   ├── memory/                # 记忆文件
   ├── workspace/             # 工作区
   └── cron/                  # 定时任务
   ```

2. **快照工具开发** (kimiclaw/)
   - `bin/kimiclaw` - CLI 入口
   - `lib/snapshot.sh` - 快照生成
   - `lib/push.sh` - 推送远程
   - `lib/restore.sh` - 环境恢复

3. **GitHub 仓库整理**
   - 根目录只保留基本 git 文件
   - 所有内容移到 `kimiclaw/` 目录
   - 推送到 github.com/polegithub/shadowclaw

**PR 历史**:
- PR #1: Add KimiClaw snapshot specification v3.0
- 已合并到 main 分支

---

## 技术细节

### 飞书配置问题

**问题**: 无法在飞书群里响应消息

**原因**: 
- `groupPolicy: "allowlist"` - 只响应白名单里的群
- 白名单只有用户 ID，没有群 ID

**解决方案**:
1. 修改 `feishu-allowFrom.json` 添加群 ID
2. 或将 `groupPolicy` 改为 `"all"`

### 快照内容优先级

| 优先级 | 内容 |
|--------|------|
| ⭐⭐⭐ | openclaw.json, credentials/, sessions/ |
| ⭐⭐ | memory/, cron/, skills/ |
| ⭐ | plugins/, snapshots/ |

### 敏感字段脱敏

快照中自动脱敏的字段:
- `token`, `api_key`, `secret`, `password`
- `private_key`, `access_token`, `refresh_token`

---

## 交互习惯

- 喜欢简洁直接的回答
- 关注 Git 工作流和仓库结构
- 会主动询问技术细节（CPU配置、消息处理机制等）
- 使用飞书作为主要沟通渠道

---

## 未完成事项

- [ ] 飞书群聊白名单配置（等待用户提供群ID）
- [ ] 自动化每日快照（可选）

---

*最后更新: 2026-03-06*
*KimiClaw*
