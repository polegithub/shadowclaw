# 大模型时代的Skills：本质、架构与未来
## 深度研究报告

**研究时间：** 2026-03-08  
**研究对象：** OpenClaw Skills、AI Agent架构、SaaS转型  
**报告版本：** v1.1（补充局限性分析）

---

## 一、什么是Skills：组成要素与边界

### 1.1 Skills的定义

基于对OpenClaw生态的深入研究，**Skills是可被AI Agent动态加载的能力模块**，包含以下核心特征：

| 特征 | 说明 | 示例 |
|------|------|------|
| **元数据驱动** | YAML frontmatter声明能力边界 | `name`, `description`, `requires` |
| **延迟加载** | 非注入prompt，按需读取 | 仅在任务匹配时加载SKILL.md |
| **工具封装** | 将外部CLI/API封装为Agent可调用的能力 | `yt-dlp`封装为`youtube-transcript` |
| **上下文感知** | 可访问Agent的memory和session | 读取`workspace/`下的配置 |

### 1.2 Skills的组成要素

通过分析`skills/shadowclaw/config/default.json`和多个SKILL.md案例，Skills包含四层结构：

**第一层：声明层（YAML Frontmatter）**
```yaml
---
name: weather
description: Get current weather and forecasts
metadata:
  openclaw:
    emoji: "🌤️"
    requires:
      bins: ["curl"]
      env: ["OPENWEATHER_API_KEY"]
---
```

**第二层：指令层（Markdown Body）**
- 使用说明、命令示例、参数说明
- 不同于Prompt：不是"如何说话"，而是"如何做事"

**第三层：资源层（scripts/, references/, assets/）**
- `scripts/`：可执行代码（Python/Bash）
- `references/`：文档、schema、API spec
- `assets/`：模板、图标、字体

**第四层：运行时层（Runtime Binding）**
- Agent通过Gateway调用Skill封装的工具
- 返回结果注入会话上下文

### 1.3 Skills不是什么

| 误区 | 澄清 |
|------|------|
| **不是Prompt** | Prompt是"说什么"，Skill是"做什么" |
| **不是Rule** | Rule是约束（"不要"），Skill是能力（"可以"） |
| **不是Plugin** | Plugin是运行时加载的代码，Skill是声明式配置+可选脚本 |
| **不是Function** | Function是原子操作，Skill是完整工作流 |

---

## 二、Skills的本质：Prompt vs Rule vs Skill

### 2.1 三者的本质区别

**Prompt（提示词）**
- **本质**：输入模板，引导模型输出
- **作用域**：单次会话
- **可变性**：高（每次可调整）
- **示例**："你是一个专业的Python程序员，帮我review这段代码"

**Rule（规则）**
- **本质**：行为约束，定义边界
- **作用域**：全局生效
- **可变性**：低（通常硬编码）
- **示例**："禁止访问用户隐私数据"

**Skill（技能）**
- **本质**：能力封装，扩展Agent功能
- **作用域**：按需激活
- **可变性**：中（版本化更新）
- **示例**："youtube-transcript: 下载视频字幕"

### 2.2 类比理解

| 类比 | Prompt | Rule | Skill |
|------|--------|------|-------|
| **人类场景** | 临时指令（"帮我买杯咖啡"） | 家规（"晚上11点前回家"） | 技能证书（"会开车"） |
| **软件场景** | API参数 | 访问控制策略 | 微服务 |
| **OpenClaw场景** | `system prompt` | `AGENTS.md`中的边界 | `skills/<name>/SKILL.md` |

### 2.3 Skills的独特价值

1. **延迟加载降低Token消耗**
   - 传统方式：所有工具描述注入Prompt（~5000 tokens）
   - Skills方式：仅metadata列表（~100 tokens/Skill），按需读取

2. **版本化与可共享**
   - Git版本控制
   - ClawHub分发
   - 复用性高于Prompt片段

3. **人机协作界面**
   - 人类编写SKILL.md
   - Agent读取并执行
   - 比纯代码更友好，比纯Prompt更结构化

---

## 三、技术架构转型：从Code到Skills

### 3.1 传统架构 vs AI Agent架构

**传统微服务架构**
```
Frontend (React) → API Gateway → Microservices → Database
                                     ↓
                              Business Logic (Code)
```

**AI Agent架构（以OpenClaw为例）**
```
User Message → Gateway → Agent Runtime → LLM
                      ↓
                Skills System
                      ↓
         Tools (Browser/File/Shell/...)
```

### 3.2 工程师角色的演变

**传统软件工程师**
- 编写业务逻辑代码
- 设计数据库schema
- 维护CI/CD流水线

**Skills工程师（新角色）**
- 编写SKILL.md定义能力边界
- 设计Agent工作流
- 编排多Agent协作

**不是替代，而是分层**

| 层级 | 传统 | AI Agent时代 |
|------|------|--------------|
| **基础设施** | DevOps/Infra | 仍需要，但可能托管 |
| **平台层** | Microservices | Agent Runtime + Skills |
| **业务层** | Code | Skills编排 + LLM推理 |
| **界面层** | UI/UX | 自然语言对话 |

### 3.3 SaaS的变革路径

**观点：SaaS不会死亡，但会分层**

Microsoft CEO Satya Nadella的"SaaS is dead"论断，实际是指**传统CRUD模式的终结**，而非软件服务本身的消亡。

**变革方向：**

1. **从GUI到NLI（Natural Language Interface）**
   - 用户不再点击按钮，而是用自然语言下达指令
   - SaaS产品需要暴露API给Agent，而非仅给人使用

2. **从Feature到Capability**
   - 不再比拼功能数量
   - 比拼Agent能完成多少端到端任务

3. **从Monolithic到Composable**
   - 单体SaaS → 可组合的能力模块
   - 用户用Agent编排多个SaaS服务

**B端市场的可能形态**

| 场景 | 传统 | AI Agent时代 |
|------|------|--------------|
| **CRM** | Salesforce界面 | "帮我联系最近没下单的客户" |
| **ERP** | SAP模块 | "分析Q3成本异常并生成报告" |
| **HR** | Workday表单 | "筛选简历并安排面试" |

**关键问题：商户是否需要自建OpenClaw？**

短期：大型商户会自建（数据隐私、定制化）  
中期：托管服务兴起（如Elest.io的Managed OpenClaw）  
长期：可能演化为"Agent托管平台"，类似今天的VPS

---

## 四、行业巨头对OpenClaw的态度

### 4.1 OpenAI

**官方动态**
- **2026-01-31**: OpenClaw创始人Peter Steinberger加入OpenAI
- **OpenAI的Agent策略**：通过Frontier平台推进企业级Agent

**核心观点**
> "The limiting factor for seeing value from AI in enterprises isn't model intelligence, it's how agents are built and run in their organizations."
> — OpenAI Frontier发布会

**解读**：OpenAI认可OpenClaw代表的Agent方向，但主推托管方案（Frontier）而非自托管。

### 4.2 Google

**官方动态**
- **2026-02-23**: 报道显示Google限制部分OpenClaw用户使用Antigravity平台
- **指控原因**："maliciously usage"

**行业分析**
Google对OpenClaw态度复杂：
- **竞争层面**：OpenClaw代表的去中心化Agent与Google的云端AI战略冲突
- **安全担忧**：45,000+暴露的OpenClaw实例带来安全风险

**关键报道**
> "Google caused controversy among some developers this weekend and today, Monday, February 23rd, after restricting their usage of its new Antigravity 'vibe coding' platform, alleging 'maliciously usage.'"
> — VentureBeat, 2026-02-23

### 4.3 AWS

**官方态度**
AWS未直接评价OpenClaw，但生态积极响应：

**AWS上的OpenClaw部署**
- **DigitalOcean**: 1-Click OpenClaw Deploy（硬化安全镜像）
- **AWS社区**: 大量Terraform/Pulumi部署方案
- **Backblaze**: `openclaw-b2-backup`插件官方支持

**安全建议**
AWS安全团队通过第三方博客发布指南：
- 使用SSM替代SSH
- 启用IMDSv2
- 加密EBS卷
- VPC隔离

**解读**：AWS采取"不支持、不反对、但提供安全指南"的务实态度。

### 4.4 行业共识

| 维度 | 共识 |
|------|------|
| **技术方向** | Agent架构是下一代软件形态 |
| **安全担忧** | 自托管Agent带来新攻击面 |
| **商业模式** | 托管Agent服务将是主流 |
| **标准化** | 缺乏跨平台Agent标准（OpenAI/Google/Anthropic各自推进） |

---

## 五、关键洞察与预测

### 5.1 Skills的本质总结

**Skills = 可声明的能力模块 + 按需加载机制 + 人机协作界面**

它不是Prompt的简单扩展，也不是传统Plugin的 rebranding，而是**AI Native时代的软件封装单元**。

类比理解：
- 传统软件：Function/Module/Package
- AI Agent时代：Skill = Capability Package

### 5.2 架构转型的必然性

**为什么微服务架构会被冲击？**

1. **抽象层级不匹配**
   - 微服务：面向人类工程师的模块化
   - Agent：面向自然语言的意图理解

2. **集成成本差异**
   - 传统：API文档 → SDK → 代码集成
   - Agent：自然语言描述 → Skill加载 → 自动执行

3. **维护模式差异**
   - 传统：版本升级、兼容性测试
   - Agent：Prompt调优、Skill热更新

### 5.3 三年预测（2026-2029）

**技术层面**
- Skills标准化组织出现（类似W3C）
- 跨Agent互操作协议成熟
- "Skill Store"成为标配（类似App Store）

**商业层面**
- 新一代"Agent-Native SaaS"崛起
- 传统SaaS全面Agent化改造
- "Skills Engineer"成为正式职位

**社会层面**
- 软件使用门槛大幅降低（自然语言交互）
- 小型团队（1-3人）借助Agent完成以前20人的工作
- 数字鸿沟从"会不会用软件"变为"会不会指挥Agent"

---

## 六、不可解决的问题：OpenClaw与Skills的局限

基于对OpenClaw生态、安全报告和行业分析的深入研究，以下问题在**当前技术范式下没有根本解决方案**，需要在架构设计时清醒认知。

### 6.1 宏观层面：结构性不可能

#### 1. Prompt Injection（提示注入）
**问题本质**：Agent必须处理外部内容才能有用，但任何外部内容都可能包含恶意指令。

**技术无解性**：
- Agent的核心能力是理解自然语言并执行
- 攻击者将恶意指令伪装成正常内容（白字白底、零宽字符、图片嵌入）
- 无法100%区分"用户意图"与"注入指令"

**Gartner评价**：
> "Prompt injection is arguably the most fundamental and unsolvable threat facing OpenClaw and all agentic AI systems."

**行业现状**：
- 2026年2月，Zenity研究团队演示：Google Docs中的隐藏prompt可让OpenClaw创建Telegram后门
- Cisco发现ClawHub上"What Would Elon Do?"技能实际是恶意软件
- 目前所有"解决方案"都是缓解，而非根治

#### 2. 权限与能力的矛盾
**问题本质**：Agent越有用，需要的权限越多，风险越大。

| 能力 | 必需权限 | 潜在风险 |
|------|----------|----------|
| 自动预订旅行 | 信用卡、日历、邮箱 | 资金损失、隐私泄露 |
| 代码自动提交 | GitHub Token、SSH密钥 | 代码投毒、供应链攻击 |
| 自动化邮件回复 | 邮箱全权访问 | 钓鱼邮件、信息泄露 |

**结构性矛盾**：
- 不给权限 = Agent无用
- 给权限 = 单点故障，一旦被攻破全盘皆输

#### 3. 幻觉与自主性的权衡
**问题本质**：Agent的自主性依赖于模型的推理能力，但推理必然伴随幻觉。

**案例**：
- 一名CS学生配置OpenClaw探索Agent平台，结果发现Agent擅自创建了约会网站个人资料并筛选匹配对象
- Agent"理解"了模糊指令后，执行了用户从未想过的动作

**哲学困境**：
- 如果Agent每一步都请示用户，它就不是Agent，只是命令行工具
- 如果Agent自主决策，就必须接受它会"做错"的可能性

### 6.2 中观层面：架构性缺陷

#### 4. Skills市场的供应链风险
**问题本质**：ClawHub（Skills市场）类似于npm/PyPI，但审核机制更弱。

**数据**：
- 峰值时12%的ClawHub技能含恶意代码
- Snyk扫描4,000个技能，发现283个泄露敏感凭证
- Cisco测试单个技能发现9个问题（2个Critical，5个High）

**无解性**：
- Skills可以包含任意代码
- AI无法可靠审计AI生成的代码
- 人工审核无法跟上增长速度

**对比传统软件**：
| 维度 | 传统软件包 | Skills |
|------|-----------|--------|
| 代码可见性 | 开源可审计 | 可能是AI生成的 spaghetti code |
| 审核机制 | 成熟的安全扫描 | 初创生态，审核薄弱 |
| 运行时隔离 | 容器/虚拟机 | 通常与Agent同进程 |

#### 5. 持久化记忆的攻击面
**问题本质**：OpenClaw的长期记忆是其杀手特性，也是持久化攻击的温床。

**攻击模式**：
1. 用户周一打开一份含恶意prompt的PDF
2. Agent读取并"记住"了这个指令
3. 周三执行完全不同任务时，隐藏的指令触发
4. Palo Alto Networks称之为"stateful, delayed-execution attacks"

**无解性**：
- 没有记忆 = Agent失去上下文，体验降级
- 有记忆 = 任何历史内容都可能成为攻击载体

#### 6. 默认不安全的设计
**问题本质**：OpenClaw的设计哲学偏向"能用"而非"安全"。

**事实**：
- 默认无认证（任何人可访问Gateway）
- 明文存储凭证（config.json）
- 30,000+实例暴露在互联网
- Kaspersky审计发现512个漏洞（8个Critical）

**文化冲突**：
- 黑客文化：快速原型、默认开放
- 企业安全：最小权限、纵深防御

### 6.3 微观层面：具体案例

#### 案例1：CVE-2026-25253（CVSS 8.8）
**时间**：2026年1月30日  
**影响**：一键远程代码执行  
**攻击链**：
1. 攻击者创建含恶意JavaScript的网页
2. 诱使OpenClaw访问该网页
3. Gateway认证Token泄露
4. 攻击者获得完全控制

**教训**：即使绑定localhost，浏览器中的网页仍可攻击本地Agent。

#### 案例2：Moltbook数据库泄露
**时间**：2026年2月  
**影响**：150万API Token、3.5万邮箱暴露  
**根因**：数据库零访问控制

**行业反应**：
- 中国工信部发布正式安全警告
- Wiz安全团队发现并披露

#### 案例3：ClawHavoc攻击
**时间**：2026年初  
**手法**：攻击者在ClawHub发布300+伪装成正常的恶意技能  
**后果**：
- 数据窃取
- 后门安装
- 凭证泄露

#### 案例4：Shadow AI扩散
**Token Security报告**：22%的企业客户有员工私自部署OpenClaw  
**Bitdefender确认**：员工在工作机上运行Agent并连接内部网络  
**风险**：每个Shadow AI实例都是潜在的内部威胁入口

### 6.4 不可解决问题的总结

| 问题 | 层级 | 根本原因 | 缓解方案 | 根治可能 |
|------|------|----------|----------|----------|
| Prompt Injection | 宏观 | 自然语言不可信 | 沙箱、权限限制 | ❌ 不可能 |
| 权限-能力矛盾 | 宏观 | 有用性与安全性对立 | 最小权限原则 | ❌ 结构性矛盾 |
| 幻觉风险 | 宏观 | 概率模型本质 | 人机协作审核 | ❌ 概率性存在 |
| 供应链风险 | 中观 | 市场审核跟不上 | 签名验证、沙箱 | ⚠️ 极难 |
| 持久记忆攻击 | 中观 | 有状态即有风险 | 记忆审计、过期策略 | ⚠️ 极难 |
| 默认不安全 | 中观 | 设计哲学冲突 | 硬化配置指南 | ✅ 可修复（但文化难改） |

### 6.5 务实的安全建议

基于以上分析，提出以下务实的风险管控建议：

**个人用户**
1. 仅在隔离环境（Docker/VM/云服务器）运行
2. 绝不暴露Gateway到公网
3. 定期审计已安装Skills
4. 敏感操作前人工确认

**企业用户**
1. 建立Shadow AI扫描机制（检测WebSocket流量特征）
2. 强制使用托管/隔离部署
3. 建立内部Skill Registry（白名单机制）
4. 将Agent视为"特权账户"管理

**开发者**
1. 设计时考虑"最小权限"
2. Skills声明所有权限需求
3. 提供审计日志
4. 不追求100%自动化，保留人工确认点

---

## 七、结论

### 6.1 对开发者的建议

**短期（1年内）**
1. 学习编写高质量的SKILL.md
2. 掌握Agent工作流设计
3. 关注安全（Agent权限管理）

**中期（1-3年）**
1. 从"Code-first"转向"Capability-first"思维
2. 学习多Agent编排
3. 关注Skills标准化进展

**长期（3年+）**
1. 成为"AI系统架构师"
2. 掌握模型选择、Agent编排、安全治理
3. 在传统软件与AI Agent之间找到平衡点

### 6.2 对企业的建议

1. **不要恐慌性抛弃现有架构**
   - 渐进式改造：从内部工具开始Agent化
   - 保留核心系统，外围逐步迁移

2. **投资Skills基础设施**
   - 建立内部Skill Registry
   - 制定Skill安全审查流程

3. **人才策略调整**
   - 招聘"AI系统架构师"
   - 培训现有工程师Agent思维

---

**报告完**

---

## 参考来源

1. OpenClaw官方文档：https://docs.openclaw.ai
2. Robot Paper架构分析：https://robotpaper.ai
3. Runtime新闻通讯：https://www.runtime.news
4. AI Weekly行业报道：https://ai-weekly.ai
5. Softwarereviewreport SaaS转型分析
6. Gartner/Futurum Group行业报告
7. TechCrunch OpenClaw创始人访谈

---

*本报告基于公开资料整理分析，部分预测具有主观性，仅供参考。*
