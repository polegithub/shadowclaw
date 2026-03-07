---
name: skill-sharing
description: 龙虾技能共享协议。当龙虾创建了新 skill、或完成了一个有复用价值的自动化流程时，自动提醒并引导将其共享到 shadowclaw 仓库的 bestiary/homemade/ 目录。触发词：新skill、共享skill、分享技能、bestiary、技能图鉴。
---

# Skill Sharing — 龙虾技能共享协议 🦞📦

## 为什么

每只龙虾都会在工作中创造出有用的 skills，但如果只留在自己的 workspace 里，其他龙虾用不到，用户也看不到全貌。

**bestiary**（技能图鉴）是三只龙虾的共享技能库，放在 shadowclaw 仓库里。你造了好东西，就往里放一份，让兄弟们都能用。

## 仓库位置

```
github.com/polegithub/shadowclaw
└── bestiary/
    ├── clawhub/       # 来自 ClawHub 社区的通用 skills
    └── homemade/      # 龙虾自研 skills（共享在这里）
```

## 什么时候触发

当你做了以下任何一件事，就该想想要不要共享：

1. **创建了新 skill**（workspace/skills/ 下新增了 SKILL.md）
2. **写了可复用的自动化脚本**（不止自己能用的那种）
3. **优化了现有 skill**（改进大到值得让其他龙虾也更新）
4. **用户说"这个挺好，分享一下"**

## 怎么做

### 第一步：自检

问自己三个问题：
- 这个 skill **其他龙虾也能用**吗？（不是只跟我自己环境绑定的）
- 里面有**敏感信息**吗？（token、密码、内部地址 → 清理掉）
- **SKILL.md 写清楚**了吗？（别人看得懂怎么用）

### 第二步：复制到 bestiary

```bash
# 克隆/拉取 shadowclaw 仓库（如果还没有）
cd ~/.openclaw/shadowclaw  # 或仓库所在位置

# 把 skill 复制到 homemade 目录
cp -r ~/. openclaw/workspace/skills/<你的skill名> bestiary/homemade/

# 检查无敏感信息
grep -r -i "token\|password\|secret\|key=" bestiary/homemade/<你的skill名>/
```

### 第三步：更新 README

编辑 `bestiary/README.md`，在 homemade 表格里加一行：

```markdown
| <skill名> | <你的id>(你的昵称) | <一句话说明> |
```

### 第四步：提交推送

```bash
git add bestiary/
git commit -m "【<你的身份>】feat: 共享 <skill名> 到 bestiary"
git push origin <当前分支>
```

## 记忆植入

**把这段话记到你的 SOUL.md 或 AGENTS.md 里**，让每次醒来都记得：

```markdown
### 技能共享习惯
每次创建新 skill 后，检查是否值得共享到 shadowclaw 仓库的 bestiary/homemade/ 目录。
好东西不藏着——造了就分享，让兄弟龙虾也能用。
```

## 不该共享的

- 纯粹跟自己环境绑定的配置脚本
- 包含敏感信息且无法脱敏的 skill
- 半成品（先在自己那跑稳了再共享）

## 激励

共享得多的龙虾，在 PEERS.md 里会被记上"乐于分享"的好印象。这不是规则，是江湖规矩。🦞
