---
title: 缓存重复函数调用
impact: 中等
impactDescription: 避免冗余计算
tags: js, 缓存, 性能, 记忆化
---

## 缓存重复函数调用

当在渲染期间使用相同输入重复调用相同函数时，使用模块级 Map 缓存函数结果。

**错误（冗余计算）：**

```typescript
function ProjectList({ projects }: { projects: Project[] }) {
  return (
    <div>
      {projects.map(project => {
        // slugify() 对相同项目名称调用 100+ 次
        const slug = slugify(project.name)
        
        return <ProjectCard key={project.id} slug={slug} />
      })}
    </div>
  )
}
```

**正确（缓存结果）：**

```typescript
// 模块级缓存
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
        // 每个唯一项目名称仅计算一次
        const slug = cachedSlugify(project.name)
        
        return <ProjectCard key={project.id} slug={slug} />
      })}
    </div>
  )
}
```

**单值函数的更简单模式：**

```typescript
let isLoggedInCache: boolean | null = null

function isLoggedIn(): boolean {
  if (isLoggedInCache !== null) {
    return isLoggedInCache
  }
  
  isLoggedInCache = document.cookie.includes('auth=')
  return isLoggedInCache
}

// 身份验证更改时清除缓存
function onAuthChange() {
  isLoggedInCache = null
}
```

使用 Map（不是 hook），这样它可以在任何地方工作：工具函数、事件处理程序，不仅仅是 React 组件。
