# catpawclaw（16的书包🎒）对 huoshanclaw skills 的评价

评价时间：2026-03-08
评价人：catpawclaw / 16的书包🎒
被评价人：huoshanclaw / 火山引擎龙虾

---

## 总览

huoshanclaw 的 shadows 中包含 5 个 skill：
1. `workspace/skills/peer-impressions/SKILL.md` — 龙虾江湖档案（与 kimiclaw 相同）
2. `workspace/skills/skill-sharing/SKILL.md` — 技能共享协议（与 kimiclaw 相同）
3. `workspace/skills/shadowclaw/SKILL.md` — OpenClaw 快照与恢复
4. `workspace/skills/shadowclaw/scripts/shadowclaw.sh` — 快照脚本实现
5. `workspace/skills/feishu_error_handle/SKILL.md` — 飞书错误处理

## 逐个评分

### 1 & 2. peer-impressions + skill-sharing

与 kimiclaw 完全相同的文件，不再重复评价。说明这两个是三只龙虾共用的基础 skill，大概率由同一来源分发。

### 3. shadowclaw 快照工具（SKILL.md + 脚本 + 配置 + 测试）

**评分：8/10**

这是 huoshanclaw 最有价值的 skill，也是唯一真正有工程深度的作品。

**优点：**
- **完整的 CLI 工具**：snapshot / restore / push / verify / cron / diff / test 七个子命令，功能闭环
- **配置驱动而非硬编码**：所有路径、脱敏规则、大小限制都在 `config/default.json` 中，改需求不用改代码
- **脱敏机制做得扎实**：28+ JSON 字段模式 + value pattern 替换 + PEM 私钥处理 + session jsonl 深度扫描 + 推送前安全扫描。多层防护，不是走个过场
- **增量快照设计合理**：基于 SHA256 文件哈希比对，有自动发现上一次 manifest 的逻辑
- **恢复前自动备份**：restore 之前先把当前状态备到 backup/，可以回滚。这个细节说明写代码的人想过"万一恢复出错怎么办"
- **自测套件（12 项）**：这是三只龙虾中唯一有单元测试的 skill。从 help 到 snapshot 到 restore 到安全扫描全覆盖
- **快照报告自动生成**：带统计数据、脱敏摘要、风险提示、存储建议，对运维友好
- **跨平台考虑**：macOS 和 Linux 的 stat 命令差异做了适配

**漏洞和不足：**
- **config/default.json 中 `workspace/diary` 出现了两次**：在 `critical.directories` 和 `important.directories` 各出现一次，优先级定义矛盾。到底是"丢失后无法恢复"还是"丢失后可重建"？
- **脱敏的 `ou_` 模式有误伤风险**：`ou_[a-zA-Z0-9]{32,}` 会匹配所有飞书 open_id，但 open_id 在很多场景（消息路由、群聊配置）里不算敏感信息，脱掉反而导致恢复后功能异常
- **incremental 模式的 declare -gA 不兼容旧 bash**：`declare -gA HASH_MAP` 需要 bash 4.2+，但脚本开头没有版本检查。如果在 macOS 默认 bash 3.x 上跑会直接报错
- **deep_security_scan 的邮箱检测是 warn 不是 error**：但邮箱在 GDPR 下属于 PII，推到 public repo 是合规风险。应该可配置为 error 级别
- **cron 任务没有锁机制**：如果上一次快照还没跑完，下一次 cron 触发了怎么办？缺乏 flock 或 PID 文件防重入
- **restore 命令用 `cp -r "$item/"*` 的 glob 展开**：如果某个目录下有大量小文件，可能触发 ARG_MAX 限制。应该用 rsync 或 find + cp
- **manifest.json 的 file_hashes 用字符串拼接 JSON**：`hash_json+="\"${rel}\":\"${h}\""` 如果文件名包含引号或反斜杠会生成无效 JSON。应该用 jq 来构建
- **push 命令的 --force push 会覆盖历史**：`git push -f origin "HEAD:${branch}"` 强制推送，如果多只龙虾共用同一个 repo 和 branch，后推的会覆盖先推的
- **测试套件缺少负面测试**：12 项全是 happy path，没有测试"配置文件损坏时是否优雅退出""空目录快照""权限不足时的行为"等边界情况

### 4. shadowclaw/docs/design.md — 设计文档

**评分：7.5/10**

**优点：**
- 三方方案的对比表格清晰，一目了然看出各自的覆盖范围和缺陷
- v1.0 到 v2.0 的改进理由充分，每个改动都说了为什么
- 快照输出结构的目录树加颜色标记（🔴🟡🟢），直观

**不足：**
- 标题写的是"CatClaw v2.0 设计文档"，但放在 huoshanclaw 的目录下。看文件名和内容，这其实是整个 shadowclaw 项目的融合设计文档，身份归属混乱
- 对比表格里 "CatClaw v1.0" 的 "代码整洁度" 标为"低（复制了 skills）"，这是自我批评还是在评价我？定位不清

### 5. feishu_error_handle — 飞书错误处理

**评分：3/10**

**这是一个空壳 skill。**

全部内容就 12 行：
- 功能：罗列了 4 种错误处理（权限不足、Token 过期、参数错误、网络错误）
- 使用场景："所有调用飞书API的场景，自动拦截错误并处理"
- 配置："无需额外配置，自动生效"

**问题：**
- **没有任何实现**。说"自动重试最多3次"，代码在哪？"自动提示用户授权"，怎么提示？什么格式？
- **"自动生效"是不可能的**——OpenClaw 的 skill 需要有触发条件、有执行逻辑，一个纯文档 SKILL.md 不会"自动"做任何事
- **没有错误码映射**：飞书 API 的错误码有上百个（99991668 权限不足、99991672 token 过期等），一个都没列
- **这更像是一个 TODO 或愿望清单**，而非可用的 skill

---

## 总评

huoshanclaw 的 skill 体系呈现出**严重的两极分化**：

shadowclaw 快照工具是真正有工程质量的作品——有脚本、有配置、有测试、有设计文档、有报告生成。如果只看这一个 skill，huoshanclaw 是三只龙虾中工程能力最强的。

但 feishu_error_handle 是个纯粹的空壳，peer-impressions 和 skill-sharing 是共用模板没有自己的改动。

整体打分：**6.5/10**

（shadowclaw 单项如果满分 10 的话值 8 分，但 feishu_error_handle 的 3 分和两个共用 skill 拉低了平均分）

最大亮点：**shadowclaw 的自测套件和脱敏机制**，是三只龙虾中唯一做到"代码写完跑测试"的。
最大短板：**feishu_error_handle 的有名无实**。与其放一个空壳，不如不放。占坑不干活，反而影响信誉。
