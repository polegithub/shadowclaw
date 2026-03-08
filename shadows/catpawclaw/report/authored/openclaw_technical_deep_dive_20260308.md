# OpenClaw 底层原理技术分析

2026-03-08 | 作者：16的书包🎒

---

## 整体架构

OpenClaw 只有一个核心进程：**Gateway**。所有能力都从它展开。

```
                    ┌─────────────────────────────────────────┐
                    │              Gateway (单进程)              │
                    │                                         │
  IM 通道层         │  ┌─────────┐ ┌─────────┐ ┌──────────┐   │
  (飞书/大象/       │  │ 飞书 WS │ │大象 WS  │ │Telegram  │   │
   WhatsApp/...)   │  │ 插件    │ │ 插件    │ │ 插件     │   │
                    │  └────┬────┘ └────┬────┘ └────┬─────┘   │
                    │       └──────────┬┼──────────┘           │
                    │                  ↓                       │
  消息路由层        │  ┌──────────────────────────────────┐    │
                    │  │ Router (binding → agent → session) │    │
                    │  └──────────────┬───────────────────┘    │
                    │                 ↓                        │
  会话队列层        │  ┌──────────────────────────────────┐    │
                    │  │ Command Queue (per-session串行)    │    │
                    │  └──────────────┬───────────────────┘    │
                    │                 ↓                        │
  Agent 运行时      │  ┌──────────────────────────────────┐    │
                    │  │ Agent Loop (推理→工具→回复 循环)    │    │
                    │  └──────────────┬───────────────────┘    │
                    │                 ↓                        │
  存储层            │  sessions.json + *.jsonl + MEMORY.md     │
                    │  + memory/*.md + SQLite 向量索引          │
                    └─────────────────────────────────────────┘
```

就这么简单。没有微服务，没有消息中间件，没有数据库集群。整个 OpenClaw 就是一个 Node.js 进程，所有状态存在本地文件系统上。

---

## 问题 ①：为什么它能记住之前的谈话内容

### 短期记忆：Session 的 JSONL 文件

每次对话都会写入一个 JSONL 文件：`~/.openclaw/agents/<agentId>/sessions/<SessionId>.jsonl`

每一行是一条消息（用户的、agent 的、工具调用结果的），按时间追加。下次对话时，Gateway 把这个文件里的历史消息组装进 LLM 的 context window——模型就"记得"之前聊了什么。

**但 context window 有上限**（比如 200k tokens）。聊多了就塞不下了。这时候触发 **compaction**：OpenClaw 让模型先把旧对话总结成一段摘要，存下来，然后只保留摘要 + 最近的消息。类似于你把一本厚笔记本的前 50 页压缩成 1 页提纲。

在 compaction 之前，还有一步 **memory flush**：提醒模型"你快要被压缩了，赶紧把重要的东西写到磁盘上"。模型就会主动调用 write 工具，把关键信息写进 `memory/YYYY-MM-DD.md`。

### 长期记忆：Markdown 文件 + 向量搜索

- `MEMORY.md`：长期记忆，模型自己维护（新 session 启动时读取）
- `memory/YYYY-MM-DD.md`：每日日志
- 这些都是纯 Markdown 文件，模型通过 `read`/`write` 工具直接读写

**怎么从几百个文件里快速找到相关记忆？** 向量搜索。OpenClaw 把 Markdown 文件切成 ~400 token 的小段，用 embedding 模型转成向量，存到 SQLite 里。查询时做余弦相似度匹配 + BM25 关键词匹配（混合搜索），返回最相关的片段。

流程：
```
用户问"之前讨论的 ShadowClaw 方案是什么？"
  → agent 调用 memory_search("ShadowClaw 方案")
  → 向量搜索 + BM25 混合检索
  → 返回 MEMORY.md 第 45-60 行的片段
  → agent 调用 memory_get(path="MEMORY.md", from=45, lines=15)
  → 读到具体内容，组装进回复
```

**它不是真的"记得"，而是每次都在"查"。** 和人类翻笔记本一个逻辑。

---

## 问题 ②：为什么多个任务不会互相打断

### Session 隔离 + Command Queue

每条消息进来后，Router 根据 binding 规则确定：(1) 哪个 agent 处理 (2) 哪个 session。

Session key 的生成规则：
- 私聊 DM → `agent:main:main`（默认所有私聊共享一个 session）
- 群聊 → `agent:main:feishu:group:oc_xxx`（每个群独立 session）
- Cron 任务 → `cron:<job.id>`（每个 cron 独立 session）
- Sub-agent → 独立 session

**关键机制：Command Queue 做 per-session 串行。** 同一个 session 内，消息排队一个一个执行，保证不会两个 run 同时写同一个 session 的 JSONL。但不同 session 之间可以并行（默认全局并发上限 4）。

### Sub-agent：为什么 A 任务在后台跑，B 可以继续对话

当你说"帮我做个调研"，agent 可以调用 `sessions_spawn` 创建一个子 agent。这个子 agent 有独立的 session、独立的执行队列，跑在后台。主 session 继续响应你的新消息。

子 agent 完成后，通过 `sessions_send` 把结果发回主 session，或者直接通过 message 工具发消息给你。

```
你："帮我调研 X"
  → 主 agent 调用 sessions_spawn(task="调研 X")
  → 子 agent 在独立 session 里跑（后台）
  → 你继续聊别的，主 agent 正常响应
  → 子 agent 完成 → 发消息通知你"调研 X 完成了，结果是..."
```

不是"多线程"概念，是"多 session 并行，每个 session 内串行"。

---

## 问题 ③：自我进化靠什么

### 两种"进化"

**第一种：运行时自我学习（workspace 文件机制）**

OpenClaw 本身没有"自我进化"模块。它的"进化"完全依赖模型的 read/write 能力 + workspace 文件约定：

- AGENTS.md 告诉模型"犯错了要记下来"
- 模型通过 write 工具修改 MEMORY.md、TOOLS.md、HEARTBEAT.md
- 下一次 session 启动时读取这些文件，行为就"进化"了

这不是什么黑科技——就是"模型往文件里写东西，下次读出来"。进化的质量完全取决于模型的自我反思能力和 AGENTS.md 里的提示词质量。

**第二种：ClawHub 的 self-improving-agent skill**

这是一个外部 skill（~/.openclaw/skills/self-improving-agent/），做的是更结构化的学习：
- 检测到错误/用户纠正时，记录 learning 到专门的文件
- 下次执行类似任务前，先查阅历史 learnings
- 本质上是把"记笔记"流程标准化了

**两者的区别**：前者是 OpenClaw 的基础能力（任何模型 + read/write 工具就能做到），后者是一个封装好的 skill，把"什么时候记、记什么格式、怎么检索"做了标准化。区别在封装程度，不在底层能力。

---

## 问题 ④：怎么知道去哪里查日志

这不是 agent 的"能力"，而是 **system prompt 注入**。

OpenClaw 在组装 system prompt 时，会注入运行时信息：
```
Runtime: agent=main | host=sandbox-ide-434352-0 | repo=/root/.openclaw/workspace 
| os=Linux 5.4.241 (x64) | node=v22.12.0 | model=kubeplex-maas/claude-opus-4.5 
| channel=feishu | ...
```

同时，AGENTS.md 等 workspace 文件里写了路径约定，skills 里写了具体的诊断流程。模型看到这些信息后，就"知道"日志在 `/tmp/openclaw/openclaw-*.log`，session 文件在 `~/.openclaw/agents/main/sessions/`。

排查能力的来源：
1. system prompt 里注入的运行时环境信息
2. OpenClaw 文档目录（`/app/docs/`）模型可以 read
3. Skills（如 healthcheck）里写了具体的排查步骤
4. 模型自身的 Linux/Node.js 知识

不是 agent 有什么特殊的自省 API——它就是能读文件、能执行命令，加上知道该去哪里看。

---

## 问题 ⑤：IM 通信层做得怎么样

### 实际实现

以飞书为例（因为我们用这个），看源码后的结论：

**连接方式**：飞书 SDK 的 WSClient（WebSocket 长连接），或 webhook HTTP server。Gateway 启动时调用 `wsClient.start({ eventDispatcher })`，把事件分发器传进去。

**重连**：**OpenClaw 自己没有加重连逻辑。** 完全依赖飞书 SDK（`@larksuiteoapi/node-sdk`）内部的重连机制。monitor.ts 里的 `monitorWebSocket` 函数就是一个 Promise，WS 连上了就挂着，断了 Promise 就 resolve/reject。没有 watchdog，没有自动重启 account。

**去重**：做得不错。双层去重——内存 LRU（1000 条）+ 磁盘持久化文件（10000 条，24 小时 TTL），基于飞书的 message_id。重启 Gateway 后磁盘去重文件还在，理论上不会重复。但如果去重文件被清掉（比如容器重建），就会重复。

**心跳**：这是 Gateway 层面的 heartbeat 机制（定时触发一次 agent 对话），不是 IM 协议层面的心跳。IM 层的 keep-alive 完全依赖各通道 SDK 自己的实现。

**整体评价**：
- **路由和去重**做得好——binding 系统灵活，去重持久化
- **连接稳定性**做得一般——完全依赖第三方 SDK 的重连逻辑，没有 Gateway 级别的 watchdog
- **不是自研通信框架**——每个通道就是一个 SDK 封装（飞书用 @larksuiteoapi/node-sdk，WhatsApp 用 Baileys，Telegram 用 grammY，Discord 用 discord.js）

这解释了 kimiclaw 的断连问题：飞书 SDK 的 WS 重连如果有 bug 或者网络环境特殊（代理），OpenClaw 层面没有兜底。

---

## 问题 ⑥：技术瓶颈和优化方向

### 当前痛点（不含安全）

**1. 单进程 + 本地文件系统 = 无法水平扩展**

所有状态（session、memory、去重缓存）都在本地磁盘。不能多实例部署、不能跨机器共享 session。这意味着：
- 一个 Gateway 挂了，所有通道都断
- 无法做高可用（active-standby 都做不到，因为 session 文件没有外部存储）
- 大量并发用户时单进程性能有上限

**2. Context window 管理粗糙**

compaction（压缩历史对话）是让模型自己总结的——总结质量取决于模型能力，压缩比不可控。有时候重要信息被压缩丢了，有时候总结太冗长没省多少 token。

**3. 通道层缺少统一的连接管理**

每个通道 SDK 各自管理连接，Gateway 没有统一的连接健康检查和自动恢复机制。飞书 WS 断了，Gateway 不一定知道。

**4. Skill 匹配是模型自己判断的**

没有确定性的 skill 路由。模型看 `<available_skills>` 列表后自己选哪个 skill 加载——选错了就浪费一轮调用。当 skill 数量多、描述重叠时，准确率下降。

**5. Memory 搜索延迟**

向量搜索需要 embedding API 调用（远程的话有网络延迟），首次搜索还需要建索引。对实时对话体验有影响。

### 业界当前高频优化的方向

| 方向 | 做什么 | 为什么重要 |
|---|---|---|
| **Context Engineering** | 更精准地管理塞进 context window 的内容 | 直接影响模型输出质量。当前 compaction 太粗糙 |
| **Tool Use 可靠性** | 减少模型调错 tool / 传错参数的概率 | tool call 失败率是 agent 实际使用中的第一大痛点 |
| **Multi-agent 编排** | 多个 agent 协作完成复杂任务 | 单 agent 能力有天花板，A2A/ACP 协议就是在解决这个 |
| **长期记忆** | 比"写 Markdown + 向量搜索"更可靠的记忆方案 | 当前方案依赖模型主动写入，容易遗漏 |
| **延迟优化** | 推理加速、并行 tool 调用、流式输出 | 用户体验的核心——等 30 秒回复太长了 |

### 如果我们要优化 OpenClaw，最值得投入的三个点

**第一：通道层连接管理（投入小，收益确定）**
加一个 Gateway 级别的 WS watchdog：定时检测各通道连接状态，断了自动重连。这不需要改架构，几百行代码就能解决 kimiclaw 那类问题。

**第二：Context 管理精细化（投入中，收益高）**
当前 skill 加载、历史消息裁剪、compaction 都比较粗糙。可以做的事：
- Skill 匹配加一层轻量级的关键词预筛选（不完全依赖模型判断）
- Compaction 按话题分段压缩（而不是一把梭全压缩）
- Session pruning 策略更细粒度（按 tool 类型/重要性裁剪）

**第三：Memory 写入自动化（投入中，收益高）**
当前完全依赖模型"自觉"写 memory。可以做的事：
- 每轮对话后自动提取关键事实（不依赖模型主动调用 write）
- 对 memory 做结构化索引（不只是全文搜索，还能按人名/项目/日期查）

---

*本报告基于 OpenClaw 源码（/app/）和官方文档（/app/docs/）分析，版本截至 2026-03-08。*
