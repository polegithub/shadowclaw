---
name: react-best-practices-cn
description: 客户端 React 应用的性能优化指南（中文版）。当编写、审查或重构 React 代码以确保最佳性能模式时使用此技能。触发场景包括涉及 React 组件、数据获取、包优化或性能改进的任务。
license: MIT
metadata:
  author: 基于 Vercel 改造
  version: "1.0.0"
---

# React 最佳实践（中文版）

针对客户端 React 应用的综合性能优化指南。包含 7 个类别的 30+ 条规则，按影响优先级排序，从关键优化（消除瀑布流、减少包体积）到增量改进（高级模式）。

## 何时应用

在以下情况下参考这些指南：
- 编写新的 React 组件
- 实现数据获取（客户端）
- 审查代码以查找性能问题
- 重构现有 React 代码
- 优化包大小或加载时间

## 按优先级分类的规则

| 优先级 | 类别 | 影响 | 前缀 |
|--------|------|------|------|
| 1 | 消除瀑布流 | 关键 | `async-` |
| 2 | 包体积优化 | 关键 | `bundle-` |
| 3 | 客户端数据获取 | 中高 | `client-` |
| 4 | 重渲染优化 | 中等 | `rerender-` |
| 5 | 渲染性能 | 中等 | `rendering-` |
| 6 | JavaScript 性能 | 中低 | `js-` |
| 7 | 高级模式 | 低 | `advanced-` |

## 快速参考

### 1. 消除瀑布流（关键）

- `async-defer-await` - 将 await 移到实际使用的分支中
- `async-parallel` - 对独立操作使用 Promise.all()

### 2. 包体积优化（关键）

- `bundle-barrel-imports` - 直接导入，避免桶文件
- `bundle-dynamic-imports` - 对重型组件使用动态导入
- `bundle-defer-third-party` - 在水合后加载分析/日志

### 3. 客户端数据获取（中高）

- `client-swr-dedup` - 使用 SWR 实现自动请求去重
- `client-event-listeners` - 去重全局事件监听器
- `client-passive-event-listeners` - 使用被动监听器提升滚动性能
- `client-localstorage-schema` - localStorage 数据版本化和最小化

### 4. 重渲染优化（中等）

- `rerender-defer-reads` - 不要订阅仅在回调中使用的状态
- `rerender-memo` - 将昂贵的工作提取到记忆化组件
- `rerender-dependencies` - 在 effects 中使用基本类型依赖
- `rerender-derived-state` - 订阅派生的布尔值，而非原始值
- `rerender-functional-setstate` - 使用函数式 setState 实现稳定回调
- `rerender-lazy-state-init` - 为昂贵值传递函数给 useState
- `rerender-transitions` - 对非紧急更新使用 startTransition

### 5. 渲染性能（中等）

- `rendering-animate-svg-wrapper` - 动画 div 包装器，而非 SVG 元素
- `rendering-content-visibility` - 对长列表使用 content-visibility
- `rendering-hoist-jsx` - 在组件外提取静态 JSX
- `rendering-svg-precision` - 减少 SVG 坐标精度
- `rendering-hydration-no-flicker` - 使用内联脚本处理仅客户端数据
- `rendering-conditional-render` - 使用三元运算符，而非 && 进行条件渲染

### 6. JavaScript 性能（中低）

- `js-batch-dom-css` - 通过类或 cssText 分组 CSS 更改
- `js-index-maps` - 为重复查找构建 Map
- `js-cache-property-access` - 在循环中缓存对象属性
- `js-cache-function-results` - 在模块级 Map 中缓存函数结果
- `js-cache-storage` - 缓存 localStorage/sessionStorage 读取
- `js-set-map-lookups` - 使用 Set/Map 进行 O(1) 查找
- `js-tosorted-immutable` - 使用 toSorted() 实现不可变性
- `js-early-exit` - 从函数提前返回
- `js-hoist-regexp` - 在循环外提升 RegExp 创建

### 7. 高级模式（低）

- `advanced-event-handler-refs` - 在 refs 中存储事件处理程序
- `advanced-use-latest` - useLatest 用于稳定的回调引用

## 如何使用

阅读单个规则文件以获取详细说明和代码示例：

```
rules/async-parallel.md
rules/bundle-barrel-imports.md
rules/_sections.md
```

每个规则文件包含：
- 为什么重要的简要说明
- 带说明的错误代码示例
- 带说明的正确代码示例
- 附加上下文和参考

## 完整编译文档

完整指南（所有规则已展开）：`AGENTS.md`
