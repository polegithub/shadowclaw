---
title: 提升 RegExp 创建
impact: 中低
impactDescription: 避免重新创建
tags: js, regexp, 提升, 性能
---

## 提升 RegExp 创建

不要在渲染中创建 RegExp。提升到模块作用域或使用 `useMemo()` 记忆化。

**错误（每次渲染都创建新 RegExp）：**

```tsx
function Highlighter({ text, query }: Props) {
  const regex = new RegExp(`(${query})`, 'gi')
  const parts = text.split(regex)
  return <>{parts.map((part, i) => ...)}</>
}
```

**正确（记忆化或提升）：**

```tsx
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

function Highlighter({ text, query }: Props) {
  const regex = useMemo(
    () => new RegExp(`(${escapeRegex(query)})`, 'gi'),
    [query]
  )
  const parts = text.split(regex)
  return <>{parts.map((part, i) => ...)}</>
}
```

**警告：全局正则表达式有可变状态**

```typescript
const regex = /foo/g
regex.test('foo')  // true, lastIndex = 3
regex.test('foo')  // false, lastIndex = 0
```

全局正则表达式（`/g`）有可变的 `lastIndex` 状态。
