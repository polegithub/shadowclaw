---
title: 使用 Set/Map 进行 O(1) 查找
impact: 中低
impactDescription: O(n) 降至 O(1)
tags: js, set, map, 查找, 性能
---

## 使用 Set/Map 进行 O(1) 查找

将数组转换为 Set/Map 以进行重复的成员检查。

**错误（每次检查 O(n)）：**

```typescript
const allowedIds = ['a', 'b', 'c', ...]
items.filter(item => allowedIds.includes(item.id))
```

**正确（每次检查 O(1)）：**

```typescript
const allowedIds = new Set(['a', 'b', 'c', ...])
items.filter(item => allowedIds.has(item.id))
```
