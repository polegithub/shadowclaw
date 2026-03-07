#!/usr/bin/env bash
#
# ShadowClaw Skill 测试套件
# 用途：验证 skill 安装后快照/恢复/脱敏/增量/定时/diff 全链路可用
# 执行：bash skills/shadowclaw/tests/run_tests.sh
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SHADOWCLAW="${SKILL_DIR}/scripts/shadowclaw.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

pass=0; fail=0; total=0

assert() {
  local desc="$1"; shift
  (( total++ )) || true
  if "$@" >/dev/null 2>&1; then
    echo -e "  ${GREEN}✅ PASS${NC}: $desc"
    (( pass++ )) || true
  else
    echo -e "  ${RED}❌ FAIL${NC}: $desc"
    (( fail++ )) || true
  fi
}

assert_output() {
  local desc="$1" pattern="$2"; shift 2
  (( total++ )) || true
  local output
  output=$("$@" 2>&1)
  if echo "$output" | grep -qE "$pattern"; then
    echo -e "  ${GREEN}✅ PASS${NC}: $desc"
    (( pass++ )) || true
  else
    echo -e "  ${RED}❌ FAIL${NC}: $desc (期望匹配: $pattern)"
    (( fail++ )) || true
  fi
}

echo -e "${CYAN}━━━ ShadowClaw Skill 测试 ━━━${NC}"
echo ""

# ─────────────────────────────────────
echo -e "${CYAN}T1: 脚本可执行${NC}"
assert "help 命令正常返回" bash "$SHADOWCLAW" help
assert "version 命令正常返回" bash "$SHADOWCLAW" version
# 多行输出逐个检查关键命令
assert "help 包含 snapshot" bash -c "bash '$SHADOWCLAW' help 2>&1 | grep -q snapshot"
assert "help 包含 restore" bash -c "bash '$SHADOWCLAW' help 2>&1 | grep -q restore"
assert "help 包含 verify" bash -c "bash '$SHADOWCLAW' help 2>&1 | grep -q verify"
assert "help 包含 diff" bash -c "bash '$SHADOWCLAW' help 2>&1 | grep -q diff"
assert "help 包含 cron" bash -c "bash '$SHADOWCLAW' help 2>&1 | grep -q cron"

# ─────────────────────────────────────
echo ""
echo -e "${CYAN}T2: 快照生成${NC}"
SNAP=$(mktemp -d)
assert "snapshot 生成成功" bash "$SHADOWCLAW" snapshot -o "$SNAP"
assert "manifest.json 存在" test -f "$SNAP/manifest.json"
assert "manifest 包含 file_hashes" bash -c "jq -e '.file_hashes | length > 0' '$SNAP/manifest.json'"
assert "manifest 包含 stats" bash -c "jq -e '.stats.copied > 0' '$SNAP/manifest.json'"
assert "secrets-template.json 存在" test -f "$SNAP/secrets-template.json"

# ─────────────────────────────────────
echo ""
echo -e "${CYAN}T3: 关键文件覆盖${NC}"
for f in openclaw.json workspace/MEMORY.md workspace/SOUL.md workspace/USER.md workspace/AGENTS.md; do
  assert "快照包含 $f" test -f "$SNAP/$f"
done

# ─────────────────────────────────────
echo ""
echo -e "${CYAN}T4: 脱敏安全${NC}"
if [[ -f "$SNAP/openclaw.json" ]]; then
  assert "openclaw.json 存在脱敏占位符" bash -c "grep -q '{{SECRET:' '$SNAP/openclaw.json'"
fi
# 检查明文密钥泄漏
assert "无 GitHub token 泄漏 (ghp_)" bash -c "! grep -rlE 'ghp_[a-zA-Z0-9]{36}' '$SNAP/'"
assert "无 OpenAI key 泄漏 (sk-)" bash -c "! grep -rlE '\"sk-[a-zA-Z0-9]{20,}\"' '$SNAP/'"
assert "无 Bearer token 泄漏" bash -c "! grep -rlE 'Bearer [a-zA-Z0-9._-]{40,}' '$SNAP/'"

# ─────────────────────────────────────
echo ""
echo -e "${CYAN}T5: 恢复能力${NC}"
RESTORE_DIR=$(mktemp -d)
assert "restore --force 执行成功" bash -c "OPENCLAW_DIR='$RESTORE_DIR' bash '$SHADOWCLAW' restore --force '$SNAP'"
assert "恢复前自动备份存在" test -d "$RESTORE_DIR/backup"
# 检查恢复后的文件
assert "恢复后 openclaw.json 存在" test -f "$RESTORE_DIR/openclaw.json"
rm -rf "$RESTORE_DIR"

# ─────────────────────────────────────
echo ""
echo -e "${CYAN}T6: verify 校验${NC}"
assert_output "verify 输出包含通过标记" "验证通过|\\[OK\\]" bash "$SHADOWCLAW" verify "$SNAP"

# ─────────────────────────────────────
echo ""
echo -e "${CYAN}T7: 增量快照${NC}"
SNAP2=$(mktemp -d)
assert "增量快照生成成功" bash "$SHADOWCLAW" snapshot --incremental -o "$SNAP2"
assert "manifest 标记 incremental" bash -c "jq -e '.incremental == true or .incremental == false' '$SNAP2/manifest.json'"
assert "manifest 有 file_hashes" bash -c "jq -e '.file_hashes | length > 0' '$SNAP2/manifest.json'"
rm -rf "$SNAP2"

# ─────────────────────────────────────
echo ""
echo -e "${CYAN}T8: diff 对比${NC}"
assert "diff 命令执行成功" bash "$SHADOWCLAW" diff "$SNAP"

# ─────────────────────────────────────
echo ""
echo -e "${CYAN}T9: 定时快照${NC}"
assert_output "help 中包含 cron/schedule" "cron|schedule" bash "$SHADOWCLAW" help
# 不实际注册 cron，只验证命令解析
assert_output "cron --remove 不报错" "移除|removed|crontab" bash "$SHADOWCLAW" cron --remove

# ─────────────────────────────────────
echo ""
echo -e "${CYAN}T10: dry-run 模式${NC}"
SNAP3=$(mktemp -d)
assert "dry-run 不生成文件" bash -c "bash '$SHADOWCLAW' snapshot --dry-run -o '$SNAP3' && [ ! -f '$SNAP3/manifest.json' ]"
rm -rf "$SNAP3"

# ─────────────────────────────────────
echo ""
echo -e "${CYAN}T11: 配置可覆盖${NC}"
assert "SHADOWCLAW_CONFIG 环境变量可用" bash -c "SHADOWCLAW_CONFIG='$SKILL_DIR/config/default.json' bash '$SHADOWCLAW' help"

# ─────────────────────────────────────
echo ""
echo -e "${CYAN}T12: 内置自测${NC}"
assert "test 命令 12/12 通过" bash "$SHADOWCLAW" test

# 清理
rm -rf "$SNAP"

# ─────────────────────────────────────
echo ""
echo -e "${CYAN}━━━ 测试结果 ━━━${NC}"
echo -e "  通过: ${GREEN}$pass${NC} / $total | 失败: ${RED}$fail${NC}"
echo ""

if (( fail == 0 )); then
  echo -e "${GREEN}🎉 全部通过${NC}"
  exit 0
else
  echo -e "${RED}存在 $fail 个失败${NC}"
  exit 1
fi
