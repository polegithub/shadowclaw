---
title: 为重复查找构建索引 Map
impact: 中低
impactDescription: 1M 次操作降至 2K 次
tags: js, map, 查找, 性能优化
---

## 为重复查找构建索引 Map

通过相同键进行多次 `.find()` 调用应使用 Map。

**错误（每次查找 O(n)）：**

```typescript
function processOrders(orders: Order[], users: User[]) {
  return orders.map(order => ({
    ...order,
    user: users.find(u => u.id === order.userId)
  }))
}
```

**正确（每次查找 O(1)）：**

```typescript
function processOrders(orders: Order[], users: User[]) {
  const userById = new Map(users.map(u => [u.id, u]))

  return orders.map(order => ({
    ...order,
    user: userById.get(order.userId)
  }))
}
```

构建 map 一次（O(n)），然后所有查找都是 O(1)。

对于 1000 个订单 × 1000 个用户：1M 次操作 → 2K 次操作。
