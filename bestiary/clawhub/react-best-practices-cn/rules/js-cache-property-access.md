---
title: 循环中缓存属性访问
impact: 中低
impactDescription: 减少查找
tags: js, 循环, 缓存, 性能
---

## 循环中缓存属性访问

在热路径中缓存对象属性查找。

**错误（3 次查找 × N 次迭代）：**

```typescript
for (let i = 0; i < arr.length; i++) {
  process(obj.config.settings.value)
}
```

**正确（总共 1 次查找）：**

```typescript
const value = obj.config.settings.value
const len = arr.length
for (let i = 0; i < len; i++) {
  process(value)
}
```
