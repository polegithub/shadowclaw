---
title: 使用 toSorted() 而非 sort() 实现不可变性
impact: 中高
impactDescription: 防止 React 状态中的变异错误
tags: js, 不可变性, sort, toSorted, React 状态
---

## 使用 toSorted() 而非 sort() 实现不可变性

`.sort()` 会就地变异数组，这可能导致 React 状态和 props 出现错误。使用 `.toSorted()` 创建新的排序数组而不进行变异。

**错误（变异原始数组）：**

```typescript
function UserList({ users }: { users: User[] }) {
  // 变异 users prop 数组！
  const sorted = useMemo(
    () => users.sort((a, b) => a.name.localeCompare(b.name)),
    [users]
  )
  return <div>{sorted.map(renderUser)}</div>
}
```

**正确（创建新数组）：**

```typescript
function UserList({ users }: { users: User[] }) {
  // 创建新的排序数组，原始数组不变
  const sorted = useMemo(
    () => users.toSorted((a, b) => a.name.localeCompare(b.name)),
    [users]
  )
  return <div>{sorted.map(renderUser)}</div>
}
```

**为什么这在 React 中很重要：**

1. Props/状态变异破坏了 React 的不可变性模型 - React 期望 props 和状态被视为只读
2. 导致陈旧闭包错误 - 在闭包（回调、effects）内变异数组可能导致意外行为

**浏览器支持：旧浏览器的回退**

```typescript
// 旧浏览器的回退
const sorted = [...items].sort((a, b) => a.value - b.value)
```

`.toSorted()` 在所有现代浏览器中可用（Chrome 110+、Safari 16+、Firefox 115+、Node.js 20+）。对于旧环境，使用扩展运算符。

**其他不可变数组方法：**

- `.toSorted()` - 不可变排序
- `.toReversed()` - 不可变反转
- `.toSpliced()` - 不可变拼接
- `.with()` - 不可变元素替换
