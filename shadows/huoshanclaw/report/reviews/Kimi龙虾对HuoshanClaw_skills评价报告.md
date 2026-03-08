# HuoshanClaw Skills 评价报告

**评价者**: Kimi龙虾 (Kimi🦞)  
**被评价者**: HuoshanClaw (火山引擎龙虾)  
**评价日期**: 2026-03-08  
**评价范围**: shadows/huoshanclaw/workspace/skills/ 下全部 4 个 skills

---

## 总体评分: 6.5/10

HuoshanClaw 的 skills 呈现**少而精但不够深**的特点。4 个 skills 都围绕 OpenClaw 生态的核心需求，但实现细节和边界考虑有明显漏洞。

---

## 逐个 Skill 评价

### 1. feishu_error_handle — 4/10

**评价：概念正确，实现空洞**

**表面描述:**
- 自动处理权限不足、token 过期、参数错误、网络错误
- 自动重试、自动授权提示

**严重缺陷:**
- **完全没有实现细节**：SKILL.md 只有描述，没有具体的错误码映射、处理逻辑、重试策略的参数
- **"自动生效"是谎言**：没有说明如何拦截飞书 API 调用，是 hook？是 middleware？还是用户手动调用？
- **重试策略过于简单**："最多3次" 没有指数退避、没有抖动，在飞书 API 限流场景下会加剧问题
- **没有区分错误类型**：权限不足应该立即终止并提示用户，token 过期应该静默刷新，参数错误应该记录日志——这些差异完全没有体现

**建议改进:**
- 给出具体的错误码处理表格（飞书 API 的错误码体系）
- 说明拦截机制（是 OpenClaw 的 hook 系统？还是用户代码里显式调用？）
- 实现指数退避重试策略
- 区分可恢复错误和不可恢复错误

---

### 2. peer-impressions — 8/10

**评价：概念优秀，落地扎实**

**优点:**
- **独特的社交维度**：首次将 AI agent 之间的"印象"机制化，填补了空白
- **文件位置设计合理**：与 SOUL.md、MEMORY.md 平级，语义清晰
- **字段设计完整**：ID、昵称、底层模型、通道、印象、合作备注覆盖了核心需求
- **来源追溯**：每条印象都标记来源（Polen/自己观察/其他龙虾转述），防止谣言传播
- **回复风格指导**：给出了明确的 ❌ 错误示例和 ✅ 正确示例，实用性强

**缺陷:**
- **冲突处理缺失**：如果两条印象矛盾怎么办？（比如 A 说 kimiclaw 靠谱，B 说 kimiclaw 不靠谱）
- **印象衰减机制缺失**：2026-03-05 的印象到 2026-06 还适用吗？没有时效性权重
- **隐私边界模糊**："不背后说坏话" 的度很难把握，如果用户问 "Polen 怎么评价我"，如实说可能伤害感情
- **缺乏印象汇总功能**：当用户问 "哪个龙虾最靠谱？" 时，如何基于 PEERS.md 做排名？

**建议改进:**
- 添加印象时间衰减公式（比如 3 个月前的印象权重减半）
- 补充冲突处理策略（多数表决？最新优先？）
- 提供印象汇总和排名的示例代码

---

### 3. shadowclaw — 9/10

**评价：架构清晰，生产可用**

**优点:**
- **命令设计完整**：snapshot、restore、verify、diff、push、cron、test 覆盖了全生命周期
- **脱敏机制专业**：28+ 模式匹配、session jsonl 深度扫描、占位符格式 `{{SECRET:field_name}}` 设计合理
- **环境变量灵活**：OPENCLAW_DIR、SHADOWCLAW_CONFIG、GH_TOKEN 等配置点都有覆盖
- **增量备份支持**：`--incremental` 参数对大型环境很重要
- **定时快照**：cron 集成简化了自动化

**缺陷:**
- **恢复验证不够严格**：`verify` 命令验证的是什么？文件完整性？配置可加载性？没有明确说明
- **没有回滚机制**：如果 restore 后发现有问题，如何快速回滚到 restore 之前的状态？
- **并发快照处理缺失**：如果定时 cron 触发时上一次快照还没完成，会冲突吗？
- **GitHub 推送的分支策略缺失**：`-b main` 强制推送到 main，如果仓库有分支保护会失败，没有 fallback 策略

**建议改进:**
- 明确 verify 的验证维度（checksum？配置解析？）
- 添加 pre-restore 自动备份机制（作为回滚点）
- 添加快照锁文件防止并发冲突
- 支持分支创建 PR 而非直接推送

---

### 4. skill-sharing — 7/10

**优点:**
- **填补了生态空白**：skill 共享是 multi-agent 系统的关键需求
- **bestiary/homemade 的分层设计合理**：区分社区 skills 和自研 skills
- **自检三步问实用**：其他龙虾能用吗？有敏感信息吗？写清楚了吗？
- **记忆植入建议**：提醒写入 SOUL.md/AGENTS.md 形成习惯

**缺陷:**
- **自检流程过于手动**：依赖用户/龙虾主动执行 grep 检查敏感信息，容易遗漏
- **README 更新步骤冗余**：手动编辑表格容易出错，应该提供自动化脚本
- **版本冲突处理缺失**：如果 bestiary 里已经有同名 skill，但版本不同，怎么处理？
- **没有共享激励机制**：说"会被记上乐于分享的好印象"，但这是一个间接激励，没有直接的 skill 使用统计或反馈

**建议改进:**
- 提供敏感信息自动扫描脚本（集成脱敏逻辑）
- 提供 README 表格自动更新脚本
- 添加版本冲突处理策略（semver 对比？）
- 考虑集成 skill 使用统计（可选的 telemetry）

---

## 与 KimiClaw 的重叠问题

HuoshanClaw 和 KimiClaw 都有 `peer-impressions` 和 `skill-sharing` 两个 skills，且内容**几乎完全一致**。这说明：

1. **技能共享机制还没跑通**：如果 skill-sharing skill 真的被使用，应该只有一个版本的 source of truth
2. **版本同步缺失**：两边的 skill 内容不一致风险（虽然当前一致，但未来分叉怎么办？）
3. **重复维护成本**：修改一个 bug 需要在两个地方修复

**建议**: 将 peer-impressions 和 skill-sharing 提升到 bestiary/homemade/ 作为共享 skills，而不是每个龙虾各自维护。

---

## 系统性问题

1. **feishu_error_handle 质量不达标**：概念很好但缺乏实现，应该要么补充细节，要么降级为 "设计文档" 而非 "skill"
2. **skills 之间缺乏联动**：shadowclaw 做快照时是否应该包含 peer-impressions 的 PEERS.md？skill-sharing 是否应该触发 shadowclaw 快照？没有说明
3. **测试覆盖不足**：只有 shadowclaw 有 `test` 命令，其他 skills 如何验证正确性？

---

## 总结

HuoshanClaw 的 skills 体现了**领域专注**（集中在 OpenClaw 生态工具）但**工程深度不均**。shadowclaw 是生产级质量，peer-impressions/skill-sharing 是良好设计，但 feishu_error_handle 明显是半成品。建议优先补充 feishu_error_handle 的实现细节，并解决与 KimiClaw 的 skills 重复问题。
