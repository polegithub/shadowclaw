---
title: 滚动性能使用被动事件监听器
impact: 中等
impactDescription: 消除事件监听器导致的滚动延迟
tags: client, event-listeners, passive, 滚动性能
---

## 滚动性能使用被动事件监听器

为触摸和滚轮事件监听器添加 `{ passive: true }` 以实现即时滚动。浏览器通常会等待监听器完成以检查是否调用了 `preventDefault()`，从而导致滚动延迟。

**错误：**

```typescript
useEffect(() => {
  const handleTouch = (e: TouchEvent) => console.log(e.touches[0].clientX)
  const handleWheel = (e: WheelEvent) => console.log(e.deltaY)
  
  document.addEventListener('touchstart', handleTouch)
  document.addEventListener('wheel', handleWheel)
  
  return () => {
    document.removeEventListener('touchstart', handleTouch)
    document.removeEventListener('wheel', handleWheel)
  }
}, [])
```

**正确：**

```typescript
useEffect(() => {
  const handleTouch = (e: TouchEvent) => console.log(e.touches[0].clientX)
  const handleWheel = (e: WheelEvent) => console.log(e.deltaY)
  
  document.addEventListener('touchstart', handleTouch, { passive: true })
  document.addEventListener('wheel', handleWheel, { passive: true })
  
  return () => {
    document.removeEventListener('touchstart', handleTouch)
    document.removeEventListener('wheel', handleWheel)
  }
}, [])
```

**何时使用被动模式：** 跟踪/分析、日志记录、任何不调用 `preventDefault()` 的监听器。

**何时不使用被动模式：** 实现自定义滑动手势、自定义缩放控件，或任何需要 `preventDefault()` 的监听器。
