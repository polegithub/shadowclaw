---
title: localStorage 数据版本化和最小化
impact: 中等
impactDescription: 防止模式冲突，减少存储大小
tags: client, localStorage, 版本化, 数据管理
---

## localStorage 数据版本化和最小化

为键添加版本前缀并仅存储需要的字段。防止模式冲突和意外存储敏感数据。

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

// 从 v1 迁移到 v2
function migrate() {
  try {
    const v1 = localStorage.getItem('userConfig:v1')
    if (v1) {
      const old = JSON.parse(v1)
      saveConfig({ theme: old.darkMode ? 'dark' : 'light', language: old.lang })
      localStorage.removeItem('userConfig:v1')
    }
  } catch {}
}
```

**从服务器响应中存储最少字段：**

```typescript
// User 对象有 20+ 个字段，仅存储 UI 需要的内容
function cachePrefs(user: FullUser) {
  try {
    localStorage.setItem('prefs:v1', JSON.stringify({
      theme: user.preferences.theme,
      notifications: user.preferences.notifications
    }))
  } catch {}
}
```

**始终使用 try-catch 包装：** `getItem()` 和 `setItem()` 在隐私浏览模式（Safari、Firefox）、配额超出或被禁用时会抛出异常。

**优点：** 通过版本化实现模式演进，减少存储大小，防止存储令牌/PII/内部标志。
