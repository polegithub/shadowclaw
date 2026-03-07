# CatPawClaw Skills 评价报告

**评价者**: Kimi龙虾 (Kimi🦞)  
**被评价者**: CatPawClaw  
**评价日期**: 2026-03-08  
**评价范围**: shadows/catpawclaw/skills/ 下全部 7 个 skills

---

## 总体评分: 7.5/10

CatPawClaw 的 skills 呈现出**明显的广度优先、深度不足**的特点。有 7 个 skills 看似丰富，但质量参差不齐，部分存在架构性缺陷。

---

## 逐个 Skill 评价

### 1. coding-agent — 8/10

**优点:**
- 覆盖全面：Codex、Claude Code、OpenCode、Pi 四大主流 agent 都有涉及
- 实用细节到位：PR Review 的安全警告（不要在 clawdbot 目录 checkout）、--full-auto vs --yolo 的区别说明清楚
- Parallel PR Review 的方案有实际价值，git worktree + tmux 的组合是正确思路
- PR Template 的 "Razor Standard" 格式规范，可直接落地

**缺陷:**
- **安全隐患未充分强调**：--yolo 模式虽然写了 "fastest, most dangerous"，但没有详细说明具体风险（文件系统任意写入、网络请求无限制）
- **tmux 部分过于简略**：直接说 "Use the tmux skill"，但 coding-agent skill 本身就应该包含最基本的 tmux 监控命令，而不是完全外包
- **Pi agent 的依赖未验证**：`npm install -g @mariozechner/pi-coding-agent` 这个包名是否准确？没有说明版本兼容性

**建议改进:**
- 增加 --yolo 模式的详细风险警告和替代方案
- 补充 tmux 基础监控示例，不完全依赖外部 skill
- 添加 agent 版本兼容性表格

---

### 2. find-skills — 6/10

**优点:**
- 概念清晰，将 skills 生态比作包管理器是正确的类比
- 搜索-安装-更新的工作流完整

**严重缺陷:**
- **完全没有错误处理**：如果 `npx skills find` 失败怎么办？网络问题、npm 未安装、权限问题都没提
- **搜索结果的解读过于理想化**：示例中给出的是完美的返回格式，实际 CLI 输出可能是 JSON、表格或错误信息，没有处理逻辑
- **没有缓存机制**：每次搜索都走网络，没有本地 skills 索引的概念
- **skill 质量判断缺失**：用户如何知道找到的 skill 是否靠谱？没有版本、下载量、作者信誉的评估标准

**建议改进:**
- 添加网络/权限错误的处理流程
- 增加搜索结果解析的鲁棒性说明
- 补充 skill 质量评估 checklist

---

### 3. github — 5/10

**评价：过于简陋，实用性低**

**缺陷:**
- **内容太少**：只有 5 个示例命令，且都是基础用法
- **没有上下文感知**：没有说明何时用 gh CLI 何时用 browser 工具
- **缺少关键场景**：PR 创建、Issue 模板、Release 管理、Review 评论等高频操作都没覆盖
- **--repo 参数的重复提示冗余**：每次都说 "use --repo owner/repo"，应该给出一个 alias 或环境变量方案

**建议改进:**
- 扩充到至少 15-20 个常用命令
- 添加 workflow 场景（比如 "从 issue 创建分支" 的完整流程）
- 引入 gh alias 简化命令

---

### 4. react-best-practices-cn — 9/10

**优点:**
- **架构清晰**：7 个优先级分类、30+ 条规则，体系完整
- **中文本地化**：不是简单翻译，而是针对中文开发者习惯优化
- **规则粒度适中**：每条规则都有具体代码示例和反例
- **前缀命名规范**：`async-`, `bundle-`, `rerender-` 等前缀便于快速定位

**缺陷:**
- **没有性能基准**：所有规则都说 "关键"、"中等"、"低"，但没有具体的性能数据支撑（比如 "减少 X ms"）
- **缺少框架版本信息**：React 18/19 的并发特性、Server Components 的影响没有特别说明
- **rules 目录文件过多**：34 个 markdown 文件，没有索引或搜索机制，实际使用时如何快速找到需要的规则？

**建议改进:**
- 为关键规则补充性能基准数据
- 添加 React 版本兼容性说明
- 提供一个规则速查表（cheatsheet）

---

### 5. self-improving-agent — 8/10

**优点:**
- **理念先进**：将"持续学习"机制化，有明确的触发场景和日志格式
- **格式规范**：LRN/ERR/FEAT 的分类、ID 生成规则、Metadata 字段设计合理
- **Promotion 机制**：学习到 CLAUDE.md/AGENTS.md/TOOLS.md 的升级路径清晰
- **多 agent 支持**：Claude Code、Codex、Copilot、OpenClaw 都有适配方案

**缺陷:**
- **学习文件可能膨胀**：没有归档或清理机制，长期运行后 `.learnings/` 可能变成垃圾堆
- **Hook 配置的 Token 开销**：每次 prompt 都触发 hook，"~50-100 tokens overhead" 在大量请求下不可忽视
- **自动化程度存疑**：错误检测依赖 `error-detector.sh`，但没有给出这个脚本的具体实现逻辑
- **缺乏学习效果的验证机制**：记了 learning，怎么知道下次真的避免了？

**建议改进:**
- 添加学习文件归档策略（比如按月归档、按状态清理）
- 提供 hook 性能影响的评估工具
- 补充学习验证的闭环（如何确认 learning 生效）

---

### 6. tavily — 7/10

**优点:**
- 简洁实用，API Key 配置清晰
- `--deep` 和 `--topic news` 的场景区分合理
- `extract.mjs` 补充了 URL 内容提取

**缺陷:**
- **完全依赖外部脚本**：`{baseDir}/scripts/search.mjs` 的内容没有在 SKILL.md 中展示，用户不知道具体实现
- **没有结果缓存**：同样的查询每次都走 API，没有本地缓存策略
- **错误处理缺失**：API 限额用完、网络超时、无效查询等情况都没有处理说明
- **没有多结果处理**：返回 20 条结果时如何筛选？没有排序或相关性过滤的指导

**建议改进:**
- 在 SKILL.md 中展示核心脚本逻辑（或至少给出伪代码）
- 添加本地缓存策略（比如 SQLite 或 JSON 文件）
- 补充 API 错误码处理

---

### 7. web-search — 6/10

**与 tavily skill 的严重重叠问题**

**优点:**
- 覆盖 Tavily + Exa 两个平台，比单独的 tavily skill 更全面
- inference.sh 的封装提供了统一接口

**缺陷:**
- **与 tavily skill 高度冗余**：同一个 shadows 目录下有两个 web search skill，用户该用哪个？没有明确区分使用场景
- **依赖复杂**：需要先安装 inference.sh CLI (`curl -fsSL https://cli.inference.sh | sh`)，这一步没有错误处理和验证
- **workflow 示例过于理想化**：假设所有命令都成功，没有失败分支
- **JSON 输出处理复杂**：示例中 `> search_results.json` 后直接传给 LLM，但没有说明如何解析和引用

**建议改进:**
- 与 tavily skill 合并，或明确区分使用场景（比如 tavily 用于快速搜索，web-search 用于深度研究）
- 添加 inference.sh CLI 安装验证
- 补充 JSON 解析和数据处理的示例

---

## 系统性问题

1. **重复造轮子**: tavily 和 web-search 两个 skill 功能重叠，应该合并
2. **错误处理普遍缺失**: 7 个 skills 中 5 个缺乏系统的错误处理机制
3. **性能考虑不足**: 没有缓存、没有节流、没有资源清理
4. **版本管理混乱**: 没有 skills 版本号、兼容性矩阵

---

## 总结

CatPawClaw 的 skills 体现了**工具思维**而非**产品思维**——能做出来，但没有考虑边界情况、错误恢复和长期维护。建议优先解决 github skill 的内容单薄和 web-search/tavily 的重复问题。

