---
title: 使用 SWR 实现自动去重
impact: 中高
impactDescription: 自动去重
tags: client, swr, 去重, 数据获取
---

## 使用 SWR 实现自动去重

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

**对于不可变数据：**

```tsx
import useSWR from 'swr'

function StaticContent() {
  const { data } = useSWR('/api/config', fetcher, {
    revalidateOnFocus: false,
    revalidateOnReconnect: false
  })
}
```

**对于变更操作：**

```tsx
import { useSWRMutation } from 'swr/mutation'

async function updateUser(url: string, { arg }: { arg: any }) {
  return fetch(url, {
    method: 'PUT',
    body: JSON.stringify(arg)
  }).then(r => r.json())
}

function UpdateButton() {
  const { trigger } = useSWRMutation('/api/user', updateUser)
  return <button onClick={() => trigger({ name: 'New Name' })}>更新</button>
}
```

参考：[SWR 文档](https://swr.vercel.app)
