# ShadowClaw

OpenClaw 环境快照与恢复方案。

## 目录结构

```
.
├── skills/shadowclaw/              ← 最终方案（OpenClaw skill 格式）
│   ├── SKILL.md
│   ├── scripts/shadowclaw.sh
│   ├── config/default.json
│   ├── docs/design.md
│   └── tests/                      ← 评测与测试
│       ├── benchmark.sh
│       ├── test_plan.md
│       └── reports/                ← 历史评测报告
│
├── shadows/                        ← 各龙虾真实快照落地
│   ├── catpawclaw/
│   ├── kimiclaw/
│   ├── huoshanclaw/
│   └── MIGRATION_CHECKLIST.md
│
├── archive/                        ← 历史方案存档（只读参考）
│   ├── catpawclaw/
│   ├── kimiclaw/
│   ├── huoshanclaw/
│   └── misc/                       ← 根目录散文件 + evaluate_module 原始备份
│
└── README.md
```

## 快速开始

```bash
bash skills/shadowclaw/scripts/shadowclaw.sh snapshot -o ./my-snapshot
bash skills/shadowclaw/scripts/shadowclaw.sh restore --force ./my-snapshot
bash skills/shadowclaw/scripts/shadowclaw.sh help
```
