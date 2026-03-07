---
title: 避免桶文件导入
impact: 关键
impactDescription: 200-800ms 导入成本，构建缓慢
tags: bundle, imports, tree-shaking, barrel-files, 性能
---

## 避免桶文件导入

直接从源文件导入而不是从桶文件导入，以避免加载数千个未使用的模块。**桶文件**是重新导出多个模块的入口点（例如，`index.js` 执行 `export * from './module'`）。

流行的图标和组件库在其入口文件中可能有**多达 10,000 个重新导出**。对于许多 React 包，**仅导入它们就需要 200-800ms**，影响开发速度和生产环境的冷启动。

**为什么 tree-shaking 无法解决：** 当库被标记为外部（不打包）时，打包器无法优化它。如果你打包它以启用 tree-shaking，构建会因分析整个模块图而变得非常慢。

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
