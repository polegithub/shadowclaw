# feishu-quote-debug

飞书引用消息排查与诊断 Skill。当机器人在飞书群聊中收不到引用（quote/reply）消息的原文内容时，使用本 skill 进行排查。

## 背景

OpenClaw 飞书插件在处理消息时，会通过 `event.message.parent_id` 识别引用关系，并调用飞书 Open API `GET /im/v1/messages/{message_id}` 获取被引用消息的内容。获取成功后，会在 agent 收到的消息体前拼接 `[Replying to: "..."]` 前缀。

## 已知问题

### 1. interactive 卡片消息无法正确解析

**现象**：用户引用了一条飞书机器人发送的 interactive 卡片消息（包含图片、按钮等富内容），agent 侧收不到有效的引用内容。

**根因**：`getMessageFeishu()` 在解析消息内容时，只对 `msg_type === "text"` 做了 `parsed.text` 提取。对于 `msg_type === "interactive"` 的卡片消息，`body.content` 是一段 JSON 结构（含 `elements`、`image_key` 等），解析后不是可读文本。

**代码位置**：`extensions/feishu/src/send.ts` — `getMessageFeishu()` 函数

```typescript
// 当前逻辑（只处理 text 类型）
let content = item.body?.content ?? "";
try {
  const parsed = JSON.parse(content);
  if (item.msg_type === "text" && parsed.text) {
    content = parsed.text;
  }
} catch {
  // Keep raw content if parsing fails
}
```

**影响范围**：所有非 text 类型的被引用消息，包括：
- `interactive`（卡片消息）— 最常见，机器人回复通常是卡片
- `image`（纯图片）
- `post`（富文本）
- `file`、`audio`、`media` 等

### 2. parent_id 未传递到 agent 上下文（极少数情况）

**现象**：飞书 webhook event 中包含 `parent_id`，但 agent 的 inbound context 中没有体现引用关系。

**排查步骤**：
1. 通过飞书 API 直接查询该 message_id，确认 `parent_id` 字段是否存在
2. 检查 OpenClaw gateway 日志中是否有 `fetched quoted message` 或 `failed to fetch quoted message` 记录
3. 确认飞书应用是否具备 `im:message` 或 `im:message:readonly` 权限

## 排查流程

### Step 1: 确认 API 权限

```bash
# 获取 tenant_access_token
curl -X POST https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal \
  -H "Content-Type: application/json" \
  -d '{"app_id":"YOUR_APP_ID","app_secret":"YOUR_APP_SECRET"}'

# 用 token 查询目标消息
curl https://open.feishu.cn/open-apis/im/v1/messages/{message_id} \
  -H "Authorization: Bearer {tenant_access_token}"
```

如果返回 `code: 0`，说明权限正常。

### Step 2: 检查被引用消息类型

在 API 返回结果中查看：
- `msg_type`：如果是 `interactive`、`image`、`post` 等非 text 类型，就是已知问题
- `parent_id`：确认引用关系确实存在

### Step 3: 验证 agent 侧接收

在 agent 的 inbound context 中搜索 `[Replying to:` 前缀。如果不存在，说明引用内容未被传递。

## 修复建议

在 `getMessageFeishu()` 中增加对其他消息类型的解析：

```typescript
let content = item.body?.content ?? "";
try {
  const parsed = JSON.parse(content);
  if (item.msg_type === "text" && parsed.text) {
    content = parsed.text;
  } else if (item.msg_type === "interactive") {
    // 提取卡片中的文本元素
    content = extractTextFromCard(parsed);
  } else if (item.msg_type === "post") {
    // 提取富文本中的纯文本
    content = extractTextFromPost(parsed);
  } else if (item.msg_type === "image") {
    content = "[图片消息]";
  } else if (item.msg_type === "file") {
    content = "[文件消息]";
  }
} catch {
  // Keep raw content if parsing fails
}

function extractTextFromCard(card: any): string {
  const texts: string[] = [];
  const walk = (node: any) => {
    if (!node) return;
    if (node.tag === "text" || node.tag === "lark_md") {
      if (node.text || node.content) texts.push(node.text || node.content);
    }
    if (Array.isArray(node)) node.forEach(walk);
    if (node.elements) walk(node.elements);
    if (Array.isArray(node)) node.forEach((n: any) => walk(n));
  };
  walk(card.elements || card);
  return texts.join("\n") || "[卡片消息]";
}

function extractTextFromPost(post: any): string {
  const texts: string[] = [];
  const content = post?.zh_cn?.content || post?.en_us?.content || post?.content || [];
  for (const line of content) {
    for (const item of line) {
      if (item.tag === "text") texts.push(item.text || "");
      if (item.tag === "a") texts.push(item.text || item.href || "");
    }
  }
  return texts.join("") || "[富文本消息]";
}
```

## 相关文件

| 文件 | 说明 |
|------|------|
| `extensions/feishu/src/send.ts` | `getMessageFeishu()` — 获取并解析消息内容 |
| `extensions/feishu/src/bot.ts` | `buildFeishuAgentBody()` — 拼接 `[Replying to:]` 前缀 |
| `extensions/feishu/src/bot.ts` L845-865 | 获取引用消息并传入 agent body 的主流程 |

## 权限要求

飞书应用需要以下权限之一：
- `im:message`（消息读写）
- `im:message:readonly`（消息只读）

在飞书开放平台 → 应用详情 → 权限管理中配置。
