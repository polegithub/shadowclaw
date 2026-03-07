---
title: 提取到记忆化组件
impact: 中等
impactDescription: 启用提前返回
tags: rerender, memo, useMemo, 优化
---

## 提取到记忆化组件

将昂贵的工作提取到记忆化组件中，以在计算之前启用提前返回。

**错误（即使在加载时也计算头像）：**

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

**注意：** 如果你的项目启用了 [React Compiler](https://react.dev/learn/react-compiler)，则不需要手动使用 `memo()` 和 `useMemo()` 进行记忆化。编译器会自动优化重渲染。
