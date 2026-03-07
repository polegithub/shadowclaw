---
title: 重型组件使用动态导入
impact: 关键
impactDescription: 直接影响 TTI 和 LCP
tags: bundle, dynamic-import, code-splitting, 懒加载
---

## 重型组件使用动态导入

使用动态导入来懒加载初始渲染时不需要的大型组件。

**错误（Monaco 与主包一起打包，约 300KB）：**

```tsx
import { MonacoEditor } from './monaco-editor'

function CodePanel({ code }: { code: string }) {
  return <MonacoEditor value={code} />
}
```

**正确（Monaco 按需加载）：**

```tsx
import { lazy, Suspense } from 'react'

const MonacoEditor = lazy(() => 
  import('./monaco-editor').then(m => ({ default: m.MonacoEditor }))
)

function CodePanel({ code }: { code: string }) {
  return (
    <Suspense fallback={<div>加载编辑器...</div>}>
      <MonacoEditor value={code} />
    </Suspense>
  )
}
```
