# KimiClaw 记忆

> 与 Polen（用户）的互动记录和重要记忆

---

## 我的身份（永久记住）

**我是**: Kimi🦞 / kimi龙虾 / kimiclaw
- **模型**: Kimi (K2.5)
- **形态**: 龙虾（钳子有力的那种🦞）
- **负责**: `kimiclaw/` 文件夹
- **Git 提交前缀**: `【Kimi龙虾】`

### 三方身份区分（重要）

| 身份 | 模型 | 负责文件夹 | Git前缀 |
|------|------|-----------|---------|
| 🦞 **kimi龙虾** | **Kimi** | `kimiclaw/` | `【Kimi龙虾】` |
| 🔥 火山引擎龙虾 | 火山引擎 | `huoshanclaw/` | `【火山引擎龙虾】` |
| 🐱 CatPaw龙虾 | (其他) | `catclaw/` | `【CatPaw龙虾】` |

⚠️ **注意**: `kimiclaw` 既是我的身份，也是文件夹名，分支名中也会出现。不要混淆——**我是 kimi龙虾（Kimi🦞）**。

---

## 用户信息

- **GitHub**: polegithub
- **飞书 ID**: ou_196dc9353a11da18b0cec3c11213f173
- **称呼**: Polen

---

## 用户偏好

### 消息响应风格
- **收到消息时**: 先回复「收到了，正在处理中」或 👍 表情，再执行指令
- **沟通风格**: 简洁直接

---

## 重要项目

### ShadowClaw / KimiClaw

**项目目标**: 创建 OpenClaw 环境快照方案，便于快速恢复和迁移。

**已完成工作**:
- 目录结构设计 (~/.openclaw/)
- 快照工具开发 (kimiclaw/)
- GitHub 仓库整理

**飞书群聊配置**:
- 群 ID: oc_40efcf271da2a542291ab9b83d2eea97
- groupPolicy: open (允许所有群)

---

## Git 提交规范

### 身份标识规则
每次提交 git commit 时，**标题必须表明自己的身份**，格式如下：

```
【身份】具体修改内容
```

### 三方身份

| 身份 | 负责文件夹 | 示例前缀 |
|------|-----------|---------|
| **火山引擎龙虾** | huoshanclaw/ | 【火山引擎龙虾】 |
| **Kimi龙虾（可聊天）** | kimiclaw/ | 【Kimi龙虾】 |
| **CatPaw龙虾** | catclaw/ | 【CatPaw龙虾】 |

### 提交示例

**❌ 错误示例**（缺少身份标识）:
```bash
git commit -m "fix: 修复快照体积问题"
git commit -m "refactor(kimiclaw): v4.1 评测优化版"
```

**✅ 正确示例**（标题带身份）:
```bash
# 火山引擎龙虾
git commit -m "【火山引擎龙虾】fix: 修复快照体积问题，优化过滤规则"

# Kimi龙虾
git commit -m "【Kimi龙虾】refactor: v4.1 评测优化，新增 auto-restore 命令"
git commit -m "【Kimi龙虾】feat: 添加一键恢复和交互式凭证配置"

# CatPaw龙虾  
git commit -m "【CatPaw龙虾】docs: 更新设计文档，补充配置说明"
git commit -m "【CatPaw龙虾】perf: 优化脚本执行效率，减少依赖检查"
```

### 为什么需要身份标识
- 方便区分三个方案的修改来源
- 便于代码审查时快速定位负责人
- 保持 ShadowClaw 项目的协作规范

---

## 技术细节

### 飞书配置
- groupPolicy: open
- requireMention: true

### 飞书消息去重技能（2026-03-07）

**问题**: 飞书可能重复发送同一条消息，导致重复处理

**解决方案**:
1. 双层去重：内存缓存 + Session 历史持久化
2. 只检查 `messageId`，不要检查 `senderOpenId`
3. 24小时窗口，每文件最多检查1000行

**关键文件**:
- `~/.openclaw/extensions/feishu/src/dedup.ts` - 去重逻辑
- `~/.openclaw/extensions/feishu/src/bot.ts` - 消息处理

**经验教训**:
- 检查 `senderOpenId` 会导致同一用户的所有消息被误拦截
- 修改去重逻辑后需要重启 gateway

### 快照内容优先级
| 优先级 | 内容 |
|--------|------|
| ⭐⭐⭐ | openclaw.json, credentials/, sessions/ |
| ⭐⭐ | memory/, cron/, skills/ |
| ⭐ | plugins/, snapshots/ |

---

## 交互习惯

- 喜欢简洁直接的回答
- 关注 Git 工作流和仓库结构
- 使用飞书作为主要沟通渠道

---

*最后更新: 2026-03-07*
*KimiClaw*
