#!/usr/bin/env bash
#
# ShadowClaw 客观评测脚本 v1.0
# 所有方案跑同一套测试，机器打分，零主观
#
# 用法: bash benchmark.sh [--verbose]
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERBOSE="${1:-}"

# ── Colors ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── Score tracking ──
declare -A SCORES
declare -A DETAILS
TOTAL_POINTS=100  # 10 tests × 10 points each

log()  { echo -e "$*"; }
pass() { log "  ${GREEN}✅ PASS${NC} ($1 pts): $2"; }
fail() { log "  ${RED}❌ FAIL${NC} ( 0 pts): $2"; }
part() { log "  ${YELLOW}⚠️ PART${NC} ($1 pts): $2"; }
section() { log "\n${CYAN}━━━ $* ━━━${NC}"; }

# ── Test runner ──
# Each test outputs a score (0-10) and writes to SCORES[solution]
run_test() {
  local solution="$1" test_name="$2" max_score="$3"
  shift 3
  local score=0
  score=$("$@" 2>/dev/null) || score=0
  # Clamp to max
  (( score > max_score )) && score=$max_score
  (( score < 0 )) && score=0
  SCORES[$solution]=$(( ${SCORES[$solution]:-0} + score ))
  
  if (( score == max_score )); then
    pass "$score" "$test_name"
  elif (( score > 0 )); then
    part "$score" "$test_name (${score}/${max_score})"
  else
    fail "0" "$test_name"
  fi
}

# ══════════════════════════════════════════════════
# TEST 1: 脚本是否能运行 (10分)
# - help 命令返回 exit 0: 5分
# - 有 snapshot/backup 命令: 5分
# ══════════════════════════════════════════════════
test_runnable() {
  local script="$1" snapshot_cmd="$2"
  local score=0
  
  # help 可运行
  if bash "$script" help >/dev/null 2>&1; then
    (( score += 5 ))
  fi
  
  # dry-run 或 --help 显示 snapshot/backup 命令
  if bash "$script" help 2>&1 | grep -qiE "snapshot|backup|generate"; then
    (( score += 5 ))
  fi
  
  echo $score
}

# ══════════════════════════════════════════════════
# TEST 2: 快照生成 (10分)
# - 生成成功 (exit 0): 5分
# - 输出目录非空: 3分
# - 耗时 < 30s: 2分
# ══════════════════════════════════════════════════
test_snapshot() {
  local script="$1" cmd="$2"
  local score=0
  local snap_dir; snap_dir=$(mktemp -d)
  
  local start=$SECONDS
  if bash "$script" $cmd -o "$snap_dir" >/dev/null 2>&1 || \
     OPENCLAW_DIR="$HOME/.openclaw" bash "$script" $cmd "$snap_dir" >/dev/null 2>&1 || \
     bash "$script" $cmd >/dev/null 2>&1; then
    (( score += 5 ))
  fi
  local elapsed=$(( SECONDS - start ))
  
  # Check output has files
  local file_count; file_count=$(find "$snap_dir" -type f 2>/dev/null | wc -l)
  if (( file_count > 5 )); then
    (( score += 3 ))
  elif (( file_count > 0 )); then
    (( score += 1 ))
  fi
  
  # Speed check
  if (( elapsed < 30 )); then
    (( score += 2 ))
  fi
  
  rm -rf "$snap_dir"
  echo $score
}

# ══════════════════════════════════════════════════
# TEST 3: 关键文件覆盖 (10分)
# 检查快照中是否包含核心文件
# 每个关键文件 1分，最多10分
# ══════════════════════════════════════════════════
test_coverage() {
  local script="$1" cmd="$2"
  local score=0
  local snap_dir; snap_dir=$(mktemp -d)
  
  bash "$script" $cmd -o "$snap_dir" >/dev/null 2>&1 || \
    OPENCLAW_DIR="$HOME/.openclaw" bash "$script" $cmd "$snap_dir" >/dev/null 2>&1 || \
    bash "$script" $cmd >/dev/null 2>&1
  
  local checks=(
    "openclaw.json"
    "workspace/SOUL.md"
    "workspace/MEMORY.md"
    "workspace/USER.md"
    "workspace/AGENTS.md"
    "workspace/IDENTITY.md"
    "agents/main/sessions/sessions.json"
    "cron/jobs.json"
    "identity/device.json"
    "workspace/TOOLS.md"
  )
  
  for f in "${checks[@]}"; do
    if find "$snap_dir" -path "*/$f" -type f 2>/dev/null | grep -q .; then
      (( score++ ))
    fi
  done
  
  rm -rf "$snap_dir"
  echo $score
}

# ══════════════════════════════════════════════════
# TEST 4: 脱敏能力 (10分)
# - openclaw.json 中有 {{SECRET: 占位符: 4分
# - 无明文 ghp_ token: 3分
# - 无明文 sk- key: 3分
# ══════════════════════════════════════════════════
test_desensitize() {
  local script="$1" cmd="$2"
  local score=0
  local snap_dir; snap_dir=$(mktemp -d)
  
  bash "$script" $cmd -o "$snap_dir" >/dev/null 2>&1 || \
    OPENCLAW_DIR="$HOME/.openclaw" bash "$script" $cmd "$snap_dir" >/dev/null 2>&1 || \
    bash "$script" $cmd >/dev/null 2>&1
  
  # Check desensitization markers
  if find "$snap_dir" -name "openclaw.json" -exec grep -l '{{SECRET:' {} \; 2>/dev/null | grep -q .; then
    (( score += 4 ))
  fi
  
  # No plaintext GitHub tokens
  local ghp; ghp=$(grep -rlE 'ghp_[a-zA-Z0-9]{10,}' "$snap_dir/" 2>/dev/null | wc -l)
  if (( ghp == 0 )); then
    (( score += 3 ))
  fi
  
  # No plaintext sk- keys
  local sk; sk=$(grep -rlE '"sk-[a-zA-Z0-9]{20,}"' "$snap_dir/" 2>/dev/null | wc -l)
  if (( sk == 0 )); then
    (( score += 3 ))
  fi
  
  rm -rf "$snap_dir"
  echo $score
}

# ══════════════════════════════════════════════════
# TEST 5: 恢复能力 (10分)
# - restore 命令存在: 3分
# - restore 到临时目录成功: 4分
# - 恢复前自动备份: 3分
# ══════════════════════════════════════════════════
test_restore() {
  local script="$1" snap_cmd="$2" restore_cmd="$3"
  local score=0
  local snap_dir; snap_dir=$(mktemp -d)
  local restore_dir; restore_dir=$(mktemp -d)
  
  # Generate snapshot first
  bash "$script" $snap_cmd -o "$snap_dir" >/dev/null 2>&1 || \
    OPENCLAW_DIR="$HOME/.openclaw" bash "$script" $snap_cmd "$snap_dir" >/dev/null 2>&1 || \
    bash "$script" $snap_cmd >/dev/null 2>&1
  
  # Check restore command exists
  if bash "$script" help 2>&1 | grep -qiE "restore"; then
    (( score += 3 ))
  fi
  
  # Try restore
  if OPENCLAW_DIR="$restore_dir" bash "$script" $restore_cmd --force "$snap_dir" >/dev/null 2>&1 || \
     OPENCLAW_DIR="$restore_dir" bash "$script" $restore_cmd "$snap_dir" >/dev/null 2>&1; then
    (( score += 4 ))
  fi
  
  # Check backup was created
  if find "$restore_dir" -type d -name "backup*" 2>/dev/null | grep -q .; then
    (( score += 3 ))
  fi
  
  rm -rf "$snap_dir" "$restore_dir"
  echo $score
}

# ══════════════════════════════════════════════════
# TEST 6: verify 命令 (10分)
# - verify/check 命令存在: 5分
# - verify 对快照执行成功: 5分
# ══════════════════════════════════════════════════
test_verify() {
  local script="$1" snap_cmd="$2"
  local score=0
  local snap_dir; snap_dir=$(mktemp -d)
  
  # Check verify command exists
  if bash "$script" help 2>&1 | grep -qiE "verify|check|validate"; then
    (( score += 5 ))
  fi
  
  # Generate and verify
  bash "$script" $snap_cmd -o "$snap_dir" >/dev/null 2>&1 || true
  if bash "$script" verify "$snap_dir" >/dev/null 2>&1; then
    (( score += 5 ))
  fi
  
  rm -rf "$snap_dir"
  echo $score
}

# ══════════════════════════════════════════════════
# TEST 7: 增量备份 (10分)
# - 支持 incremental flag: 5分
# - manifest 中有文件哈希: 5分
# ══════════════════════════════════════════════════
test_incremental() {
  local script="$1" snap_cmd="$2"
  local score=0
  local snap_dir; snap_dir=$(mktemp -d)
  
  # Check incremental support
  if bash "$script" help 2>&1 | grep -qiE "incremental|增量"; then
    (( score += 5 ))
  fi
  
  # Check manifest has hashes
  bash "$script" $snap_cmd -o "$snap_dir" >/dev/null 2>&1 || true
  if find "$snap_dir" -name "manifest.json" -exec cat {} \; 2>/dev/null | grep -qE '"file_hashes"|"hashes"|"sha256"|"checksum"'; then
    (( score += 5 ))
  fi
  
  rm -rf "$snap_dir"
  echo $score
}

# ══════════════════════════════════════════════════
# TEST 8: 定时快照 (10分)
# - cron/schedule 命令存在: 5分
# - help 中有定时相关说明: 5分
# ══════════════════════════════════════════════════
test_cron() {
  local script="$1"
  local score=0
  
  # Check cron command
  if bash "$script" help 2>&1 | grep -qiE "cron|schedule|定时|timer"; then
    (( score += 5 ))
  fi
  
  # Check cron in command list (not just docs)
  local help_output; help_output=$(bash "$script" help 2>&1)
  if echo "$help_output" | grep -qE "^\s+(cron|schedule)"; then
    (( score += 5 ))
  elif echo "$help_output" | grep -qiE "cron|schedule"; then
    (( score += 3 ))
  fi
  
  echo $score
}

# ══════════════════════════════════════════════════
# TEST 9: diff 对比能力 (10分)
# - diff 命令存在: 5分
# - diff 执行成功: 5分
# ══════════════════════════════════════════════════
test_diff() {
  local script="$1" snap_cmd="$2"
  local score=0
  local snap_dir; snap_dir=$(mktemp -d)
  
  # Check diff command
  if bash "$script" help 2>&1 | grep -qiE "diff|compare|对比"; then
    (( score += 5 ))
  fi
  
  # Try running diff
  bash "$script" $snap_cmd -o "$snap_dir" >/dev/null 2>&1 || true
  if bash "$script" diff "$snap_dir" >/dev/null 2>&1; then
    (( score += 5 ))
  fi
  
  rm -rf "$snap_dir"
  echo $score
}

# ══════════════════════════════════════════════════
# TEST 10: 配置驱动 & 文档完整度 (10分)
# - 有独立配置文件 (json/yaml/toml): 4分
# - 有 README.md: 3分
# - 有设计文档或详细说明: 3分
# ══════════════════════════════════════════════════
test_docs() {
  local solution_dir="$1"
  local score=0
  
  # Config file
  if find "$solution_dir" -name "*.json" -path "*/config/*" 2>/dev/null | grep -q .; then
    (( score += 4 ))
  elif find "$solution_dir" -name "*.json" -not -name "package*.json" 2>/dev/null | grep -q .; then
    (( score += 2 ))
  fi
  
  # README
  if [[ -f "$solution_dir/README.md" ]]; then
    (( score += 3 ))
  fi
  
  # Design doc or detailed docs
  if find "$solution_dir" -name "*.md" -path "*/docs/*" 2>/dev/null | grep -q . || \
     find "$solution_dir" -name "design*" -o -name "ARCHITECTURE*" 2>/dev/null | grep -q .; then
    (( score += 3 ))
  elif find "$solution_dir" -name "*.md" 2>/dev/null | wc -l | grep -qE '^[2-9]|^[0-9]{2,}'; then
    (( score += 1 ))
  fi
  
  echo $score
}

# ══════════════════════════════════════════════════
# MAIN: Run all tests for all solutions
# ══════════════════════════════════════════════════

log "${BOLD}${CYAN}"
log "╔══════════════════════════════════════════════════╗"
log "║   ShadowClaw 客观评测 v1.0  (机器打分)          ║"
log "║   10项测试 × 10分 = 满分100分                    ║"
log "╚══════════════════════════════════════════════════╝"
log "${NC}"

# Define solutions: name | script_path | snapshot_cmd | restore_cmd | solution_dir
declare -a SOLUTIONS=(
  "CatPawClaw|${REPO_DIR}/catclaw/bin/shadowclaw|snapshot|restore|${REPO_DIR}/catclaw"
  "KimiClaw|${REPO_DIR}/kimiclaw/bin/kimiclaw|generate|restore|${REPO_DIR}/kimiclaw"
  "HuoshanClaw|${REPO_DIR}/huoshanclaw/huoshanclaw_super_v1.sh|backup|restore|${REPO_DIR}/huoshanclaw"
)

for sol_def in "${SOLUTIONS[@]}"; do
  IFS='|' read -r name script snap_cmd restore_cmd sol_dir <<< "$sol_def"
  
  section "评测: ${BOLD}$name${NC}"
  SCORES[$name]=0
  
  if [[ ! -f "$script" ]]; then
    log "  ${RED}脚本不存在: $script${NC}"
    continue
  fi
  
  run_test "$name" "T1: 脚本可运行"      10 test_runnable     "$script" "$snap_cmd"
  run_test "$name" "T2: 快照生成"         10 test_snapshot     "$script" "$snap_cmd"
  run_test "$name" "T3: 关键文件覆盖"     10 test_coverage     "$script" "$snap_cmd"
  run_test "$name" "T4: 脱敏能力"         10 test_desensitize  "$script" "$snap_cmd"
  run_test "$name" "T5: 恢复能力"         10 test_restore      "$script" "$snap_cmd" "$restore_cmd"
  run_test "$name" "T6: verify 验证"      10 test_verify       "$script" "$snap_cmd"
  run_test "$name" "T7: 增量备份"         10 test_incremental  "$script" "$snap_cmd"
  run_test "$name" "T8: 定时快照"         10 test_cron         "$script"
  run_test "$name" "T9: diff 对比"        10 test_diff         "$script" "$snap_cmd"
  run_test "$name" "T10: 配置&文档"       10 test_docs         "$sol_dir"
  
  log "  ${BOLD}小计: ${SCORES[$name]}/${TOTAL_POINTS}${NC}"
done

# ── Final scoreboard ──
section "${BOLD}最终排名${NC}"
log ""
log "  ${BOLD}方案            得分     等级${NC}"
log "  ─────────────────────────────────"

# Sort by score
for name in $(for k in "${!SCORES[@]}"; do echo "${SCORES[$k]}|$k"; done | sort -t'|' -k1 -rn | cut -d'|' -f2); do
  s=${SCORES[$name]:-0}
  grade=""
  if (( s >= 95 )); then grade="🏆 S"
  elif (( s >= 85 )); then grade="🥇 A"
  elif (( s >= 70 )); then grade="🥈 B"
  elif (( s >= 50 )); then grade="🥉 C"
  else grade="❌ D"
  fi
  printf "  %-16s %3d/100  %s\n" "$name" "$s" "$grade"
done

log ""
log "  ${BLUE}评测时间: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
log "  ${BLUE}评测环境: $(uname -s) $(uname -m)${NC}"
log ""
