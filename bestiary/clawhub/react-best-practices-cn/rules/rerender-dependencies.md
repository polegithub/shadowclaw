---
title: 缩小 Effect 依赖项
impact: 低
impactDescription: 最小化 effect 重新运行
tags: rerender, useEffect, dependencies, 优化
---

## 缩小 Effect 依赖项

指定基本类型依赖项而不是对象，以最小化 effect 重新运行。

**错误（user 的任何字段更改都会重新运行）：**

```tsx
useEffect(() => {
  console.log(user.id)
}, [user])
```

**正确（仅在 id 更改时重新运行）：**

```tsx
useEffect(() => {
  console.log(user.id)
}, [user.id])
```

**对于派生状态，在 effect 外部计算：**

```tsx
// 错误：在 width=767, 766, 765... 时运行
useEffect(() => {
  if (width < 768) {
    enableMobileMode()
  }
}, [width])

// 正确：仅在布尔值转换时运行
const isMobile = width < 768
useEffect(() => {
  if (isMobile) {
    enableMobileMode()
  }
}, [isMobile])
```
