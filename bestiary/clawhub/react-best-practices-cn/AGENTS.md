# React 最佳实践（中文版）

**版本 1.0.0**  
基于 Vercel Engineering 改编  
2026年1月

> **注意：**  
> 本文档主要供 AI 助手和 LLM 在维护、生成或重构客户端 React 代码库时遵循。
> 人类也可能觉得有用，但这里的指导针对 AI 辅助工作流的自动化和一致性进行了优化。

---

## 摘要

针对客户端 React 应用的综合性能优化指南，专为 AI 助手和 LLM 设计。包含 7 个类别的 30+ 条规则，按影响优先级排序，从关键优化（消除瀑布流、减少包体积）到增量改进（高级模式）。每条规则都包含详细说明、对比错误与正确实现的实际示例，以及具体的影响指标，用于指导自动化重构和代码生成。

**本版本特点：**
- 专注于客户端 React 应用
- 移除了所有服务端渲染和 Next.js 特定内容
- 完全中文化，保持技术准确性

---

## 目录

1. [消除瀑布流](#1-消除瀑布流) — **关键**
   - 1.1 [延迟 Await 直到需要时](#11-延迟-await-直到需要时)
   - 1.2 [独立操作使用 Promise.all()](#12-独立操作使用-promiseall)
2. [包体积优化](#2-包体积优化) — **关键**
   - 2.1 [避免桶文件导入](#21-避免桶文件导入)
   - 2.2 [重型组件使用动态导入](#22-重型组件使用动态导入)
   - 2.3 [延迟加载非关键第三方库](#23-延迟加载非关键第三方库)
3. [客户端数据获取](#3-客户端数据获取) — **中高**
   - 3.1 [去重全局事件监听器](#31-去重全局事件监听器)
   - 3.2 [滚动性能使用被动事件监听器](#32-滚动性能使用被动事件监听器)
   - 3.3 [使用 SWR 实现自动去重](#33-使用-swr-实现自动去重)
   - 3.4 [localStorage 数据版本化和最小化](#34-localstorage-数据版本化和最小化)
4. [重渲染优化](#4-重渲染优化) — **中等**
   - 4.1 [将状态读取延迟到使用点](#41-将状态读取延迟到使用点)
   - 4.2 [提取到记忆化组件](#42-提取到记忆化组件)
   - 4.3 [缩小 Effect 依赖项](#43-缩小-effect-依赖项)
   - 4.4 [订阅派生状态](#44-订阅派生状态)
   - 4.5 [使用函数式 setState 更新](#45-使用函数式-setstate-更新)
   - 4.6 [使用惰性状态初始化](#46-使用惰性状态初始化)
   - 4.7 [非紧急更新使用 Transitions](#47-非紧急更新使用-transitions)
5. [渲染性能](#5-渲染性能) — **中等**
   - 5.1 [动画 SVG 包装器而非 SVG 元素](#51-动画-svg-包装器而非-svg-元素)
   - 5.2 [长列表使用 CSS content-visibility](#52-长列表使用-css-content-visibility)
   - 5.3 [提升静态 JSX 元素](#53-提升静态-jsx-元素)
   - 5.4 [优化 SVG 精度](#54-优化-svg-精度)
   - 5.5 [防止水合不匹配而不闪烁](#55-防止水合不匹配而不闪烁)
   - 5.6 [使用显式条件渲染](#56-使用显式条件渲染)
6. [JavaScript 性能](#6-javascript-性能) — **中低**
   - 6.1 [批量 DOM CSS 更改](#61-批量-dom-css-更改)
   - 6.2 [为重复查找构建索引 Map](#62-为重复查找构建索引-map)
   - 6.3 [循环中缓存属性访问](#63-循环中缓存属性访问)
   - 6.4 [缓存重复函数调用](#64-缓存重复函数调用)
   - 6.5 [缓存 Storage API 调用](#65-缓存-storage-api-调用)
   - 6.6 [函数提前返回](#66-函数提前返回)
   - 6.7 [提升 RegExp 创建](#67-提升-regexp-创建)
   - 6.8 [使用 Set/Map 进行 O(1) 查找](#68-使用-setmap-进行-o1-查找)
   - 6.9 [使用 toSorted() 而非 sort() 实现不可变性](#69-使用-tosorted-而非-sort-实现不可变性)
7. [高级模式](#7-高级模式) — **低**
   - 7.1 [在 Refs 中存储事件处理程序](#71-在-refs-中存储事件处理程序)
   - 7.2 [useLatest 用于稳定的回调引用](#72-uselatest-用于稳定的回调引用)

---

## 1. 消除瀑布流

**影响：关键**

瀑布流是性能杀手第一名。每个顺序 await 都会增加完整的网络延迟。消除它们能带来最大收益。

### 1.1 延迟 Await 直到需要时

**影响：高（避免阻塞未使用的代码路径）**

将 `await` 操作移到实际使用它们的分支中，避免阻塞不需要它们的代码路径。

**错误（阻塞两个分支）：**

```typescript
async function handleRequest(userId: string, skipProcessing: boolean) {
  const userData = await fetchUserData(userId)
  
  if (skipProcessing) {
    // 立即返回但仍然等待了 userData
    return { skipped: true }
  }
  
  // 只有这个分支使用 userData
  return processUserData(userData)
}
```

**正确（仅在需要时阻塞）：**

```typescript
async function handleRequest(userId: string, skipProcessing: boolean) {
  if (skipProcessing) {
    // 立即返回，无需等待
    return { skipped: true }
  }
  
  // 仅在需要时获取
  const userData = await fetchUserData(userId)
  return processUserData(userData)
}
```

当跳过的分支经常被执行，或延迟的操作开销很大时，这种优化特别有价值。

### 1.2 独立操作使用 Promise.all()

**影响：关键（2-10倍性能提升）**

当异步操作之间没有相互依赖时，使用 `Promise.all()` 并发执行它们。

**错误（顺序执行，3次往返）：**

```typescript
const user = await fetchUser()
const posts = await fetchPosts()
const comments = await fetchComments()
```

**正确（并行执行，1次往返）：**

```typescript
const [user, posts, comments] = await Promise.all([
  fetchUser(),
  fetchPosts(),
  fetchComments()
])
```

---

## 2. 包体积优化

**影响：关键**

减少初始包体积可以改善交互时间和最大内容绘制。

### 2.1 避免桶文件导入

**影响：关键（200-800ms 导入成本，构建缓慢）**

直接从源文件导入而不是从桶文件导入，以避免加载数千个未使用的模块。**桶文件**是重新导出多个模块的入口点（例如，`index.js` 执行 `export * from './module'`）。

流行的图标和组件库在其入口文件中可能有**多达 10,000 个重新导出**。对于许多 React 包，**仅导入它们就需要 200-800ms**，影响开发速度和生产环境的冷启动。

**错误（导入整个库）：**

```tsx
import { Check, X, Menu } from 'lucide-react'
// 加载 1,583 个模块，开发环境额外耗时约 2.8 秒
// 运行时成本：每次冷启动 200-800ms

import { Button, TextField } from '@mui/material'
// 加载 2,225 个模块，开发环境额外耗时约 4.2 秒
```

**正确（仅导入所需内容）：**

```tsx
import Check from 'lucide-react/dist/esm/icons/check'
import X from 'lucide-react/dist/esm/icons/x'
import Menu from 'lucide-react/dist/esm/icons/menu'
// 仅加载 3 个模块（约 2KB vs 约 1MB）

import Button from '@mui/material/Button'
import TextField from '@mui/material/TextField'
// 仅加载你使用的内容
```

直接导入可提供 15-70% 更快的开发启动速度、28% 更快的构建速度、40% 更快的冷启动速度，以及显著更快的 HMR。

常见受影响的库：`lucide-react`、`@mui/material`、`@mui/icons-material`、`@tabler/icons-react`、`react-icons`、`@headlessui/react`、`@radix-ui/react-*`、`lodash`、`ramda`、`date-fns`、`rxjs`、`react-use`。

### 2.2 重型组件使用动态导入

**影响：关键（直接影响 TTI 和 LCP）**

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

### 2.3 延迟加载非关键第三方库

**影响：中等（在水合后加载）**

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

---

## 3. 客户端数据获取

**影响：中高**

自动去重和高效的数据获取模式可以减少冗余网络请求。

### 3.1 去重全局事件监听器

**影响：低（N 个组件使用单个监听器）**

使用 `useSWRSubscription()` 在组件实例之间共享全局事件监听器。

**错误（N 个实例 = N 个监听器）：**

```tsx
function useKeyboardShortcut(key: string, callback: () => void) {
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.metaKey && e.key === key) {
        callback()
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [key, callback])
}
```

**正确（N 个实例 = 1 个监听器）：**

```tsx
import useSWRSubscription from 'swr/subscription'

// 模块级 Map 跟踪每个键的回调
const keyCallbacks = new Map<string, Set<() => void>>()

function useKeyboardShortcut(key: string, callback: () => void) {
  // 在 Map 中注册此回调
  useEffect(() => {
    if (!keyCallbacks.has(key)) {
      keyCallbacks.set(key, new Set())
    }
    keyCallbacks.get(key)!.add(callback)

    return () => {
      const set = keyCallbacks.get(key)
      if (set) {
        set.delete(callback)
        if (set.size === 0) {
          keyCallbacks.delete(key)
        }
      }
    }
  }, [key, callback])

  useSWRSubscription('global-keydown', () => {
    const handler = (e: KeyboardEvent) => {
      if (e.metaKey && keyCallbacks.has(e.key)) {
        keyCallbacks.get(e.key)!.forEach(cb => cb())
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  })
}
```

### 3.2 滚动性能使用被动事件监听器

**影响：中等（消除事件监听器导致的滚动延迟）**

为触摸和滚轮事件监听器添加 `{ passive: true }` 以实现即时滚动。

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

### 3.3 使用 SWR 实现自动去重

**影响：中高（自动去重）**

SWR 可以在组件实例之间实现请求去重、缓存和重新验证。

**错误（无去重，每个实例都获取）：**

```tsx
function UserList() {
  const [users, setUsers] = useState([])
  useEffect(() => {
    fetch('/api/users')
      .then(r => r.json())
      .then(setUsers)
  }, [])
}
```

**正确（多个实例共享一个请求）：**

```tsx
import useSWR from 'swr'

const fetcher = (url: string) => fetch(url).then(r => r.json())

function UserList() {
  const { data: users } = useSWR('/api/users', fetcher)
}
```

参考：[SWR 文档](https://swr.vercel.app)

### 3.4 localStorage 数据版本化和最小化

**影响：中等（防止模式冲突，减少存储大小）**

为键添加版本前缀并仅存储需要的字段。

**错误：**

```typescript
// 无版本，存储所有内容，无错误处理
localStorage.setItem('userConfig', JSON.stringify(fullUserObject))
const data = localStorage.getItem('userConfig')
```

**正确：**

```typescript
const VERSION = 'v2'

function saveConfig(config: { theme: string; language: string }) {
  try {
    localStorage.setItem(`userConfig:${VERSION}`, JSON.stringify(config))
  } catch {
    // 在隐私浏览、配额超出或禁用时抛出
  }
}

function loadConfig() {
  try {
    const data = localStorage.getItem(`userConfig:${VERSION}`)
    return data ? JSON.parse(data) : null
  } catch {
    return null
  }
}
```

**始终使用 try-catch 包装：** `getItem()` 和 `setItem()` 在隐私浏览模式、配额超出或被禁用时会抛出异常。

---

## 4. 重渲染优化

**影响：中等**

减少不必要的重渲染可以最小化浪费的计算并提高 UI 响应性。

### 4.1 将状态读取延迟到使用点

**影响：中等（避免不必要的订阅）**

如果只在回调中读取动态状态，不要订阅它。

**错误（订阅所有更改）：**

```tsx
function ShareButton({ chatId }: { chatId: string }) {
  const searchParams = useSearchParams()

  const handleShare = () => {
    const ref = searchParams.get('ref')
    shareChat(chatId, { ref })
  }

  return <button onClick={handleShare}>分享</button>
}
```

**正确（按需读取，无订阅）：**

```tsx
function ShareButton({ chatId }: { chatId: string }) {
  const handleShare = () => {
    const params = new URLSearchParams(window.location.search)
    const ref = params.get('ref')
    shareChat(chatId, { ref })
  }

  return <button onClick={handleShare}>分享</button>
}
```

### 4.2 提取到记忆化组件

**影响：中等（启用提前返回）**

将昂贵的工作提取到记忆化组件中，以在计算之前启用提前返回。

**错误（即使在加载时也计算）：**

```tsx
function Profile({ user, loading }: Props) {
  const avatar = useMemo(() => {
    const id = computeAvatarId(user)
    return <Avatar id={id} />
  }, [user])

  if (loading) return <Skeleton />
  return <div>{avatar}</div>
}
```

**正确（加载时跳过计算）：**

```tsx
const UserAvatar = memo(function UserAvatar({ user }: { user: User }) {
  const id = useMemo(() => computeAvatarId(user), [user])
  return <Avatar id={id} />
})

function Profile({ user, loading }: Props) {
  if (loading) return <Skeleton />
  return (
    <div>
      <UserAvatar user={user} />
    </div>
  )
}
```

**注意：** 如果你的项目启用了 [React Compiler](https://react.dev/learn/react-compiler)，则不需要手动记忆化。

### 4.3 缩小 Effect 依赖项

**影响：低（最小化 effect 重新运行）**

指定基本类型依赖项而不是对象。

**错误（任何字段更改都会重新运行）：**

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

### 4.4 订阅派生状态

**影响：中等（减少重渲染频率）**

订阅派生的布尔状态而不是连续值。

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

### 4.5 使用函数式 setState 更新

**影响：中等（防止陈旧闭包和不必要的回调重建）**

使用 setState 的函数式更新形式，而不是直接引用状态变量。

**错误（需要状态作为依赖项）：**

```tsx
function TodoList() {
  const [items, setItems] = useState(initialItems)
  
  const addItems = useCallback((newItems: Item[]) => {
    setItems([...items, ...newItems])
  }, [items])  // ❌ items 依赖导致重建
  
  return <ItemsEditor items={items} onAdd={addItems} />
}
```

**正确（稳定的回调，无陈旧闭包）：**

```tsx
function TodoList() {
  const [items, setItems] = useState(initialItems)
  
  const addItems = useCallback((newItems: Item[]) => {
    setItems(curr => [...curr, ...newItems])
  }, [])  // ✅ 不需要依赖项
  
  return <ItemsEditor items={items} onAdd={addItems} />
}
```

### 4.6 使用惰性状态初始化

**影响：中等（每次渲染都浪费计算）**

为昂贵的初始值向 `useState` 传递一个函数。

**错误（每次渲染都运行）：**

```tsx
function FilteredList({ items }: { items: Item[] }) {
  const [searchIndex, setSearchIndex] = useState(buildSearchIndex(items))
  const [query, setQuery] = useState('')
  
  return <SearchResults index={searchIndex} query={query} />
}
```

**正确（仅运行一次）：**

```tsx
function FilteredList({ items }: { items: Item[] }) {
  const [searchIndex, setSearchIndex] = useState(() => buildSearchIndex(items))
  const [query, setQuery] = useState('')
  
  return <SearchResults index={searchIndex} query={query} />
}
```

### 4.7 非紧急更新使用 Transitions

**影响：中等（保持 UI 响应性）**

将频繁的、非紧急的状态更新标记为 transitions。

**错误（每次滚动都阻塞 UI）：**

```tsx
function ScrollTracker() {
  const [scrollY, setScrollY] = useState(0)
  useEffect(() => {
    const handler = () => setScrollY(window.scrollY)
    window.addEventListener('scroll', handler, { passive: true })
    return () => window.removeEventListener('scroll', handler)
  }, [])
}
```

**正确（非阻塞更新）：**

```tsx
import { startTransition } from 'react'

function ScrollTracker() {
  const [scrollY, setScrollY] = useState(0)
  useEffect(() => {
    const handler = () => {
      startTransition(() => setScrollY(window.scrollY))
    }
    window.addEventListener('scroll', handler, { passive: true })
    return () => window.removeEventListener('scroll', handler)
  }, [])
}
```

---

## 5. 渲染性能

**影响：中等**

优化渲染过程可以减少浏览器需要完成的工作。

### 5.1 动画 SVG 包装器而非 SVG 元素

**影响：低（启用硬件加速）**

许多浏览器对 SVG 元素的 CSS3 动画没有硬件加速。将 SVG 包装在 `<div>` 中并动画包装器。

**错误（直接动画 SVG）：**

```tsx
function LoadingSpinner() {
  return (
    <svg className="animate-spin" width="24" height="24" viewBox="0 0 24 24">
      <circle cx="12" cy="12" r="10" stroke="currentColor" />
    </svg>
  )
}
```

**正确（动画包装器 div）：**

```tsx
function LoadingSpinner() {
  return (
    <div className="animate-spin">
      <svg width="24" height="24" viewBox="0 0 24 24">
        <circle cx="12" cy="12" r="10" stroke="currentColor" />
      </svg>
    </div>
  )
}
```

### 5.2 长列表使用 CSS content-visibility

**影响：高（更快的初始渲染）**

应用 `content-visibility: auto` 以延迟屏幕外渲染。

**CSS：**

```css
.message-item {
  content-visibility: auto;
  contain-intrinsic-size: 0 80px;
}
```

**示例：**

```tsx
function MessageList({ messages }: { messages: Message[] }) {
  return (
    <div className="overflow-y-auto h-screen">
      {messages.map(msg => (
        <div key={msg.id} className="message-item">
          <Avatar user={msg.author} />
          <div>{msg.content}</div>
        </div>
      ))}
    </div>
  )
}
```

对于 1000 条消息，浏览器跳过约 990 个屏幕外项目的布局/绘制（初始渲染快 10 倍）。

### 5.3 提升静态 JSX 元素

**影响：低（避免重新创建）**

将静态 JSX 提取到组件外部以避免重新创建。

**错误（每次渲染都重新创建）：**

```tsx
function Container() {
  return (
    <div>
      {loading && <div className="animate-pulse h-20 bg-gray-200" />}
    </div>
  )
}
```

**正确（重用相同元素）：**

```tsx
const loadingSkeleton = (
  <div className="animate-pulse h-20 bg-gray-200" />
)

function Container() {
  return (
    <div>
      {loading && loadingSkeleton}
    </div>
  )
}
```

### 5.4 优化 SVG 精度

**影响：低（减少文件大小）**

减少 SVG 坐标精度以减小文件大小。

**错误（精度过高）：**

```svg
<path d="M 10.293847 20.847362 L 30.938472 40.192837" />
```

**正确（1 位小数）：**

```svg
<path d="M 10.3 20.8 L 30.9 40.2" />
```

### 5.5 防止水合不匹配而不闪烁

**影响：中等（避免视觉闪烁和水合错误）**

当渲染依赖客户端存储的内容时，通过在 React 水合之前注入同步脚本更新 DOM。

**错误（视觉闪烁）：**

```tsx
function ThemeWrapper({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState('light')
  
  useEffect(() => {
    const stored = localStorage.getItem('theme')
    if (stored) {
      setTheme(stored)
    }
  }, [])
  
  return <div className={theme}>{children}</div>
}
```

**正确（无闪烁）：**

```tsx
function ThemeWrapper({ children }: { children: ReactNode }) {
  return (
    <>
      <div id="theme-wrapper">{children}</div>
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

### 5.6 使用显式条件渲染

**影响：低（防止渲染 0 或 NaN）**

使用显式三元运算符而不是 `&&` 进行条件渲染。

**错误（count 为 0 时渲染 "0"）：**

```tsx
function Badge({ count }: { count: number }) {
  return (
    <div>
      {count && <span className="badge">{count}</span>}
    </div>
  )
}
```

**正确（count 为 0 时不渲染）：**

```tsx
function Badge({ count }: { count: number }) {
  return (
    <div>
      {count > 0 ? <span className="badge">{count}</span> : null}
    </div>
  )
}
```

---

## 6. JavaScript 性能

**影响：中低**

热路径的微优化可以累积成有意义的改进。

### 6.1 批量 DOM CSS 更改

**影响：中等（减少重排/重绘）**

通过类或 `cssText` 将多个 CSS 更改分组在一起。

**错误（多次重排）：**

```typescript
function updateElementStyles(element: HTMLElement) {
  element.style.width = '100px'
  element.style.height = '200px'
  element.style.backgroundColor = 'blue'
  element.style.border = '1px solid black'
}
```

**正确（单次重排）：**

```typescript
function updateElementStyles(element: HTMLElement) {
  element.classList.add('highlighted-box')
}
```

### 6.2 为重复查找构建索引 Map

**影响：中低（1M 次操作降至 2K 次）**

通过相同键进行多次 `.find()` 调用应使用 Map。

**错误（每次查找 O(n)）：**

```typescript
function processOrders(orders: Order[], users: User[]) {
  return orders.map(order => ({
    ...order,
    user: users.find(u => u.id === order.userId)
  }))
}
```

**正确（每次查找 O(1)）：**

```typescript
function processOrders(orders: Order[], users: User[]) {
  const userById = new Map(users.map(u => [u.id, u]))
  return orders.map(order => ({
    ...order,
    user: userById.get(order.userId)
  }))
}
```

### 6.3 循环中缓存属性访问

**影响：中低（减少查找）**

在热路径中缓存对象属性查找。

**错误（3 次查找 × N 次迭代）：**

```typescript
for (let i = 0; i < arr.length; i++) {
  process(obj.config.settings.value)
}
```

**正确（总共 1 次查找）：**

```typescript
const value = obj.config.settings.value
const len = arr.length
for (let i = 0; i < len; i++) {
  process(value)
}
```

### 6.4 缓存重复函数调用

**影响：中等（避免冗余计算）**

使用模块级 Map 缓存函数结果。

**错误（冗余计算）：**

```typescript
function ProjectList({ projects }: { projects: Project[] }) {
  return (
    <div>
      {projects.map(project => {
        const slug = slugify(project.name)
        return <ProjectCard key={project.id} slug={slug} />
      })}
    </div>
  )
}
```

**正确（缓存结果）：**

```typescript
const slugifyCache = new Map<string, string>()

function cachedSlugify(text: string): string {
  if (slugifyCache.has(text)) {
    return slugifyCache.get(text)!
  }
  const result = slugify(text)
  slugifyCache.set(text, result)
  return result
}

function ProjectList({ projects }: { projects: Project[] }) {
  return (
    <div>
      {projects.map(project => {
        const slug = cachedSlugify(project.name)
        return <ProjectCard key={project.id} slug={slug} />
      })}
    </div>
  )
}
```

### 6.5 缓存 Storage API 调用

**影响：中低（减少昂贵的 I/O）**

`localStorage` 和 `sessionStorage` 是同步且昂贵的。在内存中缓存读取。

**错误（每次调用都读取存储）：**

```typescript
function getTheme() {
  return localStorage.getItem('theme') ?? 'light'
}
```

**正确（Map 缓存）：**

```typescript
const storageCache = new Map<string, string | null>()

function getLocalStorage(key: string) {
  if (!storageCache.has(key)) {
    storageCache.set(key, localStorage.getItem(key))
  }
  return storageCache.get(key)
}

function setLocalStorage(key: string, value: string) {
  localStorage.setItem(key, value)
  storageCache.set(key, value)
}
```

### 6.6 函数提前返回

**影响：中低（避免不必要的计算）**

当结果已确定时提前返回。

**错误（即使找到答案后仍处理）：**

```typescript
function validateUsers(users: User[]) {
  let hasError = false
  let errorMessage = ''
  
  for (const user of users) {
    if (!user.email) {
      hasError = true
      errorMessage = 'Email required'
    }
  }
  
  return hasError ? { valid: false, error: errorMessage } : { valid: true }
}
```

**正确（立即返回）：**

```typescript
function validateUsers(users: User[]) {
  for (const user of users) {
    if (!user.email) {
      return { valid: false, error: 'Email required' }
    }
  }
  return { valid: true }
}
```

### 6.7 提升 RegExp 创建

**影响：中低（避免重新创建）**

不要在渲染中创建 RegExp。提升到模块作用域或使用 `useMemo()` 记忆化。

**错误（每次渲染都创建新 RegExp）：**

```tsx
function Highlighter({ text, query }: Props) {
  const regex = new RegExp(`(${query})`, 'gi')
  const parts = text.split(regex)
  return <>{parts.map((part, i) => ...)}</>
}
```

**正确（记忆化）：**

```tsx
function Highlighter({ text, query }: Props) {
  const regex = useMemo(
    () => new RegExp(`(${escapeRegex(query)})`, 'gi'),
    [query]
  )
  const parts = text.split(regex)
  return <>{parts.map((part, i) => ...)}</>
}
```

### 6.8 使用 Set/Map 进行 O(1) 查找

**影响：中低（O(n) 降至 O(1)）**

将数组转换为 Set/Map 以进行重复的成员检查。

**错误（每次检查 O(n)）：**

```typescript
const allowedIds = ['a', 'b', 'c', ...]
items.filter(item => allowedIds.includes(item.id))
```

**正确（每次检查 O(1)）：**

```typescript
const allowedIds = new Set(['a', 'b', 'c', ...])
items.filter(item => allowedIds.has(item.id))
```

### 6.9 使用 toSorted() 而非 sort() 实现不可变性

**影响：中高（防止 React 状态中的变异错误）**

`.sort()` 会就地变异数组。使用 `.toSorted()` 创建新的排序数组。

**错误（变异原始数组）：**

```typescript
function UserList({ users }: { users: User[] }) {
  const sorted = useMemo(
    () => users.sort((a, b) => a.name.localeCompare(b.name)),
    [users]
  )
  return <div>{sorted.map(renderUser)}</div>
}
```

**正确（创建新数组）：**

```typescript
function UserList({ users }: { users: User[] }) {
  const sorted = useMemo(
    () => users.toSorted((a, b) => a.name.localeCompare(b.name)),
    [users]
  )
  return <div>{sorted.map(renderUser)}</div>
}
```

---

## 7. 高级模式

**影响：低**

需要仔细实现的特定场景的高级模式。

### 7.1 在 Refs 中存储事件处理程序

**影响：低（稳定的订阅）**

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

### 7.2 useLatest 用于稳定的回调引用

**影响：低（防止 effect 重新运行）**

在回调中访问最新值而不将它们添加到依赖数组。

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

---

## 参考

1. [React 文档](https://react.dev)
2. [SWR](https://swr.vercel.app)
3. [node-lru-cache](https://github.com/isaacs/node-lru-cache)
