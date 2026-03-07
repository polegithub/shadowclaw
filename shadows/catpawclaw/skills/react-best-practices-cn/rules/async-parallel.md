---
title: 独立操作使用 Promise.all()
impact: 关键
impactDescription: 2-10倍性能提升
tags: async, 并行化, promises, 瀑布流
---

## 独立操作使用 Promise.all()

当异步操作之间没有相互依赖时，使用 `Promise.all()` 并发执行它们。

**错误（顺序执行，3次往返）：**

```typescript
const user = await fetchUser()
const posts = await fetchPosts()
const comments = await fetchComments()
```

**正确（并行执行，1次往返）：**

```typescript
const [user, posts, comments] = await Promise.all([
  fetchUser(),
  fetchPosts(),
  fetchComments()
])
```
