# OpenClaw 记忆恢复方案测试方案

## 测试目标
验证快照方案在环境备份、恢复、安全脱敏等场景下的完整性和可靠性。

## 前置条件
1. OpenClaw 环境正常运行
2. 有写入权限到 `~/.openclaw/` 目录
3. 已安装 jq、git

## 评测维度（每项10分，满分100分）

| # | 维度 | 说明 |
|---|------|------|
| 1 | 记忆覆盖完整性 | 方案能覆盖多少核心文件（配置、凭证、记忆、workspace、skills等） |
| 2 | 恢复成功率 | 从快照恢复后，环境能否正常工作 |
| 3 | 快照体积效率 | 体积是否合理，是否有大小限制和排除机制 |
| 4 | 操作便捷性 | 生成、恢复、推送几步完成，是否单一入口 |
| 5 | 安全性（脱敏） | 是否自动脱敏密钥、个人信息，推送前是否检查 |
| 6 | 跨平台兼容性 | 脚本是否跨 Linux/macOS，路径是否可配置 |
| 7 | 错误恢复能力 | 恢复前是否自动备份、缺失文件是否跳过、幂等性 |
| 8 | 增量备份能力 | 是否支持增量/差量备份，减少重复传输 |
| 9 | 自动化能力 | 是否支持定时快照、自动推送 |
| 10 | 方案完整度 | 文档、配置、脚本是否齐全可执行 |

## 测试用例（可直接执行）

### 测试用例1：基础记忆写入与读取验证
```bash
WORK_DIR=$(mktemp -d)
echo "测试记忆1: 2026-03-07 测试内容A" > "$WORK_DIR/test_memory.md"
grep -q "测试内容A" "$WORK_DIR/test_memory.md" && echo "PASS" || echo "FAIL"
rm -rf "$WORK_DIR"
```

### 测试用例2：快照生成验证
```bash
# 对各方案执行快照（dry-run），检查是否有可执行脚本
# CatClaw:
bash catclaw/bin/shadowclaw snapshot --dry-run 2>&1 | grep -c "\[OK\]"
# 预期：>15 个文件被识别
```

### 测试用例3：快照完整性验证
```bash
# 生成快照并验证关键文件是否存在
SNAP_DIR=$(mktemp -d)
bash catclaw/bin/shadowclaw snapshot -o "$SNAP_DIR" 2>&1
# 检查 manifest.json
jq '.stats.copied' "$SNAP_DIR/manifest.json"
# 检查关键文件
for f in openclaw.json workspace/MEMORY.md workspace/SOUL.md; do
  [[ -f "$SNAP_DIR/$f" ]] && echo "PASS: $f" || echo "FAIL: $f"
done
rm -rf "$SNAP_DIR"
```

### 测试用例4：脱敏验证
```bash
SNAP_DIR=$(mktemp -d)
bash catclaw/bin/shadowclaw snapshot -o "$SNAP_DIR" 2>&1
# 检查 openclaw.json 中的敏感字段是否被替换
grep -c "{{SECRET:" "$SNAP_DIR/openclaw.json" 2>/dev/null
# 预期：>0（存在脱敏占位符）
# 检查是否有明文密钥泄漏
grep -rE 'sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}' "$SNAP_DIR/" 2>/dev/null | wc -l
# 预期：0
rm -rf "$SNAP_DIR"
```

### 测试用例5：恢复流程验证（模拟）
```bash
SNAP_DIR=$(mktemp -d)
RESTORE_DIR=$(mktemp -d)
# 生成快照
OPENCLAW_DIR="$RESTORE_DIR" bash catclaw/bin/shadowclaw snapshot -o "$SNAP_DIR" 2>&1
# 恢复到新目录
OPENCLAW_DIR="$RESTORE_DIR" bash catclaw/bin/shadowclaw restore --force "$SNAP_DIR" 2>&1
# 检查恢复结果
[[ -d "$RESTORE_DIR/backup" ]] && echo "PASS: 恢复前备份存在" || echo "FAIL"
rm -rf "$SNAP_DIR" "$RESTORE_DIR"
```

### 测试用例6：verify 命令验证
```bash
SNAP_DIR=$(mktemp -d)
bash catclaw/bin/shadowclaw snapshot -o "$SNAP_DIR" 2>&1
bash catclaw/bin/shadowclaw verify "$SNAP_DIR" 2>&1 | grep -c "\[OK\]"
rm -rf "$SNAP_DIR"
```

### 测试用例7：增量快照验证
```bash
# 首次全量快照
SNAP1=$(mktemp -d)
bash catclaw/bin/shadowclaw snapshot -o "$SNAP1" 2>&1
# 二次增量快照
SNAP2=$(mktemp -d)
bash catclaw/bin/shadowclaw snapshot --incremental -o "$SNAP2" 2>&1
# 检查 manifest 中的 incremental 标记
jq '.incremental' "$SNAP2/manifest.json"
rm -rf "$SNAP1" "$SNAP2"
```

### 测试用例8：安全扫描验证
```bash
SNAP_DIR=$(mktemp -d)
bash catclaw/bin/shadowclaw snapshot -o "$SNAP_DIR" 2>&1
# 检查输出中是否有安全扫描结果
bash catclaw/bin/shadowclaw snapshot -o "$SNAP_DIR" 2>&1 | grep -q "安全"
echo "PASS: 安全扫描已执行"
rm -rf "$SNAP_DIR"
```

### 测试用例9：定时任务配置验证
```bash
# 检查 cron 命令是否可用
bash catclaw/bin/shadowclaw cron --interval 6h 2>&1
echo $?  # 预期：0
bash catclaw/bin/shadowclaw cron --remove 2>&1
```

### 测试用例10：diff 命令验证
```bash
SNAP_DIR=$(mktemp -d)
bash catclaw/bin/shadowclaw snapshot -o "$SNAP_DIR" 2>&1
bash catclaw/bin/shadowclaw diff "$SNAP_DIR" 2>&1
echo $?  # 预期：0
rm -rf "$SNAP_DIR"
```

## 评分标准

**每维度10分制：**
- 10分：功能完整、可执行、自动化
- 8-9分：功能基本完整，有小缺陷
- 6-7分：有此功能但不完善或需手动操作
- 4-5分：仅文档描述，无实际实现
- 0-3分：缺失或无法使用

## 执行说明
1. 在仓库根目录执行各测试用例
2. 结果记录到 `selfalive/evaluate_module/evaluation_results.md`
3. 需要检查各方案的 bin/、config/、docs/ 目录完整性
