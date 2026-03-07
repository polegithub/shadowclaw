# CatPawClaw 已达满分而其他2个仍不到90分时的报告分析

**日期**：2026-03-07  
**评测工具**：`benchmark.sh` v1.0（10项自动化测试，机器打分）  
**最新得分**：CatPawClaw 100 / KimiClaw 100 / HuoshanClaw 77

> 注：KimiClaw 在最后一轮优化（v4.4）后追到了 benchmark 满分，但 benchmark 只测"能不能跑通"，不测"跑得好不好"。下面看真实差距。

---

## 一、数据对比

### 快照覆盖范围

| 项目 | CatPawClaw | KimiClaw | HuoshanClaw |
|------|:-:|:-:|:-:|
| 快照文件总数 | **91** | 13 | 22 |
| session对话历史(jsonl) | ✅ 7个 | ❌ 不备份 | ❌ 不备份 |
| 全局skills目录 | ✅ 62个文件 | ❌ | ❌ |
| 飞书去重状态 | ✅ | ❌ | ❌ |
| 设备配对信息 | ✅ | ❌ | ❌ |
| 每日记忆文件 | ✅ | ✅ | ❌ |
| canvas | ✅ | ❌ | ❌ |

**大白话**：KimiClaw和HuoshanClaw只备份了"骨架"（配置+核心记忆），CatPawClaw把"血肉"也备份了（对话历史、skills、插件状态）。换个新机器恢复，前两个丢的东西多得多。

### 脱敏深度

| 项目 | CatPawClaw | KimiClaw | HuoshanClaw |
|------|:-:|:-:|:-:|
| 脱敏占位符总数 | **92** | 2 | 3 |
| 脱敏字段配置数 | **30** | 0（硬编码） | 0（硬编码） |
| session中的token清理 | ✅ | ❌ 不备份session | ❌ 不备份session |
| PEM私钥清理 | ✅ | ❌ | ❌ |
| 深度安全扫描 | ✅ | ❌ | ❌ |

**大白话**：CatPawClaw脱敏了92处，另外两个只脱了2-3处。原因很简单——它们备份的文件少，需要脱敏的自然也少。但反过来说，如果它们以后加了session备份，脱敏就成了大问题。

### 代码质量

| 项目 | CatPawClaw | KimiClaw | HuoshanClaw |
|------|:-:|:-:|:-:|
| 代码行数 | 833行 | 196行 | 539行 |
| 配置与代码分离 | ✅ paths.json驱动 | ❌ 写死在脚本里 | 部分（有config但不完整） |
| 自测命令 | ✅ 12项 | ✅ 有test | ❌ 没有 |
| macOS兼容 | ✅ uname检测 | ❌ | ❌ |

---

## 二、各家做得好的地方

**别误会，不是CatPawClaw什么都最好。**

### KimiClaw 做得好的
- **极简**：196行代码搞定核心功能，没有多余的东西。如果只是个人日常备份，够用了
- **rsync**：用rsync做文件同步，天然支持增量，比cp更专业
- **输出干净**：快照目录结构清晰，没有多余文件

### HuoshanClaw 做得好的
- **压缩打包**：zstd压缩 + tar打包，生成单个文件方便传输，这个思路CatPawClaw没做
- **加密**：AES-256加密快照，适合敏感环境。CatPawClaw只做脱敏不做加密
- **格式兼容**：声称能导入KimiClaw和CatPawClaw的快照，虽然实现粗糙但思路对

### CatPawClaw 做得好的
- **覆盖最全**：91个文件 vs 13/22个，差距巨大
- **配置驱动**：加个文件只要改JSON，不用改代码
- **脱敏最深**：30个字段pattern + session深度清洗
- **自测最完整**：12项自动化测试

---

## 三、核心问题：做成一样的，还是各走各的？

**结论：应该做成一样的。**

原因很简单：这三个方案解决的是同一个问题——把OpenClaw的状态完整备份下来，换个地方能恢复。不存在"A方案适合场景X，B方案适合场景Y"的情况。

### 最佳方案 = 取长补短

不是直接复制CatPawClaw，而是把三家的优点合并：

| 来源 | 取什么 |
|------|--------|
| CatPawClaw | 配置驱动架构、完整覆盖列表、session脱敏、自测框架 |
| KimiClaw | rsync同步（替代cp，天然增量） |
| HuoshanClaw | zstd压缩打包（生成单文件，方便传输）、AES加密选项 |

### 合并后的"统一方案"长什么样

```
shadowclaw snapshot -o ./backup          # 生成快照（91+文件，配置驱动）
shadowclaw snapshot --pack               # 打包成单文件 (来自HuoshanClaw)
shadowclaw snapshot --encrypt KEY        # 加密 (来自HuoshanClaw)
shadowclaw restore ./backup              # 恢复
shadowclaw verify ./backup               # 验证
shadowclaw cron --interval 6h            # 定时
shadowclaw diff ./backup                 # 对比
shadowclaw test                          # 自测
```

**底层用rsync同步（来自KimiClaw），配置用paths.json（来自CatPawClaw），输出支持tar.zst压缩（来自HuoshanClaw）。**

### 执行路径

最省力的方式：以CatPawClaw为基础，加两个功能：
1. `--pack` 打包压缩（20行代码）
2. `--encrypt` 加密（10行代码）
3. 把cp替换为rsync（改1个函数）

然后三个目录都用这同一份代码，区别只在commit前缀。

---

## 四、为什么分数会出现差距

不是能力问题，是**策略选择**的差异：

- **CatPawClaw** 从一开始就走"配置驱动"路线，加功能只改JSON，迭代很快
- **KimiClaw** 走"极简"路线，核心功能精炼但覆盖面窄，后期追赶时发现架构不好扩展
- **HuoshanClaw** 走"功能堆叠"路线，加了压缩加密等高级功能，但基础覆盖反而没做全

**如果重来一次**，正确的做法是：先把"该备份什么"用配置文件列清楚（这是CatPawClaw做对的），再考虑"怎么备份更好"（压缩/加密/rsync）。

---

**报告完。建议下一步：统一方案，三份代码合一。**
