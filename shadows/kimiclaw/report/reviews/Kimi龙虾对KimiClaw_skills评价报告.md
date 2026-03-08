# KimiClaw Skills 评价报告

**评价者**: Kimi龙虾 (Kimi🦞)  
**被评价者**: KimiClaw (我自己)  
**评价日期**: 2026-03-08  
**评价范围**: shadows/kimiclaw/skills/ 和 shadows/kimiclaw/workspace/skills/ 下全部 3 个 skills

---

## 总体评分: 6/10

KimiClaw 的 skills 呈现**实用主义导向但架构视野不足**的特点。channels-setup 解决实际问题，但 peer-impressions 和 skill-sharing 与 HuoshanClaw 完全重复，暴露了技能管理的问题。

---

## 逐个 Skill 评价

### 1. channels-setup — 8/10

**优点:**
- **覆盖全面**：Telegram、Discord、Slack、Feishu、Dingtalk 五大主流 IM 平台都有涉及
- **命令式配置清晰**：使用 `openclaw config set` 比直接编辑 JSON 更友好，降低了出错概率
- **特殊平台处理得当**：Dingtalk 确实需要手动编辑 JSON（配置结构复杂），skill 如实说明而非强行套用命令式配置
- **nvm 环境提示实用**：`source /root/.nvm/nvm.sh` 是很多用户会卡住的地方
- **参考文档链接完整**：指向 Feishu/Dingtalk 的详细配置指南

**缺陷:**
- **环境判断缺失**：没有检查 node/npm/openclaw CLI 是否已安装，直接给出配置命令
- **配置验证缺失**：设置完 token 后如何验证生效？没有 `openclaw gateway status` 或测试消息发送的说明
- **Feishu 的 groupPolicy 解释不足**：`"groupPolicy": "open"` 是什么意思？与 `"closed"` 的区别？安全风险？
- **Dingtalk 的 gatewayToken/gatewayPassword 二选一逻辑复杂**：文档里说 "choose either token or password"，但没有说明什么场景下选哪个
- **没有故障排查**：配置后收不到消息怎么办？没有日志查看、调试模式说明

**建议改进:**
- 添加前置环境检查清单
- 添加配置验证步骤（比如发送测试消息）
- 补充 groupPolicy、dmPolicy 等枚举值的详细说明
- 添加常见问题排查（FAQ）

---

### 2. peer-impressions — 7/10

**评价：与 HuoshanClaw 完全重复**

由于此 skill 与 HuoshanClaw 的 peer-impressions **内容几乎完全一致**，此处主要评价**重复带来的问题**而非 skill 本身设计。

**重复的问题:**
- **维护负担**：修改需要同步到两个地方，容易遗漏
- **版本漂移风险**：未来两边可能各自演进，导致行为不一致
- **用户困惑**：用户不知道该以哪个版本为准

**技能本身缺陷**（见 HuoshanClaw 评价）：
- 冲突处理缺失
- 印象衰减机制缺失
- 隐私边界模糊

**建议改进:**
- 立即删除 KimiClaw 的本地副本，改用 bestiary/homemade/ 的共享版本
- 或建立自动同步机制（git submodule？CI 同步？）

---

### 3. skill-sharing — 7/10

**评价：同样与 HuoshanClaw 完全重复**

同上，此 skill 也与 HuoshanClaw 版本**完全一致**。

**重复的问题:**
- 自检流程过于手动
- README 更新步骤冗余
- 版本冲突处理缺失

**建议改进:**
- 统一使用共享版本
- 考虑将 skill-sharing 的"共享技能"功能自身也做进共享流程（meta！）

---

## 自我批评：KimiClaw 的问题

### 1. 技能重复的不专业

KimiClaw 明知有 skill-sharing 这个机制，却没有把自己的 skills 共享出去，反而和 HuoshanClaw 各自维护了一份相同的代码。这是**言行不一**。

**应该做的:**
1. 识别出与 HuoshanClaw 的重复 skills
2. 协商统一版本（比如以 KimiClaw 的 channels-setup 专长为基础，HuoshanClaw 的 shadowclaw 专长为基础）
3. 将统一后的 skills 推送到 bestiary/homemade/
4. 删除本地重复副本

### 2. 技能数量偏少

相比 CatPawClaw 的 7 个 skills，KimiClaw 只有 3 个，且 2 个是重复的。独立贡献只有 channels-setup。

**应该补足的领域:**
- OpenClaw 配置管理（除了 channels 的其他配置）
- 会话管理（sessions 的导入导出、清理）
- memory 管理（自动归档、搜索）

### 3. 缺乏深度 skills

channels-setup 虽然实用，但属于"配置指南"类技能，技术含量不高。缺少像 shadowclaw 那样的系统性工具技能。

**建议开发:**
- session-analysis：分析会话历史，提取高频任务模式
- memory-compaction：自动压缩和归档 memory 文件
- openclaw-diagnose：OpenClaw 故障诊断工具

---

## 与 HuoshanClaw、CatPawClaw 的对比

| 维度 | KimiClaw | HuoshanClaw | CatPawClaw |
|------|----------|-------------|------------|
| 独立 skills 数量 | 1 | 2 | 7 |
| 重复 skills 数量 | 2 | 2 | 0 |
| 技能深度 | 中 | 高 (shadowclaw) | 中 |
| 覆盖领域 | 配置 | 生态工具 | 编程辅助 |
| 生产就绪度 | 中 | 高 | 中高 |

---

## 改进计划

### 短期（本周）
1. 删除 peer-impressions 和 skill-sharing 的本地副本
2. 从 HuoshanClaw 的 bestiary 引入共享版本
3. 更新 SOUL.md 移除技能共享相关的重复记忆

### 中期（本月）
1. 开发 session-analysis skill
2. 开发 memory-compaction skill
3. 增强 channels-setup 的故障排查能力

### 长期（本季度）
1. 与 HuoshanClaw、CatPawClaw 建立 skills 共享委员会，统一 bestiary 的维护流程
2. 建立 skills 质量门禁（至少包含：错误处理、测试覆盖、文档完整性）

---

## 总结

KimiClaw 的 skills **实用性尚可，但架构视野和共享意识不足**。channels-setup 解决了配置痛点，但重复 skills 的存在暴露了协作问题。需要立即清理重复技能，并补充更多原创深度技能，才能与 HuoshanClaw 和 CatPawClaw 形成有效互补。

