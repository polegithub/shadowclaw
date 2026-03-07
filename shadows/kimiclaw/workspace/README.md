# ShadowClaw

OpenClaw 环境快照与恢复方案

## 简介

ShadowClaw 是一个用于备份和恢复 OpenClaw 环境的工具集，支持完整的环境迁移和快速恢复。

## 目录结构

```
.
├── .gitignore          # Git 忽略规则
├── README.md           # 本文件
└── kimiclaw/           # 核心工具与备份内容
    ├── README.md       # 详细使用文档
    ├── bin/            # CLI 工具
    ├── lib/            # 脚本库
    ├── config/         # 配置文件
    ├── workspace/      # OpenClaw 工作区文件
    ├── skills/         # 自定义 Skills
    ├── memory/         # 记忆文件
    └── snapshot/       # 历史快照
```

## 快速开始

```bash
cd kimiclaw
./bin/kimiclaw --help
```

## 详细文档

见 [kimiclaw/README.md](kimiclaw/README.md)

## License

MIT
