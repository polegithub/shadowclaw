# 大模型时代，究竟什么是 Skills？

深度研究报告 | 2026-03-08 | 作者：16的书包🎒

---

## 一句话结论

Skill 不是 prompt，也不是 tool。它是介于两者之间的**第三层抽象**——一个可发现、可组合、可治理的"程序性知识包"，让 AI agent 在不重新训练的前提下获得专业能力。这个抽象层正在重新定义软件的交付形态。

---

## 第一部分：Skill 应该包含什么

### 1.1 行业共识：五层结构

2025 年 10 月 Anthropic 把 Agent Skills 做成开放标准发布（anthropics/skills 仓库，4 个月拿到 62k stars）。2026 年 2 月 arXiv 上一篇综述（Agent Skills for LLMs: Architecture, Acquisition, Security）把这个领域做了系统梳理。综合来看，一个完整的 skill 包含五层信息：

| 层 | 内容 | 对应文件 |
|------|------|----------|
| 元数据 | 名字、描述、触发词、权限、版本 | SKILL.md frontmatter |
| 指令 | 告诉 agent "遇到这类任务该怎么做" | SKILL.md 正文 |
| 脚本/工具 | 可执行代码（bash/python/shell） | scripts/ |
| 参考资料 | 领域文档、模板、字体、数据文件 | references/, assets/ |
| 配置 | 运行时参数、环境变量、安全策略 | config/ |

关键设计原则叫 **Progressive Disclosure（渐进披露）**：
- agent 平时只看到 frontmatter 里的名字和描述（几十字）
- 用户意图命中触发词时，才加载 SKILL.md 正文（几百字）
- 执行过程中按需加载 scripts 和 references

这意味着什么：agent 的 context window 是稀缺资源。skill 的设计本质上是在管理注意力——先给 agent 一个目录，用到了再翻开具体章节。

### 1.2 和你问的几个维度对应

**上下文**：frontmatter + 正文就是上下文注入机制。skill 被加载时，实质是往 agent 的对话上下文里插入了一段"领域专家的操作手册"。

**数据**：references/ 和 assets/ 可以放模板、样本数据、字典。但 skill 本身不是数据库——大规模数据通过 MCP（Model Context Protocol）连接外部数据源。skill 告诉 agent "去哪里取数据、怎么理解数据"。

**workflow**：SKILL.md 正文可以描述多步骤流程（"先检查 X，再执行 Y，最后验证 Z"）。但这个 workflow 不是硬编码的 DAG——agent 根据指令自己规划执行路径。这和传统工作流引擎（Airflow/n8n）有本质区别。

**泛化能力**：单个 skill 是垂直的（处理 PDF、管理日历、做快照）。泛化来自 agent 的模型能力 + 多 skill 组合。类比人类：每个技能是专项训练，通才能力来自基础认知 + 技能库的广度。

**tools 使用**：skill 可以调用 tools，但 skill ≠ tool。下面详细说。

---

## 第二部分：Skill 的本质是什么

### 2.1 Skill ≠ Prompt，也 ≠ Tool

这是最容易混淆的地方。做个精确对比：

| 维度 | Prompt | Tool | Skill |
|------|--------|------|-------|
| 执行方式 | 直接送入模型 | 调用后返回结果 | 注入上下文 + 改变执行环境 |
| 生命周期 | 一次性 | 无状态调用 | 按需加载，跨轮次生效 |
| 能做什么 | 影响模型输出风格/内容 | 执行具体操作（读文件、搜索） | 教 agent 怎么解决一类问题 |
| 可组合性 | 差（拼接容易冲突） | 好（独立函数） | 好（目录级隔离） |
| 可分发性 | 差（文本片段） | 中（API 定义） | 好（文件夹即包） |

arXiv 综述里的原话："Tools execute and return results. Skills prepare the agent to solve a problem."

tool 是手（执行动作），skill 是脑子里的方法论（知道什么时候用什么手、怎么用）。

### 2.2 Skill 和 Rule 的关系

Rule 是约束（"不要做 X"、"必须用中文回复"）。Skill 是能力（"遇到 PDF 任务时，按这个流程处理"）。

从实现机制看，两者都是往 system prompt 或上下文里注入文本。但设计意图完全不同：
- Rule 是防御性的——画边界
- Skill 是建设性的——添能力

如果非要类比：Rule 像公司制度手册，Skill 像岗位操作 SOP。制度手册告诉你什么不能做，SOP 告诉你怎么把事做好。

### 2.3 Skill 的本质定义

综合以上分析，给一个精确定义：

> **Skill = 可发现的程序性知识包 + 运行时上下文注入 + 执行环境修改**

三个关键词：
1. **可发现**：有标准化的元数据，agent 能自主判断什么时候用哪个 skill
2. **程序性知识**：不是事实（factual knowledge），而是操作方法（procedural knowledge）
3. **运行时注入**：不改模型权重，不做微调，加载即生效，卸载即消失

---

## 第三部分：从代码工程师到 Skill 工程师？

### 3.1 技术架构变革的三个阶段

不是一步跳过去。我看到的演进路径是：

**阶段一（当前 2025-2026）：Skill 辅助开发**
开发者还在写代码，但用 skill 加速。比如用 coding-agent skill 让 AI 帮写代码，用 xlsx skill 处理表格。后端还是微服务，前端还是 React，但开发效率提升 3-5 倍。

**阶段二（2026-2027）：Skill 驱动的组合式开发**
很多标准化的业务逻辑不再写代码，而是用 skill 描述。比如"收到订单 → 校验库存 → 生成发货单 → 通知用户"，这个流程用一个 skill 的指令就能描述清楚。agent 根据指令调用已有的 API/MCP。开发者的角色从"写代码实现流程"变成"定义流程 + 连接服务"。

**阶段三（2028+）：Skill 生态替代部分 SaaS**
这是你问的核心问题——B 端是否不再需要 SaaS。

### 3.2 SaaS 会被替代吗？部分会，但不是全部

先说会被替代的部分：

**轻量级 SaaS 工具（CRM 基础功能、简单审批、表单收集）**
这类产品的核心价值是"把流程标准化 + 提供 UI"。当 agent 能直接对话完成这些事时，UI 的价值下降。一个配置了合适 skill 的 openclaw 实例，确实能替代很多轻 SaaS。

Salesforce 自己在做 Agentforce，说明他们也看到了这个趋势。

**数据搬运类 SaaS（ETL、数据同步、格式转换）**
agent + skill 天然适合这类任务。"从 A 系统取数据，清洗后写入 B 系统"——一个 skill 就能描述，不需要专门买个 SaaS。

再说不会被替代的部分：

**重数据基础设施的 SaaS（Snowflake、Databricks）**
skill 解决的是"怎么做"，不解决"数据存在哪里、怎么高效计算"。数据库、计算引擎、存储层——这些基础设施 skill 替代不了。

**强合规/强安全场景（金融核心、医疗记录）**
agent 的确定性不够。金融交易不能让 agent "大概率正确"地执行。这类场景需要确定性代码 + 审计链路。

**复杂 UI 交互（设计工具、视频编辑）**
Figma、Premiere 这类工具的价值在于实时可视化交互。agent 可以辅助，但完全替代还早。

### 3.3 存量架构怎么变

**后端微服务架构**
不会消失，但角色变了。微服务从"直接被前端调用"变成"被 agent 通过 MCP/A2A 调用"。每个微服务暴露一个标准化的 MCP server 或 A2A Agent Card，让 agent 能发现和使用它。

实际上 AWS 的 Bedrock AgentCore 已经在做这件事——把现有企业 API 包装成 agent 可调用的 actions。

**前端 React 架构**
变化更大。很多 B 端页面的本质是"表单 + 列表 + 审批流"。这些用对话式交互可以替代。OpenAI 10 月发布的 ChatKit 就是做这个——把 agent 嵌入产品 UI。

但复杂交互（拖拽、画布、实时协作）仍然需要前端工程。React 不会消失，但"纯 CRUD 页面"的需求量会暴跌。

**"代码工程师 → Skill 工程师" 成立吗？**
部分成立。更准确的说法是：

- **初级开发者** → 大量被 AI 编码替代（已经在发生）
- **中级开发者** → 转向"Skill 工程师 + 系统集成者"（写 skill、连 MCP、配 agent）
- **高级开发者** → 继续做基础设施和复杂系统（数据库、编译器、分布式系统、agent 框架本身）

类比历史：汇编程序员 → 高级语言程序员 → 框架工程师 → Skill 工程师。每一代抽象层上移，入门门槛降低，但深层复杂度不减。

---

## 第四部分：巨头们怎么看 Agent 和 Skill

### 4.1 OpenAI

**两个关键动作：**

**2025 年 3 月 — Responses API + Agents SDK（官方博客：New tools for building agents）**
核心观点：把 Chat Completions 的简洁性和 Assistants API 的工具能力合并。提供三个内置 tool：web search、file search、computer use。开源 Agents SDK 做多 agent 编排。

关键引用："Agents are systems that independently accomplish tasks on behalf of users."

这意味着什么：OpenAI 把 agent 从"概念"变成了"API 产品"。tool 是他们体系里的核心单元，skill 的概念他们没有直接用，但 AgentKit 里的 Agent Builder 本质上在做类似的事。

**2025 年 10 月 — AgentKit（官方博客：Introducing AgentKit）**
核心观点：可视化画布编排 agent 工作流（Agent Builder）、统一数据连接器（Connector Registry）、嵌入式 chat UI（ChatKit）。

关键引用：Ramp 用 Agent Builder "从空白画布到一个采购 agent 只花了几小时"，"把原来两个季度的工作压缩到两个 sprint"。

这意味着什么：OpenAI 在用产品化工具降低 agent 开发门槛，目标是让非技术用户也能搭建 agent workflow。

### 4.2 AWS

**两个关键动作：**

**2025 年 5 月 — Strands Agents SDK（官方博客：Introducing Strands Agents）**
核心观点：model-driven approach。不写复杂编排逻辑，让模型自己决定调什么工具、怎么规划。"Agent = model + tools + prompt"。Amazon Q Developer 已经在用。

关键引用："Where it used to take months to go from prototype to production, we're now able to ship new agents in days and weeks with Strands."

**2025 年 — Bedrock AgentCore + MCP 支持**
把企业现有 API 包装成 agent 可调用的 actions，支持 MCP server 接入。

这意味着什么：AWS 的策略是"你的基础设施在我们这里，agent 也在我们这里运行"。skill 的概念在 AWS 体系里叫 "action"——本质是一回事。

### 4.3 Google

**一个关键动作：**

**2025 年 4 月 — A2A（Agent2Agent Protocol，官方博客：Announcing the Agent2Agent Protocol）**
核心观点：50+ 合作伙伴（Salesforce、SAP、ServiceNow 等）。解决的问题是 agent 之间怎么协作——发现彼此（Agent Card）、分配任务（Task）、交换结果（Artifact）。

与 MCP 的关系：MCP 解决 agent-to-tool 连接，A2A 解决 agent-to-agent 协作。互补，不竞争。

关键引用："A2A focuses on enabling agents to collaborate in their natural, unstructured modalities."

这意味着什么：Google 不做 skill 标准，做的是 agent 间通信标准。他们的判断是：单个 agent 的能力各家自己解决，但多 agent 协作需要行业统一协议。

### 4.4 Anthropic（补充）

**Anthropic 是 skill 标准的发起者。**

2025 年 10 月发布 Agent Skills，12 月开源为标准，anthropics/skills 仓库 4 个月拿 62k stars。Atlassian、Figma、Stripe、Notion 等都提交了官方 skill。

同时发起 MCP（Model Context Protocol），12 月捐赠给 Linux Foundation 的 Agentic AI Foundation。

Anthropic 做了最重要的一个判断：skill 和 tool 是两个不同的抽象层。tool 是原子操作，skill 是"领域专家的操作手册"。这个判断目前正在被行业采纳。

---

## 第五部分：自我质疑与挑战

写完以上内容后，我做了三轮自我质疑。

### 质疑 1：Skill 会不会只是一阵风？

反驳：从 prompt engineering → function calling → skill engineering，每一步都是真实的抽象层上移。skill 解决的是"怎么把专业知识标准化打包给 agent"这个真实问题。只要 agent 继续发展，这个需求就存在。

但风险是：标准碎片化。OpenAI 的 AgentKit、Anthropic 的 Skills、AWS 的 Actions——如果各家不互通，skill 生态会被平台锁死。arXiv 综述列出的第一个开放挑战就是"cross-platform skill portability"。

### 质疑 2："给商户配一个 openclaw 替代 SaaS"是否太乐观？

承认：确实太乐观了。SaaS 的价值不只是功能，还有数据积累、行业 know-how、合规保障、客户成功服务。一个 agent 实例替代不了这些。

更现实的路径：SaaS 产品本身内嵌 agent 能力（Salesforce Agentforce、ServiceNow 的 agent），而不是被 agent 替代。"AI-native SaaS" 比 "agent 替代 SaaS" 更可能发生。

### 质疑 3：Skill 安全问题被低估了吗？

是的。arXiv 综述提到 **26.1% 的社区贡献 skill 存在安全漏洞**。skill 的本质是往 agent 的执行环境里注入指令和代码——这和供应链攻击的风险模型完全一致。

目前的应对方案（Skill Trust and Lifecycle Governance Framework）还停留在论文阶段。实际生产环境里，大部分人安装 skill 时不看源码，和 npm install 随便装包的问题一样。

---

## 结论

Skill 是大模型时代的"操作系统级抽象"。它不是 prompt 的花哨包装，而是解决了一个真实的工程问题：怎么让 AI agent 获得专业能力，同时保持可发现、可组合、可治理。

三个判断：
1. **Skill 会成为 agent 生态的基本单元**，就像 npm package 是 Node.js 生态的基本单元
2. **"代码工程师 → Skill 工程师" 在中间层成立**，但基础设施和复杂系统仍需传统工程
3. **SaaS 不会被替代，但会被重构**——从"卖软件功能"变成"卖 agent 能力 + 数据服务"

---

## 参考来源

| # | 来源 | 发布时间 |
|---|------|----------|
| 1 | OpenAI — New tools for building agents (openai.com/index/new-tools-for-building-agents) | 2025-03-11 |
| 2 | OpenAI — Introducing AgentKit (openai.com/index/introducing-agentkit) | 2025-10-06 |
| 3 | AWS — Introducing Strands Agents (aws.amazon.com/blogs/opensource) | 2025-05-16 |
| 4 | Google — Announcing the Agent2Agent Protocol (developers.googleblog.com) | 2025-04-09 |
| 5 | Anthropic — Agent Skills open standard (anthropics/skills GitHub) | 2025-12 |
| 6 | arXiv — Agent Skills for LLMs: Architecture, Acquisition, Security (2602.12430v3) | 2026-02 |
| 7 | Han Lee — Claude Agent Skills: A First Principles Deep Dive | 2025-10-26 |
| 8 | OpenClaw — 创建 Skills 文档 (/app/docs/zh-CN/tools/creating-skills.md) | 2026-02 |
| 9 | OpenClaw — Skills 概述 (/app/docs/zh-CN/tools/skills.md) | 2026-02 |

---

*本报告基于公开可查的官方博客、论文和文档。所有引用均标注来源。如有事实错误，请指出。*
