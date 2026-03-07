---
title: 使用函数式 setState 更新
impact: 中等
impactDescription: 防止陈旧闭包和不必要的回调重建
tags: rerender, setState, 函数式更新, 闭包
---

## 使用函数式 setState 更新

当基于当前状态值更新状态时，使用 setState 的函数式更新形式，而不是直接引用状态变量。这可以防止陈旧闭包，消除不必要的依赖项，并创建稳定的回调引用。

**错误（需要状态作为依赖项）：**

```tsx
function TodoList() {
  const [items, setItems] = useState(initialItems)
  
  // 回调必须依赖 items，每次 items 更改都会重建
  const addItems = useCallback((newItems: Item[]) => {
    setItems([...items, ...newItems])
  }, [items])  // ❌ items 依赖导致重建
  
  // 如果忘记依赖项，会有陈旧闭包的风险
  const removeItem = useCallback((id: string) => {
    setItems(items.filter(item => item.id !== id))
  }, [])  // ❌ 缺少 items 依赖 - 将使用陈旧的 items！
  
  return <ItemsEditor items={items} onAdd={addItems} onRemove={removeItem} />
}
```

第一个回调在每次 `items` 更改时都会重建，这可能导致子组件不必要地重渲染。第二个回调有陈旧闭包错误 - 它将始终引用初始的 `items` 值。

**正确（稳定的回调，无陈旧闭包）：**

```tsx
function TodoList() {
  const [items, setItems] = useState(initialItems)
  
  // 稳定的回调，永不重建
  const addItems = useCallback((newItems: Item[]) => {
    setItems(curr => [...curr, ...newItems])
  }, [])  // ✅ 不需要依赖项
  
  // 始终使用最新状态，无陈旧闭包风险
  const removeItem = useCallback((id: string) => {
    setItems(curr => curr.filter(item => item.id !== id))
  }, [])  // ✅ 安全且稳定
  
  return <ItemsEditor items={items} onAdd={addItems} onRemove={removeItem} />
}
```

**优点：**

1. **稳定的回调引用** - 状态更改时不需要重建回调
2. **无陈旧闭包** - 始终操作最新的状态值
3. **更少的依赖项** - 简化依赖数组并减少内存泄漏
4. **防止错误** - 消除最常见的 React 闭包错误来源

**何时使用函数式更新：**

- 任何依赖当前状态值的 setState
- 在 useCallback/useMemo 中需要状态时
- 引用状态的事件处理程序
- 更新状态的异步操作

**何时直接更新即可：**

- 设置状态为静态值：`setCount(0)`
- 仅从 props/参数设置状态：`setName(newName)`
- 状态不依赖先前值

**注意：** 如果你的项目启用了 [React Compiler](https://react.dev/learn/react-compiler)，编译器可以自动优化某些情况，但为了正确性和防止陈旧闭包错误，仍然建议使用函数式更新。
