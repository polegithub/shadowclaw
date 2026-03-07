---
title: 防止水合不匹配而不闪烁
impact: 中等
impactDescription: 避免视觉闪烁和水合错误
tags: rendering, hydration, localStorage, 闪烁
---

## 防止水合不匹配而不闪烁

当渲染依赖客户端存储（localStorage、cookies）的内容时，通过在 React 水合之前注入同步脚本更新 DOM，避免 SSR 中断和水合后闪烁。

**错误（中断 SSR）：**

```tsx
function ThemeWrapper({ children }: { children: ReactNode }) {
  // localStorage 在服务器上不可用 - 抛出错误
  const theme = localStorage.getItem('theme') || 'light'
  
  return (
    <div className={theme}>
      {children}
    </div>
  )
}
```

服务器端渲染会失败，因为 `localStorage` 未定义。

**错误（视觉闪烁）：**

```tsx
function ThemeWrapper({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState('light')
  
  useEffect(() => {
    // 在水合后运行 - 导致可见闪烁
    const stored = localStorage.getItem('theme')
    if (stored) {
      setTheme(stored)
    }
  }, [])
  
  return (
    <div className={theme}>
      {children}
    </div>
  )
}
```

组件首先使用默认值（`light`）渲染，然后在水合后更新，导致可见的错误内容闪烁。

**正确（无闪烁，无水合不匹配）：**

```tsx
function ThemeWrapper({ children }: { children: ReactNode }) {
  return (
    <>
      <div id="theme-wrapper">
        {children}
      </div>
      <script
        dangerouslySetInnerHTML={{
          __html: `
            (function() {
              try {
                var theme = localStorage.getItem('theme') || 'light';
                var el = document.getElementById('theme-wrapper');
                if (el) el.className = theme;
              } catch (e) {}
            })();
          `,
        }}
      />
    </>
  )
}
```

内联脚本在显示元素之前同步执行，确保 DOM 已经具有正确的值。无闪烁，无水合不匹配。

这种模式对于主题切换、用户偏好、身份验证状态以及任何应该立即渲染而不闪烁默认值的仅客户端数据特别有用。
