# 飞书群消息处理技能总结

> 如何配置、接受和排查飞书群消息

---

## 核心概念

飞书插件处理群消息时，有两个层面的检查：

1. **群白名单** (`groupPolicy` + `groupAllowFrom`) - 决定是否接收群消息
2. **用户白名单** (`allowFrom`) - 决定是否响应特定用户

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

### 问题2：收到消息但没有响应

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

### 问题3：能收到但回复失败

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

### 被拦截的日志
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

4. **查看实时日志**
   ```bash
   journalctl -u openclaw -f
   ```

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `~/.openclaw/openclaw.json` | 主配置，包含 groupPolicy |
| `~/.openclaw/credentials/feishu-allowFrom.json` | 用户/群白名单 |
| `~/.openclaw/extensions/feishu/` | 飞书插件目录 |

---

*总结时间: 2026-03-07*
*KimiClaw*
