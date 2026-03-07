---
title: 批量 DOM CSS 更改
impact: 中等
impactDescription: 减少重排/重绘
tags: js, dom, css, 性能, 重排
---

## 批量 DOM CSS 更改

避免一次更改一个样式属性。通过类或 `cssText` 将多个 CSS 更改分组在一起，以最小化浏览器重排。

**错误（多次重排）：**

```typescript
function updateElementStyles(element: HTMLElement) {
  // 每行都触发重排
  element.style.width = '100px'
  element.style.height = '200px'
  element.style.backgroundColor = 'blue'
  element.style.border = '1px solid black'
}
```

**正确（添加类 - 单次重排）：**

```typescript
// CSS 文件
.highlighted-box {
  width: 100px;
  height: 200px;
  background-color: blue;
  border: 1px solid black;
}

// JavaScript
function updateElementStyles(element: HTMLElement) {
  element.classList.add('highlighted-box')
}
```

**正确（更改 cssText - 单次重排）：**

```typescript
function updateElementStyles(element: HTMLElement) {
  element.style.cssText = `
    width: 100px;
    height: 200px;
    background-color: blue;
    border: 1px solid black;
  `
}
```

**React 示例：**

```tsx
// 错误：逐个更改样式
function Box({ isHighlighted }: { isHighlighted: boolean }) {
  const ref = useRef<HTMLDivElement>(null)
  
  useEffect(() => {
    if (ref.current && isHighlighted) {
      ref.current.style.width = '100px'
      ref.current.style.height = '200px'
      ref.current.style.backgroundColor = 'blue'
    }
  }, [isHighlighted])
  
  return <div ref={ref}>内容</div>
}

// 正确：切换类
function Box({ isHighlighted }: { isHighlighted: boolean }) {
  return (
    <div className={isHighlighted ? 'highlighted-box' : ''}>
      内容
    </div>
  )
}
```

尽可能优先使用 CSS 类而不是内联样式。类由浏览器缓存并提供更好的关注点分离。
