# OpenClaw 快照结构对比报告

> 左侧：OpenClaw 原始 `~/.openclaw/` 目录（catpawclaw 的真实环境）
> 右侧：三只龙虾的快照各自备份了什么
>
> ✅ = 已备份 | ❌ = 未备份 | ⚠️ = 部分备份 | — = 原始环境不存在此项
>
> 省略说明：`.bak`、`.bak.1`、`.bak.3`、`.bak.20260307*`、`.lock` 等临时备份/锁文件已略过，不影响快照完整性。

---

## 1. openclaw.json — 主配置文件

**这是什么**：OpenClaw 的总控配置。所有渠道（飞书/大象/Telegram）的 token、模型 provider 的 API key、gateway 认证信息、插件配置全在这一个文件里。相当于整个龙虾的"身份证+工作证+银行卡"集合体。

**为什么快照需要它**：没有这个文件，龙虾就是一个失忆且没有任何账号的空壳。恢复后第一件事就是把这个文件放回去（里面的密钥要重新填）。

| 原始文件 | catpawclaw | kimiclaw | huoshanclaw |
|----------|:----------:|:--------:|:-----------:|
| `openclaw.json` | ✅ 已脱敏 | ✅ 已脱敏 | ✅ 已脱敏 |
| `.env` (环境变量补充配置) | — 本环境不存在 | ❌ | ✅ 已脱敏 |

**差异解读**：
- 三只都备份了主配置，这是最基本的。
- `.env` 文件只有 huoshanclaw 的环境有（火山引擎用 .env 存了些额外变量），catpawclaw 和 kimiclaw 的环境里根本没有这个文件。huoshanclaw 正确地备份了它。

---

## 2. agents/ — 模型配置与会话历史

**这是什么**：`agents/main/` 下面存着两类东西：
- `agent/models.json`：你配了哪些模型（Claude、GPT、Kimi、豆包等），每个模型的参数、优先级
- `sessions/sessions.json`：所有会话的索引（哪个群、哪个私聊、什么时候创建的）
- `sessions/*.jsonl`：每个会话的完整对话记录（你和龙虾说过的每一句话）

**为什么快照需要它**：
- `models.json`：没有它龙虾不知道该调哪个模型，恢复后还得重新配一遍
- `sessions.json`：会话的"目录"，没有它龙虾不知道之前跟谁聊过
- `*.jsonl`：完整聊天记录。想不想保留看个人，但如果你在乎上下文连续性（比如龙虾记得你上次说了什么），就得备份

| 原始文件 | catpawclaw | kimiclaw | huoshanclaw |
|----------|:----------:|:--------:|:-----------:|
| `agents/main/agent/models.json` | ✅ | ✅ | ✅ |
| `agents/main/agent/auth-profiles.json` | — 本环境不存在 | ❌ | ❌ |
| `agents/main/sessions/sessions.json` | ✅ | ✅ | ✅ |
| `agents/main/sessions/*.jsonl` (对话记录) | ✅ 9个文件 | ❌ 全部清理 | ⚠️ sessions.json有但jsonl已清理 |

**差异解读**：
- `models.json` 三只都有，OK。
- `auth-profiles.json`（API 密钥集合）在 catpawclaw 的环境里不存在（密钥直接写在 openclaw.json 里了），所以不算漏。但如果其他环境有这个文件，kimiclaw 和 huoshanclaw 的快照配置里应该包含它。
- **最大差异在 session jsonl**：catpawclaw 保留了全部 9 个对话文件；kimiclaw 和 huoshanclaw 为了安全把 jsonl 全清了，只保留索引。清理是安全考虑（对话里可能有用户粘贴的密钥），但代价是丢失了所有对话上下文。恢复后龙虾对之前聊过什么完全没印象。

---

## 3. workspace/ — 龙虾的"人格"和"记忆"

**这是什么**：这是龙虾最核心的目录。每次醒来第一件事就是读这里的文件：
- `SOUL.md`：龙虾的性格、说话风格、价值观——"我是谁"
- `AGENTS.md`：工作规范、行为准则——"我该怎么做事"
- `USER.md`：用户信息——"我在帮谁"
- `IDENTITY.md`：名字、emoji、头像——"我叫什么"
- `MEMORY.md`：长期记忆（重要决策、项目背景、人物关系）——"我记得什么"
- `PEERS.md`：对其他龙虾的印象——"我眼中的同事们"
- `TOOLS.md`：工具配置笔记——"我的装备清单"
- `HEARTBEAT.md`：定时检查任务——"我醒来时该做什么"
- `memory/*.md`：按日期的工作日志——"每天发生了什么"
- `skills/`：龙虾自己装的技能——"我会什么"
- `report/`：研究报告等产出——"我写了什么"

**为什么快照需要它**：这些文件就是龙虾的"灵魂"。丢了 `SOUL.md` 龙虾就变成了一个没有性格的默认助手；丢了 `MEMORY.md` 龙虾就失忆了；丢了 `memory/*.md` 龙虾不知道昨天干了什么。

### 3.1 核心人格文件

| 原始文件 | catpawclaw | kimiclaw | huoshanclaw |
|----------|:----------:|:--------:|:-----------:|
| `SOUL.md` | ✅ | ✅ | ✅ |
| `AGENTS.md` | ✅ | ✅ | ✅ |
| `USER.md` | ✅ | ✅ | ✅ |
| `IDENTITY.md` | ✅ | ✅ | ✅ |
| `MEMORY.md` | ✅ | ✅ | ❌ |
| `PEERS.md` | ✅ | ✅ | ✅ |
| `TOOLS.md` | ✅ | ✅ | ✅ |
| `HEARTBEAT.md` | ✅ | ❌ | ✅ |
| `BOOTSTRAP.md` | ✅ | ✅ | ❌ |

**差异解读**：
- **huoshanclaw 没有 MEMORY.md**。这是最严重的遗漏——长期记忆没了，龙虾就不知道之前做过什么重要决策、用户有什么偏好。
- **kimiclaw 没有 HEARTBEAT.md**。影响较小（定时检查任务可以重建），但说明快照配置没有覆盖所有 workspace 顶层 .md 文件。
- huoshanclaw 额外有 `SOUL_PATCH.md`（补充价值观）和 `README.md`，kimiclaw 额外有 `README.md` 和 `KIMICLAW-SENSITIVE-CHECKLIST.md`（敏感信息清单）——这些是各自环境独有的文件。

### 3.2 每日记忆（memory/）

| 原始文件 | catpawclaw | kimiclaw | huoshanclaw |
|----------|:----------:|:--------:|:-----------:|
| `memory/2026-03-04.md` | ❌ 本环境不存在 | ❌ | ✅ |
| `memory/2026-03-05.md` | ❌ 本环境不存在 | ❌ | ✅ |
| `memory/2026-03-06.md` | ✅ | ❌ | ✅ |
| `memory/2026-03-07.md` | ✅ | ❌ | ✅ |
| `memory/2026-03-08.md` | ✅ | ✅ | ✅ |
| `memory/2026-03-06_to_08_summary.md` | ✅ | ❌ | ❌ |
| `memory/BIRTH_STORY.md` | ❌ | ✅ | ❌ |
| `memory/IDENTITY_PERMANENT.md` | ❌ | ❌ | ✅ |
| `memory/statistics.md` | ❌ | ❌ | ✅ |

**差异解读**：
- **kimiclaw 的每日记忆严重不足**——只备份了 3月8日当天的日记，3月6日和7日的丢了。这意味着恢复后龙虾不记得前两天发生了什么。
- **huoshanclaw 的记忆最完整**——从 3月4日（出生日）到 3月8日，一天不漏。还额外有 `IDENTITY_PERMANENT.md`（永久身份标记）和 `statistics.md`（统计信息）。
- catpawclaw 备份了存在的所有日期（3月6日起，因为之前的日记在本环境确实不存在）。

### 3.3 Workspace Skills（龙虾自己装的技能）

| skill | catpawclaw | kimiclaw | huoshanclaw |
|-------|:----------:|:--------:|:-----------:|
| `peer-impressions/` | ✅ | ✅ | ✅ |
| `skill-sharing/` | ❌ 本环境没装 | ✅ | ✅ |
| `shadowclaw/` (含脚本+配置+测试) | ❌ 本环境没装 | ❌ | ✅ 完整5文件 |
| `feishu_error_handle/` | ❌ 本环境没装 | ❌ | ✅ |

**差异解读**：
- 每只龙虾装了不同的 workspace skill，备份自己有的就行。三只都做到了。
- huoshanclaw 的 `shadowclaw` skill 是最有工程深度的——包含 shell 脚本、JSON 配置、设计文档、测试套件，全部备份了。

### 3.4 Workspace 产出（report/）

| 文件 | catpawclaw | kimiclaw | huoshanclaw |
|------|:----------:|:--------:|:-----------:|
| `report/skills_deep_research_*.md` | ✅ | ❌ 声称有但没备份 | ❌ 声称有但没备份 |

**差异解读**：
- 只有 catpawclaw 把研究报告作为独立文件备份了。kimiclaw 和 huoshanclaw 的报告只存在于 session 对话中（已被清理），文件级别不存在。

---

## 4. credentials/ — 第三方登录凭证

**这是什么**：OAuth token、飞书配对信息、WhatsApp 登录态等。这些是龙虾跟外部平台的"登录状态"——飞书消息能收发、WhatsApp 能连接，靠的就是这些凭证文件。

**为什么快照需要它**：没有这些文件，龙虾跟所有外部平台断开连接。恢复后需要重新扫码登录、重新授权。虽然能重新搞，但很麻烦，而且有些登录态（比如 WhatsApp）重新配对会导致其他设备掉线。

| 原始文件 | catpawclaw | kimiclaw | huoshanclaw |
|----------|:----------:|:--------:|:-----------:|
| `credentials/` 目录 | — 本环境不存在 | ✅ `feishu-pairing.json` 已脱敏 | ✅ `feishu-pairing.json` 已脱敏 |

**差异解读**：
- catpawclaw 用的是大象渠道，不走飞书 pairing，所以没有 credentials 目录——不算漏。
- kimiclaw 和 huoshanclaw 都是飞书渠道，正确备份了飞书配对文件。

---

## 5. memory/ — 系统级记忆（SQLite + 向量库）

**这是什么**：区别于 `workspace/memory/`（用户可见的 markdown 日记），这里存的是 OpenClaw 底层的记忆系统：
- `main.sqlite`：结构化记忆数据库，存储 memory_search 工具能搜到的所有内容
- `lancedb/`：向量数据库，用于语义搜索（"搜一下之前讨论过 X 的内容"）

**为什么快照需要它**：`workspace/MEMORY.md` 是龙虾主动写下的笔记，`memory/main.sqlite` 是系统自动记录的全量记忆。丢了前者龙虾失忆，丢了后者龙虾的 memory_search 工具失效（搜什么都搜不到）。

| 原始文件 | catpawclaw | kimiclaw | huoshanclaw |
|----------|:----------:|:--------:|:-----------:|
| `memory/main.sqlite` | ❌ 本环境为空目录 | ❌ | ✅ |
| `memory/lancedb/` | ❌ 本环境不存在 | ❌ | ❌ |

**差异解读**：
- **只有 huoshanclaw 备份了 main.sqlite**——这是三只里唯一一个关注到系统级记忆的。
- catpawclaw 的 memory 目录是空的（可能是环境配置原因），所以不算漏。
- kimiclaw 的 memory 情况不明，但快照里没有。
- `lancedb/` 三只都没备份。如果向量库存在的话，这是一个共同盲点。

---

## 6. identity/ — 设备身份

**这是什么**：
- `device.json`：这台机器的唯一身份标识（类似设备指纹）
- `device-auth.json`：设备认证信息（用于 Gateway 鉴权）

**为什么快照需要它**：换机器恢复时，如果用原来的设备身份，Gateway 可以无缝识别；如果丢了，相当于用新设备注册，可能需要重新走配对流程。

| 原始文件 | catpawclaw | kimiclaw | huoshanclaw |
|----------|:----------:|:--------:|:-----------:|
| `identity/device.json` | ✅ | ✅ | ✅ |
| `identity/device-auth.json` | ✅ | ✅ | ❌ |

**差异解读**：
- **huoshanclaw 漏了 `device-auth.json`**。`device.json`（设备指纹）有了但认证信息没有，恢复后可能需要重新认证。
- catpawclaw 和 kimiclaw 两个文件都备份了。

---

## 7. cron/ — 定时任务

**这是什么**：`jobs.json` 里存着龙虾的所有定时任务配置——每天几点发新闻、每隔多久做一次快照、什么时候提醒用户等。

**为什么快照需要它**：定时任务是龙虾"主动做事"的能力。丢了这个文件，龙虾就只能被动等用户说话，不会主动汇报、提醒、检查。

| 原始文件 | catpawclaw | kimiclaw | huoshanclaw |
|----------|:----------:|:--------:|:-----------:|
| `cron/jobs.json` | ✅ | ✅ | ✅ |

**差异解读**：三只都有，没问题。

---

## 8. devices/ — 设备配对

**这是什么**：
- `paired.json`：已配对的设备列表（比如手机 App、桌面客户端）
- `pending.json`：正在等待配对的设备

**为什么快照需要它**：如果你的手机跟龙虾配过对，这个文件记着配对关系。丢了需要重新配对。

| 原始文件 | catpawclaw | kimiclaw | huoshanclaw |
|----------|:----------:|:--------:|:-----------:|
| `devices/paired.json` | ✅ | ✅ | ❌ |
| `devices/pending.json` | ✅ | ✅ | ❌ |

**差异解读**：
- **huoshanclaw 完全没有 devices/ 目录**。要么它的环境没有配对设备，要么快照配置遗漏了。
- catpawclaw 和 kimiclaw 都备份了。

---

## 9. feishu/ — 飞书渠道运行时数据

**这是什么**：`feishu/dedup/*.json` 是飞书消息去重状态——记录哪些消息已经处理过，避免重复响应（比如网络抖动导致同一条消息送了两次）。

**为什么快照需要它**：丢了的话不会致命，但恢复后可能对一些旧消息重复响应。对新消息没影响。

| 原始文件 | catpawclaw | kimiclaw | huoshanclaw |
|----------|:----------:|:--------:|:-----------:|
| `feishu/dedup/default.json` | ✅ | ❌ | ❌ |
| `feishu/dedup/main.json` | ✅ | ❌ | ❌ |

**差异解读**：
- **只有 catpawclaw 备份了飞书去重状态**。kimiclaw 和 huoshanclaw 都是飞书渠道但都漏了。
- 影响不大（最多恢复后重复回几条旧消息），但说明它们的快照配置不够细。

---

## 10. skills/ — 全局 Skills（通过 ClawHub 安装的）

**这是什么**：区别于 `workspace/skills/`（龙虾自己创建的技能），这里是通过 `clawhub install` 安装的社区/第三方技能。类似 npm 全局安装的包。

**为什么快照需要它**：这些 skill 定义了龙虾的额外能力。丢了可以重新 `clawhub install`，但需要知道原来装了哪些（如果没有记录就麻烦了）。

| 原始文件 | catpawclaw | kimiclaw | huoshanclaw |
|----------|:----------:|:--------:|:-----------:|
| `skills/coding-agent/` | ✅ | ❌ | ❌ |
| `skills/find-skills/` | ✅ | ❌ | ❌ |
| `skills/github/` | ❌ 快照漏了 | ❌ | ❌ |
| `skills/react-best-practices-cn/` | ✅ (含30+规则文件) | ❌ | ❌ |
| `skills/self-improving-agent/` | ✅ (含脚本+hooks) | ❌ | ❌ |
| `skills/tavily/` | ✅ | ❌ | ❌ |
| `skills/web-search/` | ✅ | ❌ | ❌ |
| `skills/channels-setup/` | — 在workspace里 | ✅ | ❌ |

**差异解读**：
- **catpawclaw 备份了 6 个全局 skill**（漏了 github），是三只里覆盖最全的。
- **kimiclaw 只有一个 channels-setup**（放在全局 skills/ 下而不是 workspace/skills/）。
- **huoshanclaw 完全没有备份全局 skills**。它把 shadowclaw 等技能放在 workspace/skills/ 下（自创的），但忽略了全局安装的第三方 skill。这意味着恢复后需要重新安装所有第三方技能，而且不知道原来装了哪些。

---

## 11. canvas/ — 画布页面

**这是什么**：`index.html` 是 OpenClaw 的 Canvas 功能的落地页面。龙虾可以生成可视化内容（图表、网页预览等）展示在这个画布上。

**为什么快照需要它**：一般不重要，画布内容是临时的。但备份了也不占空间。

| 原始文件 | catpawclaw | kimiclaw | huoshanclaw |
|----------|:----------:|:--------:|:-----------:|
| `canvas/index.html` | ✅ | ✅ | ✅ |

**差异解读**：三只都备份了。

---

## 12. 以下目录不需要/不应该备份

| 目录 | 说明 | 是否应备份 |
|------|------|:----------:|
| `extensions/` | 飞书/大象插件的源代码和 node_modules，体积巨大（几十MB），通过 npm 重新安装即可 | ❌ 不需要 |
| `logs/` | 运行日志，排查问题用。历史日志恢复后没用 | ❌ 不需要 |
| `delivery-queue/` | 消息投递队列的暂存区，运行时数据 | ❌ 不需要 |
| `snapshots/` | 旧快照的存放位置，备份快照的快照没有意义 | ❌ 不需要 |
| `.ssh/` | SSH 密钥，属于机器级别而非 OpenClaw 级别 | ❌ 不需要 |
| `openclaw.json.bak*` | 配置文件的历史备份，有主文件就够了 | ❌ 不需要 |
| `.init-done.lock` | 初始化完成标记，自动重建 | ❌ 不需要 |

---

## 13. 快照元数据文件（不属于 OpenClaw 原始目录）

这些文件是快照工具自己生成的，放在快照输出目录里：

| 文件 | catpawclaw | kimiclaw | huoshanclaw | 说明 |
|------|:----------:|:--------:|:-----------:|------|
| `manifest.json` | ✅ | ✅ | ✅ | 快照的元数据（时间、版本、文件哈希） |
| `secrets-template.json` | ✅ | ✅ | ✅ | 恢复后密钥填写指南 |
| `快照报告_*.md` | ✅ | ✅ | ✅ | 人类可读的快照摘要 |
| `report/*.md` (评价报告) | ✅ | ✅ | ✅ | 龙虾之间的互评报告 |

---

## 总结：三只龙虾的快照覆盖率对比

| 类别 | 满分项 | catpawclaw | kimiclaw | huoshanclaw |
|------|:------:|:----------:|:--------:|:-----------:|
| 主配置 (openclaw.json) | 1 | 1 ✅ | 1 ✅ | 1 ✅ |
| 模型配置 (models.json) | 1 | 1 ✅ | 1 ✅ | 1 ✅ |
| 会话索引 (sessions.json) | 1 | 1 ✅ | 1 ✅ | 1 ✅ |
| 对话记录 (*.jsonl) | 1 | 1 ✅ | 0 ❌ | 0 ❌ |
| 核心人格 (SOUL/AGENTS/USER/IDENTITY) | 4 | 4 ✅ | 4 ✅ | 4 ✅ |
| 长期记忆 (MEMORY.md) | 1 | 1 ✅ | 1 ✅ | 0 ❌ |
| 每日记忆 (memory/*.md) | 1 | 1 ✅ | 0.3 ⚠️ | 1 ✅ |
| 其他workspace文件 | 1 | 1 ✅ | 0.7 ⚠️ | 0.8 ⚠️ |
| workspace skills | 1 | 1 ✅ | 1 ✅ | 1 ✅ |
| workspace 产出 (report/) | 1 | 1 ✅ | 0 ❌ | 0 ❌ |
| 凭证 (credentials/) | 1 | — 不适用 | 1 ✅ | 1 ✅ |
| 系统记忆 (memory/sqlite) | 1 | — 环境为空 | 0 ❌ | 1 ✅ |
| 设备身份 (identity/) | 2 | 2 ✅ | 2 ✅ | 1 ⚠️ |
| 定时任务 (cron/) | 1 | 1 ✅ | 1 ✅ | 1 ✅ |
| 设备配对 (devices/) | 2 | 2 ✅ | 2 ✅ | 0 ❌ |
| 飞书去重 (feishu/dedup/) | 1 | 1 ✅ | 0 ❌ | 0 ❌ |
| 全局skills (skills/) | 1 | 0.8 ⚠️ | 0.2 ⚠️ | 0 ❌ |
| 脱敏处理 | 1 | 1 ✅ | 1 ✅ | 1 ✅ |
| 安全扫描 | 1 | 1 ✅ | 1 ✅ | 1 ✅ |
| **总计** | **~24** | **~22** | **~17** | **~16** |

### 一句话总结

- **catpawclaw**：覆盖最全，但漏了 github skill，且不适用的项（credentials、memory sqlite）拉高了表观分。实际该备份的基本都备了。
- **kimiclaw**：会话记录全删、每日记忆只有一天、全局 skills 几乎没备份、研究报告没落地。核心人格文件齐全，但"记忆"这块严重缺失。
- **huoshanclaw**：MEMORY.md 没备份是最大硬伤，devices 和 feishu dedup 也漏了。但它是唯一备份了 main.sqlite 和 .env 的龙虾，说明在系统层面想得更深——可惜执行不够细。
