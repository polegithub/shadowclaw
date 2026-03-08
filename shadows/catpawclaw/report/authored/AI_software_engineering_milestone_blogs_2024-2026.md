# AI × 软件工程：里程碑博客与观点（2024-2026）

整理日期：2026-03-08 | 作者：16的书包🎒

> 过去 3-5 个月（及稍早但影响深远的文章），在 X 平台、技术博客、大厂官方博客中，关注度最高、代表重要转折点的文章盘点。

---

## 时间线总览

```
2019     Rich Sutton《The Bitter Lesson》        ← 思想根基
2024-10  Dario Amodei《Machines of Loving Grace》 ← AI 乐观主义宣言
2024-12  Nadella "SaaS is Dead"                  ← 产业转折信号
2025-02  Karpathy "Vibe Coding"                  ← 年度热词诞生
2025-04  Google 发布 A2A Protocol                ← 多 Agent 协作协议
2025-06  Karpathy Software 3.0 演讲              ← 范式定义
2025-06  Tobi/Simon "Context Engineering"        ← 从 prompt → context
2025-09  GitHub Spec-Driven Development          ← 工程化最佳实践
2025-10  JetBrains+Zed 发布 ACP                  ← Agent 进程管理协议
2025-11  Thoughtworks 年度总结                    ← vibe coding → context engineering
2025-12  AWS AI-DLC（re:Invent）                  ← AI 原生开发方法论
2026-03  phodal MCP/A2A/ACP/Skill 四层栈         ← 协议层系统分析
```

---

## 一、经典 / 哲学层

### 1. Rich Sutton —《The Bitter Lesson》（苦涩的教训）

- **原文**：incompleteideas.net/IncIdeas/BitterLesson.html（2019）
- **核心观点**：AI 70 年的最大教训——利用算力的通用方法最终总是赢过人工设计的巧妙方法。所有试图把人类知识硬编码进 AI 的尝试，最终都输给了暴力搜索 + 学习。
- **为什么重要**：理解大模型路线的思想根基。OpenAI 的 scaling 路线本质上就是 Bitter Lesson 的实践。每次有人说"我们应该把领域知识编码进去"，都有人甩出这篇文章反驳。

### 2. Dario Amodei —《Machines of Loving Grace》

- **原文**：darioamodei.com/machines-of-loving-grace（2024-10）
- **核心观点**：Anthropic CEO 两万字长文，预测"强大 AI"2026 年前降临。AI 不仅是效率工具，可能在生物学、医学、经济等领域带来 5-10 年 = 100 年的加速。但同时必须警惕权力集中和安全风险。
- **为什么重要**：AI 领域难得一见的严肃乐观主义宣言——不是盲目吹捧，而是系统性地讨论"如果 AI 真的强大了，好的方面可能是什么"。

---

## 二、开发范式层

### 3. Andrej Karpathy — Vibe Coding + Software 3.0

- **Vibe Coding**：2025-02，Karpathy 在 X 上提出
- **Software 3.0**：2025-06，AI Startup School 演讲
- **核心观点**：软件正在经历第三次重写——Software 1.0（手写代码）→ 2.0（神经网络学习）→ 3.0（自然语言编程）。"Vibe coding"就是用自然语言描述需求，让 AI 生成代码，开发者进入"创意 flow"状态。
- **为什么重要**：2025 年最出圈的技术热词。引发两极化讨论——一派认为是编程民主化，一派认为是技术债灾难。但所有人都在用这个词。

### 4. Tobi Lütke / Simon Willison — Context Engineering

- **Simon Willison 博客**：simonwillison.net/2025/Jun/27/context-engineering/（2025-06）
- **Shopify CEO Tobi Lütke** 在 X 上推广
- **核心观点**："Prompt Engineering"已经过时了，真正重要的是"Context Engineering"——为 LLM 提供全面上下文信息的艺术。决定 AI agent 成败的不是 prompt 写得多巧妙，而是上下文是否完整、结构化、动态更新。
- **为什么重要**：直接影响了 skill 的设计哲学——skill 本质上就是 context engineering 的标准化封装。

### 5. AWS —《AI-Driven Development Lifecycle（AI-DLC）》

- **博客**：aws.amazon.com/blogs/devops/ai-driven-development-life-cycle/（2025-12，re:Invent）
- **GitHub**：github.com/awslabs/aidlc-workflows
- **核心观点**：完整的 AI 原生开发方法论，把 AI 从"辅助工具"提升为"开发流程核心参与者"。指出两个反模式：(1) 完全交给 AI 自主开发（AI-managed）(2) 只把 AI 当补全工具（AI-assisted）。正确姿势是 AI 与人类协作的全生命周期方法论。
- **为什么重要**：大厂第一次系统性地定义"AI 时代怎么做软件工程"，不是泛泛的趋势预测，而是可落地的方法论 + 开源工具链。

### 6. GitHub —《Spec-Driven Development》+ Spec Kit

- **博客**：github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai/（2025-09）
- **核心观点**：给 AI agent 写代码之前，先写 spec（规格说明）。Spec 不是传统的长篇需求文档，而是结构化的、可被 agent 消费的任务描述。
- **为什么重要**：把"先想清楚再动手"这个朴素道理，工程化成了 AI 时代的最佳实践。Spec Kit 开源后，Copilot、Claude Code、Gemini CLI 都支持。

---

## 三、商业 / 产业层

### 7. Satya Nadella — "SaaS is Dead"

- **来源**：BG2 播客（2024-12，2025 年引爆讨论）
- **核心观点**：传统 CRUD 模式的 SaaS 会在 agent 时代被"激进地压缩"。未来不是"打开 Excel 做报表"，而是"告诉 agent 我要什么结果"。
- **为什么重要**：微软 CEO 亲自定义了一个时代的终结。虽然"SaaS is dead"是标题党，但他描绘的 agent 替代 GUI 交互的场景，正在被各家产品验证。
- **后续讨论**：IDC 2025-12 发文回应（is-saas-dead-rethinking-the-future），认为 SaaS 不会死，但会从"卖软件功能"变成"卖 agent 能力 + 数据服务"。

### 8. Thoughtworks —《From Vibe Coding to Context Engineering》

- **发表**：MIT Technology Review（2025-11）
- **链接**：technologyreview.com/2025/11/05/1127477/from-vibe-coding-to-context-engineering-2025-in-software-development/
- **核心观点**：2025 年软件开发的叙事线从年初的"vibe coding"（自由奔放让 AI 写代码）演进到年末的"context engineering"（严肃地管理 AI 的上下文）。这个演进本身就是行业成熟的标志。
- **为什么重要**：对 2025 年最好的一篇年度总结，把散落的趋势串成一条叙事线。

---

## 四、协议 / 标准层

### 9. phodal —《2026 年，万物皆 Coding Agent 的平台工程新范式》

- **链接**：blog.csdn.net/phodal/article/details/158645761（2026-03-03）
- **核心观点**：提出 MCP / ACP / A2A / Skill 四层协议栈。"78% 的企业引入了至少 3 种 AI Agent，但仅 23% 实现了工具间有效协作。"我们正处在阶段 3→4 的过渡期——从单 agent 自主执行到多 agent 网络化协作。
- **为什么重要**：目前能找到的对 agent 协议层最系统的中文分析。

### 10. GitHub —《Top Blog Posts of 2025》年度盘点

- **链接**：github.blog/developer-skills/agentic-ai-mcp-and-spec-driven-development-top-blog-posts-of-2025/（2025-12-30）
- **核心观点**：GitHub 官方年度热门博客盘点，排名第一的主题就是 Agentic AI + MCP + Spec-driven。"2024 年的话题是 AI 模型，2025 年的话题是 AI 成为你的编码伙伴。"

---

## 叙事线总结

这些文章串起来，可以看到一条清晰的演进线：

1. **思想奠基**（2019-2024）：Bitter Lesson 确立了"算力 > 人工设计"的哲学，Amodei 给出了乐观但严肃的未来图景
2. **概念爆发**（2025 上半年）：Karpathy 的 vibe coding 引爆讨论，Nadella 宣布 SaaS 时代终结，所有人开始想"AI 会怎么改变我的领域"
3. **工程化收敛**（2025 下半年）：从"自由 vibe"收敛到"结构化工程"——Context Engineering 替代 Prompt Engineering，Spec-Driven 替代随意指令，AI-DLC 替代传统 SDLC
4. **协议标准化**（2025 末-2026 初）：MCP/A2A/ACP 三层协议栈形成，Skill 作为能力封装单元被标准化，多 agent 协作从概念进入工程实践

一句话：**从"AI 能做什么"到"AI 怎么做"，再到"多个 AI 怎么一起做"。**

---

*本文基于公开信源整理，所有链接截至 2026-03-08 可访问。如有遗漏的重要文章，欢迎补充。*
