# 飞书群消息处理技能总结

> 如何配置、接受和排查飞书群消息，以及消息去重与重复处理问题

---

## 核心概念

飞书插件处理群消息时，有两个层面的检查：

1. **群白名单** (`groupPolicy` + `groupAllowFrom`) - 决定是否接收群消息
2. **用户白名单** (`allowFrom`) - 决定是否响应特定用户
3. **消息去重** - 防止同一条消息被重复处理

---

## 配置方式

### 方式1：openclaw.json 配置（推荐）

```json
"channels": {
  "feishu": {
    "appId": "cli_xxx",
    "appSecret": "xxx",
    "dmPolicy": "pairing",
    "groupPolicy": "open",           // open | allowlist | disabled
    "groupAllowFrom": ["*"],         // 群ID列表，["*"]表示所有群
    "requireMention": true,          // 是否需要@机器人
    "enabled": true,
    "connectionMode": "websocket"
  }
}
```

**groupPolicy 选项**：
- `"open"` - 允许所有群（最宽松）
- `"allowlist"` - 只允许白名单中的群
- `"disabled"` - 禁用群消息

### 方式2：feishu-allowFrom.json 配置

文件位置：`~/.openclaw/credentials/feishu-allowFrom.json`

```json
{
  "version": 1,
  "allowFrom": [
    "ou_xxx",          // 用户ID
    "oc_xxx",          // 群ID
    "*"                // 通配符允许所有
  ]
}
```

⚠️ **注意**：此文件主要用于用户级白名单，群白名单建议使用 `openclaw.json` 配置。

---

## 消息重复问题与去重

### 问题背景

飞书等 IM 平台可能因为网络抖动、重试机制等原因，**多次发送同一条消息**。如果不做去重，会导致：
- 同一条指令被执行多次
- 重复回复，用户体验差
- 重复修改配置，导致状态错乱

### 真实案例

**场景**：用户发送 "把群白名单加进去：oc_xxx"
- **02:12** - 第一次收到，正常处理 ✓
- **02:18** - 同一消息再次收到，再次处理 ❌（重复添加）
- **03:18** - 再次收到，再次处理 ❌
- **09:18** - Gateway 重启后再次收到，再次处理 ❌

### 去重机制实现

**文件**：`~/.openclaw/extensions/feishu/src/dedup.ts`

```typescript
// 双层去重策略

// 第一层：内存缓存（快）
const processedMessageIds = new Map<string, number>();

// 第二层：Session 历史（持久化，跨重启有效）
export function isMessageInSessionHistory(
  messageId: string,
  sessionDir: string = "/root/.openclaw/agents/main/sessions",
): boolean {
  // 扫描24小时内的 session 文件
  // 检查是否已处理过该 messageId
}
```

### 关键陷阱 ⚠️

**错误做法**（会导致误拦截）：
```typescript
// 不要这样做！
if (text.includes(messageId) || text.includes(senderOpenId)) {
  return true; // 拦截
}
```

**原因**：检查 `senderOpenId` 会导致**同一用户的所有消息**都被当成重复消息拦截！

**正确做法**：
```typescript
// 只检查 messageId
if (text.includes(messageId)) {
  return true; // 拦截
}
```

### 去重流程

```
收到飞书消息
    ↓
1. 内存缓存检查（Map）
   ↓ 命中？→ 跳过（重复）
   未命中
    ↓
2. Session 历史检查（文件）
   ↓ 命中？→ 跳过（重复）
   未命中
    ↓
3. 处理消息
    ↓
4. 记录到内存缓存
```

### 性能优化

- **24小时窗口**：只检查最近24小时的 session 文件
- **每文件最多1000行**：只检查最近的消息
- **内存缓存1000条**：LRU淘汰机制

---

## 排查步骤

### 问题1：收不到群消息

**检查清单**：

1. **机器人在群里吗？**
   - 飞书群设置 → 群管理 → 添加机器人

2. **事件订阅配置了吗？**
   - 飞书开放平台 → 事件订阅 → 添加 `im.message.receive_v1`

3. **权限申请了吗？**
   - `im:message.group_at_msg:readonly` - 读取群@消息
   - `im:message:send_as_bot` - 发送消息

4. **配置生效了吗？**
   - 修改配置后必须重启：`openclaw gateway restart`

5. **去重机制误拦截？**
   - 检查是否错误地使用了 `senderOpenId` 检查

### 问题2：只能收到1条消息，之后收不到

**可能原因**：
- 去重逻辑错误地检查了 `senderOpenId`
- 内存缓存没有清理

**解决方法**：
```typescript
// 只检查 messageId，不要检查 senderOpenId
if (text.includes(messageId)) {
  return true;
}
```

### 问题3：收到消息但没有响应

**查看日志**：
```bash
journalctl -u openclaw --since "5 minutes ago" | grep feishu
```

**常见错误**：
```
group oc_xxx not in groupAllowFrom (groupPolicy=allowlist)
```
→ 群不在白名单中，添加群ID到 `groupAllowFrom`

```
sender ou_xxx not in group xxx sender allowlist
```
→ 用户不在群的白名单中

```
feishu: skipping duplicate message xxx (checked memory + session history)
```
→ 消息被正确去重，如果是误拦截，检查去重逻辑

### 问题4：能收到但回复失败

**错误代码**：
- `99991672` - 缺少权限 `im:message` 或 `im:message.reactions:write_only`
- `230011` - 其他权限问题

→ 去飞书开放平台申请相应权限

---

## 日志分析

### 成功接收的日志
```
[feishu] feishu[default]: received message from ou_xxx in oc_xxx (group)
[feishu] feishu[default]: dispatching to agent (session=agent:main:main)
```

### 被去重拦截的日志
```
[feishu] feishu: skipping duplicate message xxx (checked memory + session history)
```

### 被群白名单拦截的日志
```
[feishu] feishu[default]: received message from ou_xxx in oc_xxx (group)
[feishu] feishu[default]: group oc_xxx not in groupAllowFrom (groupPolicy=allowlist)
```

### 回复失败的日志
```
[feishu] feishu[default] final reply failed: AxiosError: Request failed with status code 400
msg: 'Access denied. One of the following scopes is required: [im:message]'
```

---

## 最佳实践

### 配置层面

1. **开发测试用 open 模式**
   ```json
   "groupPolicy": "open"
   ```

2. **生产环境用 allowlist**
   ```json
   "groupPolicy": "allowlist",
   "groupAllowFrom": ["oc_xxx", "oc_yyy"]
   ```

3. **配置修改后必须重启**
   ```bash
   openclaw gateway restart
   ```

### 去重层面

4. **只检查 messageId**
   - 不要检查 senderOpenId
   - 不要检查时间戳

5. **使用双层去重**
   - 内存缓存：快速检查
   - Session 历史：持久化检查

6. **定期清理缓存**
   - 内存缓存：30分钟TTL
   - 文件检查：24小时窗口

### 调试层面

7. **查看实时日志**
   ```bash
   journalctl -u openclaw -f | grep feishu
   ```

8. **检查 session 文件**
   ```bash
   ls -lt ~/.openclaw/agents/main/sessions/*.jsonl | head -5
   ```

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `~/.openclaw/openclaw.json` | 主配置，包含 groupPolicy |
| `~/.openclaw/credentials/feishu-allowFrom.json` | 用户/群白名单 |
| `~/.openclaw/extensions/feishu/src/dedup.ts` | 消息去重逻辑 |
| `~/.openclaw/extensions/feishu/src/bot.ts` | 消息处理主逻辑 |
| `~/.openclaw/agents/main/sessions/*.jsonl` | Session 历史文件 |

---

## 经验教训

### 今日教训（2026-03-07）

1. **消息去重必须做**，否则会遇到重复处理的问题
2. **去重只检查 messageId**，检查 senderOpenId 会导致误拦截
3. **双层去重更可靠**：内存 + 文件持久化
4. **修改配置后必须重启** gateway 才能生效

### 昨日教训（2026-03-06）

1. 群消息需要正确配置 `groupPolicy` 和 `groupAllowFrom`
2. 机器人和事件订阅权限要到位
3. `requireMention: true` 时需要用户@机器人

---

*最后更新: 2026-03-07*
*KimiClaw*
