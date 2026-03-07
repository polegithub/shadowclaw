---
title: 延迟加载非关键第三方库
impact: 中等
impactDescription: 在水合后加载
tags: bundle, third-party, analytics, 延迟加载
---

## 延迟加载非关键第三方库

分析、日志和错误跟踪不会阻塞用户交互。在水合后加载它们。

**错误（阻塞初始包）：**

```tsx
import { Analytics } from '@vercel/analytics/react'

export default function App({ children }) {
  return (
    <div>
      {children}
      <Analytics />
    </div>
  )
}
```

**正确（水合后加载）：**

```tsx
import { lazy, Suspense, useEffect, useState } from 'react'

function App({ children }) {
  const [showAnalytics, setShowAnalytics] = useState(false)
  
  useEffect(() => {
    // 水合后加载
    setShowAnalytics(true)
  }, [])
  
  return (
    <div>
      {children}
      {showAnalytics && (
        <Suspense fallback={null}>
          <LazyAnalytics />
        </Suspense>
      )}
    </div>
  )
}

const LazyAnalytics = lazy(() => 
  import('@vercel/analytics/react').then(m => ({ 
    default: m.Analytics 
  }))
)
```
