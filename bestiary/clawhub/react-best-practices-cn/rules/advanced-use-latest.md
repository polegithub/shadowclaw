---
title: useLatest 用于稳定的回调引用
impact: 低
impactDescription: 防止 effect 重新运行
tags: advanced, useLatest, 回调, 稳定性
---

## useLatest 用于稳定的回调引用

在回调中访问最新值而不将它们添加到依赖数组。防止 effect 重新运行，同时避免陈旧闭包。

**实现：**

```typescript
function useLatest<T>(value: T) {
  const ref = useRef(value)
  useEffect(() => {
    ref.current = value
  }, [value])
  return ref
}
```

**错误（每次回调更改都重新运行 effect）：**

```tsx
function SearchInput({ onSearch }: { onSearch: (q: string) => void }) {
  const [query, setQuery] = useState('')

  useEffect(() => {
    const timeout = setTimeout(() => onSearch(query), 300)
    return () => clearTimeout(timeout)
  }, [query, onSearch])
}
```

**正确（稳定的 effect，新鲜的回调）：**

```tsx
function SearchInput({ onSearch }: { onSearch: (q: string) => void }) {
  const [query, setQuery] = useState('')
  const onSearchRef = useLatest(onSearch)

  useEffect(() => {
    const timeout = setTimeout(() => onSearchRef.current(query), 300)
    return () => clearTimeout(timeout)
  }, [query])
}
```
