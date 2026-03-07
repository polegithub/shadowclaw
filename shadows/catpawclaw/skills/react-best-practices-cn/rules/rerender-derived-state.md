---
title: 订阅派生状态
impact: 中等
impactDescription: 减少重渲染频率
tags: rerender, derived-state, 优化, 订阅
---

## 订阅派生状态

订阅派生的布尔状态而不是连续值，以减少重渲染频率。

**错误（每个像素变化都重渲染）：**

```tsx
function Sidebar() {
  const width = useWindowWidth()  // 持续更新
  const isMobile = width < 768
  return <nav className={isMobile ? 'mobile' : 'desktop'} />
}
```

**正确（仅在布尔值更改时重渲染）：**

```tsx
function Sidebar() {
  const isMobile = useMediaQuery('(max-width: 767px)')
  return <nav className={isMobile ? 'mobile' : 'desktop'} />
}
```
