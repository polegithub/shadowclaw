---
title: 在 Refs 中存储事件处理程序
impact: 低
impactDescription: 稳定的订阅
tags: advanced, refs, event-handlers, 稳定性
---

## 在 Refs 中存储事件处理程序

当在不应在回调更改时重新订阅的 effects 中使用回调时，将回调存储在 refs 中。

**错误（每次渲染都重新订阅）：**

```tsx
function useWindowEvent(event: string, handler: () => void) {
  useEffect(() => {
    window.addEventListener(event, handler)
    return () => window.removeEventListener(event, handler)
  }, [event, handler])
}
```

**正确（稳定的订阅）：**

```tsx
import { useEffectEvent } from 'react'

function useWindowEvent(event: string, handler: () => void) {
  const onEvent = useEffectEvent(handler)

  useEffect(() => {
    window.addEventListener(event, onEvent)
    return () => window.removeEventListener(event, onEvent)
  }, [event])
}
```

**替代方案：如果你使用最新的 React，使用 `useEffectEvent`：**

`useEffectEvent` 为相同模式提供了更清晰的 API：它创建一个稳定的函数引用，始终调用处理程序的最新版本。
