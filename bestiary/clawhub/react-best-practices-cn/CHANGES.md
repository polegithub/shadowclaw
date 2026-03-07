# React Best Practices CN - 变更说明

## 概述

本技能包是从 Vercel 的 `react-best-practices` 改编而来，专注于客户端 React 应用，并完全中文化。

## 主要变更

### 1. 移除的内容

#### 完整移除的章节
- **第3章：服务端性能** - 完整移除，包括：
  - `server-cache-lru.md` - LRU 缓存（跨请求）
  - `server-cache-react.md` - React.cache() 去重
  - `server-serialization.md` - RSC 边界序列化最小化
  - `server-parallel-fetching.md` - 组件组合并行获取
  - `server-after-nonblocking.md` - after() 非阻塞操作

#### 移除的异步规则
- `async-api-routes.md` - API 路由中的瀑布流（服务端特定）
- `async-dependencies.md` - better-all 依赖并行化（复杂度高，依赖较少使用）
- `async-suspense-boundaries.md` - Suspense 边界策略（RSC 特定）

#### 移除的包优化规则
- `bundle-conditional.md` - 条件模块加载（部分服务端相关）
- `bundle-preload.md` - 基于用户意图预加载（复杂度较高）

#### 移除的渲染规则
- `rendering-activity.md` - Activity 组件（实验性 API）

#### 移除的 JavaScript 规则
- `js-combine-iterations.md` - 合并数组迭代（较少使用）
- `js-length-check-first.md` - 数组比较前的长度检查（特定场景）
- `js-min-max-loop.md` - 使用循环而非排序求最小/最大值（特定场景）

### 2. 保留的内容

#### 第1章：消除瀑布流（2条规则）
- ✅ `async-defer-await.md` - 延迟 await 直到需要时
- ✅ `async-parallel.md` - Promise.all() 并行操作

#### 第2章：包体积优化（3条规则）
- ✅ `bundle-barrel-imports.md` - 避免桶文件导入
- ✅ `bundle-dynamic-imports.md` - 重型组件使用动态导入
- ✅ `bundle-defer-third-party.md` - 延迟加载非关键第三方库

#### 第3章：客户端数据获取（4条规则）
- ✅ `client-event-listeners.md` - 去重全局事件监听器
- ✅ `client-passive-event-listeners.md` - 被动事件监听器
- ✅ `client-swr-dedup.md` - SWR 自动去重
- ✅ `client-localstorage-schema.md` - localStorage 版本化

#### 第4章：重渲染优化（7条规则）
- ✅ `rerender-defer-reads.md` - 延迟状态读取
- ✅ `rerender-memo.md` - 记忆化组件
- ✅ `rerender-dependencies.md` - 缩小 Effect 依赖
- ✅ `rerender-derived-state.md` - 订阅派生状态
- ✅ `rerender-functional-setstate.md` - 函数式 setState
- ✅ `rerender-lazy-state-init.md` - 惰性状态初始化
- ✅ `rerender-transitions.md` - Transitions

#### 第5章：渲染性能（6条规则）
- ✅ `rendering-animate-svg-wrapper.md` - SVG 包装器动画
- ✅ `rendering-content-visibility.md` - content-visibility
- ✅ `rendering-hoist-jsx.md` - 提升静态 JSX
- ✅ `rendering-svg-precision.md` - SVG 精度优化
- ✅ `rendering-hydration-no-flicker.md` - 防止水合闪烁
- ✅ `rendering-conditional-render.md` - 显式条件渲染

#### 第6章：JavaScript 性能（9条规则）
- ✅ `js-batch-dom-css.md` - 批量 DOM CSS 更改
- ✅ `js-index-maps.md` - 索引 Map
- ✅ `js-cache-property-access.md` - 缓存属性访问
- ✅ `js-cache-function-results.md` - 缓存函数结果
- ✅ `js-cache-storage.md` - 缓存 Storage API
- ✅ `js-early-exit.md` - 提前返回
- ✅ `js-hoist-regexp.md` - 提升 RegExp
- ✅ `js-set-map-lookups.md` - Set/Map 查找
- ✅ `js-tosorted-immutable.md` - toSorted() 不可变性

#### 第7章：高级模式（2条规则）
- ✅ `advanced-event-handler-refs.md` - Refs 存储事件处理程序
- ✅ `advanced-use-latest.md` - useLatest hook

### 3. 翻译质量

所有内容已完全翻译为中文：
- ✅ 规则标题和描述
- ✅ 影响说明
- ✅ 代码注释（保持英文以符合编程习惯）
- ✅ 说明文本
- ✅ 元数据和配置

### 4. 章节重新编号

原始章节 | 新章节 | 说明
---------|--------|------
1. 消除瀑布流 | 1. 消除瀑布流 | 保留，精简规则
2. 包体积优化 | 2. 包体积优化 | 保留，精简规则
3. 服务端性能 | ❌ 移除 | 完全移除
4. 客户端数据获取 | 3. 客户端数据获取 | 保留
5. 重渲染优化 | 4. 重渲染优化 | 保留
6. 渲染性能 | 5. 渲染性能 | 保留，精简规则
7. JavaScript 性能 | 6. JavaScript 性能 | 保留，精简规则
8. 高级模式 | 7. 高级模式 | 保留

## 统计

- **原始规则数量**：45+ 条
- **精简后规则数量**：33 条
- **移除规则数量**：12+ 条
- **移除比例**：约 27%

## 文件结构

```
react-best-practices-cn/
├── AGENTS.md              # 完整编译文档（中文）
├── SKILL.md               # 技能定义（中文）
├── README.md              # 说明文档（中文）
├── metadata.json          # 元数据（中文）
├── CHANGES.md             # 本文件
└── rules/                 # 规则目录
    ├── _sections.md       # 章节定义（中文）
    ├── async-*.md         # 异步规则（2个）
    ├── bundle-*.md        # 包优化规则（3个）
    ├── client-*.md        # 客户端规则（4个）
    ├── rerender-*.md      # 重渲染规则（7个）
    ├── rendering-*.md     # 渲染规则（6个）
    ├── js-*.md            # JS 性能规则（9个）
    └── advanced-*.md      # 高级规则（2个）
```

## 使用建议

### 适用场景
- ✅ 客户端 React 应用（Create React App、Vite 等）
- ✅ SPA（单页应用）
- ✅ 使用 React Router 的应用
- ✅ 纯客户端渲染的应用

### 不适用场景
- ❌ Next.js 应用（建议使用原始版本）
- ❌ 服务端渲染应用
- ❌ React Server Components
- ❌ API 路由开发

## 致谢

原始内容由 Vercel 的 [@shuding](https://x.com/shuding) 创建。
本版本专注于客户端 React 应用并完全中文化。
