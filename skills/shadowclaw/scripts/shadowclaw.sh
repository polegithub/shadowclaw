#!/usr/bin/env bash
#
# ShadowClaw — OpenClaw Snapshot & Restore
# CatPawClaw v2.3
#
# Usage:
#   shadowclaw snapshot [-o dir] [--dry-run] [--no-desensitize] [--incremental]
#   shadowclaw restore  [--force] <snapshot-dir>
#   shadowclaw merge    [--force] [--dry-run] <snapshot-dir>
#   shadowclaw push     [-r repo] [-b branch]
#   shadowclaw verify   <snapshot-dir>
#   shadowclaw cron     [--interval 6h] [--remove]
#   shadowclaw diff     <snapshot-dir>
#   shadowclaw help
#
set -euo pipefail

VERSION="2.3.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SHADOWCLAW_CONFIG:-${SCRIPT_DIR}/../config/default.json}"
STATE_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"

# ── Colors ──────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()      { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()     { echo -e "${RED}[ERROR]${NC} $*" >&2; }
section() { echo -e "\n${CYAN}── $* ──${NC}"; }

# ── Helpers ─────────────────────────────────────────────────────────
need() {
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || { err "缺少依赖: $cmd"; exit 1; }
  done
}

file_size_mb() {
  local s
  if [[ "$(uname)" == "Darwin" ]]; then
    s=$(stat -f%z "$1" 2>/dev/null || echo 0)
  else
    s=$(stat -c%s "$1" 2>/dev/null || echo 0)
  fi
  echo $(( s / 1024 / 1024 ))
}

# Detect OS for portability
IS_MACOS=false
[[ "$(uname)" == "Darwin" ]] && IS_MACOS=true

# Read JSON arrays via jq
cfg_arr() { jq -r "$1 // [] | .[]" "$CONFIG_FILE" 2>/dev/null; }

# ── Desensitize ─────────────────────────────────────────────────────
desensitize() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  info "🔒 脱敏: $(basename "$file")"

  # JSON field patterns
  while IFS= read -r pat; do
    [[ -z "$pat" ]] && continue
    sed -i "s/\"${pat}\": *\"[^\"]*\"/\"${pat}\": \"{{SECRET:${pat}}}\"/g" "$file" 2>/dev/null || true
  done < <(cfg_arr '.desensitize.json_patterns')

  # Value patterns (e.g. sk-xxx, ghp_xxx)
  while IFS= read -r pat; do
    [[ -z "$pat" ]] && continue
    sed -i "s/\"${pat}\"/\"{{SECRET:redacted}}\"/g" "$file" 2>/dev/null || true
  done < <(cfg_arr '.desensitize.value_patterns')

  # .env KEY=value patterns
  while IFS= read -r pat; do
    [[ -z "$pat" ]] && continue
    sed -i "s/\\(${pat}\\).*/\\1{{SECRET:env}}/g" "$file" 2>/dev/null || true
  done < <(cfg_arr '.desensitize.env_patterns')

  # PEM private keys (inline or multiline)
  sed -i 's/-----BEGIN[^-]*PRIVATE KEY-----[^-]*-----END[^-]*PRIVATE KEY-----/{{SECRET:private_key}}/g' "$file" 2>/dev/null || true
  # Handle escaped newlines in JSON (\\n style PEM)
  sed -i 's/-----BEGIN PRIVATE KEY-----\\n[^"]*\\n-----END PRIVATE KEY-----\\n/{{SECRET:private_key}}/g' "$file" 2>/dev/null || true
}

# ── Deep security scan ──────────────────────────────────────────────
deep_security_scan() {
  local dir="$1"
  local issues=0

  info "🔒 深度安全扫描..."

  while IFS= read -r -d '' f; do
    local fname="${f#$dir/}"

    # API keys & tokens
    if grep -qE '(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|xoxb-[a-zA-Z0-9-]+|Bearer [a-zA-Z0-9._-]{20,})' "$f" 2>/dev/null; then
      err "明文密钥: $fname"
      (( issues++ )) || true
    fi

    # Private keys (but not JSON fields that mention "PRIVATE KEY" as a label)
    if grep -q "BEGIN.*PRIVATE KEY" "$f" 2>/dev/null; then
      err "私钥文件: $fname"
      (( issues++ )) || true
    fi

    # Email addresses (personal info)
    if grep -qE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(com|cn|org|net|io)' "$f" 2>/dev/null; then
      local count; count=$(grep -cE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(com|cn|org|net|io)' "$f" 2>/dev/null || echo 0)
      if (( count > 0 )); then
        warn "发现 $count 个邮箱地址: $fname"
      fi
    fi

    # IP addresses (internal)
    if grep -qE '(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)[0-9]+\.[0-9]+' "$f" 2>/dev/null; then
      warn "内网 IP: $fname"
    fi

    # Passwords in plaintext
    if grep -qiE '"password"\s*:\s*"[^{][^"]{3,}"' "$f" 2>/dev/null; then
      err "明文密码: $fname"
      (( issues++ )) || true
    fi

  done < <(find "$dir" \( -name "*.json" -o -name "*.md" -o -name ".env" -o -name "*.yaml" -o -name "*.yml" -o -name "*.toml" \) -print0 2>/dev/null)

  if (( issues > 0 )); then
    err "发现 $issues 个安全问题!"
    return 1
  fi
  ok "深度安全扫描通过"
  return 0
}

# ── Incremental diff ────────────────────────────────────────────────
compute_file_hash() {
  sha256sum "$1" 2>/dev/null | cut -d' ' -f1
}

build_hash_map() {
  local dir="$1"
  declare -gA HASH_MAP
  while IFS= read -r -d '' f; do
    local rel="${f#$dir/}"
    HASH_MAP["$rel"]="$(compute_file_hash "$f")"
  done < <(find "$dir" -type f -print0 2>/dev/null)
}

# ── Copy with size check ───────────────────────────────────────────
# $1=src $2=dst $3=max_mb $4=label $5=dry_run
# Uses global: incremental, BASE_HASHES, stats_unchanged
copy_checked() {
  local src="$1" dst="$2" max_mb="${3:-10}" label="${4:-}" dry="${5:-false}"

  if [[ ! -e "$src" ]]; then
    warn "跳过（不存在）: ${label:-$src}"
    (( stats_skipped++ )) || true
    return
  fi

  if [[ -f "$src" ]]; then
    local mb; mb=$(file_size_mb "$src")
    if (( mb > max_mb )); then
      warn "跳过（${mb}MB > ${max_mb}MB）: ${label:-$src}"
      (( stats_skipped++ )) || true
      return
    fi

    # Incremental: skip if file hash matches base snapshot
    if [[ "${incremental:-false}" == "true" && -f "$src" ]]; then
      local rel="${src#$STATE_DIR/}"
      local current_hash; current_hash=$(sha256sum "$src" 2>/dev/null | cut -d' ' -f1)
      local base_hash="${BASE_HASHES[$rel]:-}"
      if [[ -n "$base_hash" && "$current_hash" == "$base_hash" ]]; then
        (( stats_unchanged++ )) || true
        return  # Skip unchanged file
      fi
    fi
  fi

  if [[ "$dry" == "false" ]]; then
    mkdir -p "$(dirname "$dst")"
    if [[ -d "$src" ]]; then
      cp -r "$src" "$dst"
    else
      cp "$src" "$dst"
    fi
  fi

  ok "${label:-$(basename "$src")}"
  (( stats_copied++ )) || true
}

# ── CMD: snapshot ───────────────────────────────────────────────────
cmd_snapshot() {
  local output_dir="" dry_run=false do_desensitize=true incremental=false base_manifest=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output)  output_dir="$2"; shift 2 ;;
      --dry-run)    dry_run=true; shift ;;
      --no-desensitize) do_desensitize=false; shift ;;
      --incremental|-i) incremental=true; shift ;;
      --base)       base_manifest="$2"; shift 2 ;;
      *)            output_dir="$1"; shift ;;
    esac
  done

  [[ -z "$output_dir" ]] && output_dir="./shadowclaw-snapshot-$(date +%Y%m%d-%H%M%S)"

  section "ShadowClaw Snapshot v${VERSION}"
  info "源:   $STATE_DIR"
  info "目标: $output_dir"
  $dry_run && warn "模拟运行模式 (--dry-run)"
  $incremental && info "📦 增量模式"

  # Load base manifest for incremental
  declare -A BASE_HASHES
  if [[ "$incremental" == "true" ]]; then
    # Auto-discover latest manifest: check common snapshot locations
    if [[ -z "$base_manifest" ]]; then
      local search_dirs=("$(dirname "$output_dir")" "${STATE_DIR}/snapshots" "." "/tmp")
      for sdir in "${search_dirs[@]}"; do
        base_manifest=$(find "$sdir" -maxdepth 3 -name "manifest.json" -path "*shadowclaw*" -type f 2>/dev/null | sort -r | head -1)
        [[ -n "$base_manifest" ]] && break
      done
    fi
    if [[ -n "$base_manifest" && -f "$base_manifest" ]]; then
      info "增量基准: $base_manifest"
      while IFS='=' read -r key val; do
        BASE_HASHES["$key"]="$val"
      done < <(jq -r '.file_hashes // {} | to_entries[] | "\(.key)=\(.value)"' "$base_manifest" 2>/dev/null)
      info "基准文件数: ${#BASE_HASHES[@]}"
    else
      warn "未找到基准快照，执行完整快照"
      incremental=false
    fi
  fi

  stats_copied=0; stats_skipped=0; stats_unchanged=0

  # ─ Critical files ─
  section "🔴 必备文件"
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    copy_checked "$STATE_DIR/$rel" "$output_dir/$rel" 100 "🔴 $rel" "$dry_run"
  done < <(cfg_arr '.critical.files')

  # ─ Critical directories ─
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    if [[ -d "$STATE_DIR/$rel" ]]; then
      copy_checked "$STATE_DIR/$rel" "$output_dir/$rel" 100 "🔴 $rel/" "$dry_run"
    else
      warn "跳过目录（不存在）: $rel"
      (( stats_skipped++ )) || true
    fi
  done < <(cfg_arr '.critical.directories')

  # ─ Important files ─
  section "🟡 重要文件"
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    copy_checked "$STATE_DIR/$rel" "$output_dir/$rel" 10 "🟡 $rel" "$dry_run"
  done < <(cfg_arr '.important.files')

  # ─ Important directories ─
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    if [[ -d "$STATE_DIR/$rel" ]]; then
      copy_checked "$STATE_DIR/$rel" "$output_dir/$rel" 10 "🟡 $rel/" "$dry_run"
    else
      warn "跳过目录（不存在）: $rel"
      (( stats_skipped++ )) || true
    fi
  done < <(cfg_arr '.important.directories')

  # ─ Important globs ─
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    for src in $STATE_DIR/$pattern; do
      [[ -e "$src" ]] || continue
      local rel="${src#$STATE_DIR/}"
      copy_checked "$src" "$output_dir/$rel" 50 "🟡 $rel" "$dry_run"
    done
  done < <(cfg_arr '.important.glob')

  # ─ Optional files ─
  section "🟢 可选文件"
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    copy_checked "$STATE_DIR/$rel" "$output_dir/$rel" 10 "🟢 $rel" "$dry_run"
  done < <(cfg_arr '.optional.files')

  # ─ Desensitize ─
  if [[ "$do_desensitize" == "true" && "$dry_run" == "false" ]]; then
    section "🔒 脱敏处理"
    # Specific files
    while IFS= read -r rel; do
      [[ -z "$rel" ]] && continue
      desensitize "$output_dir/$rel"
    done < <(cfg_arr '.desensitize.files')

    # Glob files (e.g., session jsonl files containing user-pasted tokens)
    while IFS= read -r pattern; do
      [[ -z "$pattern" ]] && continue
      for src in $output_dir/$pattern; do
        [[ -f "$src" ]] || continue
        info "🔒 脱敏(glob): ${src#$output_dir/}"
        # Direct pattern replacement for session files (handles JSON-embedded tokens)
        # GitHub tokens
        sed -i 's/ghp_[a-zA-Z0-9]\{20,\}/{{SECRET:redacted}}/g' "$src" 2>/dev/null || true
        sed -i 's/ghu_[a-zA-Z0-9]\{20,\}/{{SECRET:redacted}}/g' "$src" 2>/dev/null || true
        sed -i 's/ghs_[a-zA-Z0-9]\{20,\}/{{SECRET:redacted}}/g' "$src" 2>/dev/null || true
        # OpenAI keys
        sed -i 's/sk-[a-zA-Z0-9]\{20,\}/{{SECRET:redacted}}/g' "$src" 2>/dev/null || true
        # Slack tokens
        sed -i 's/xoxb-[a-zA-Z0-9-]\{10,\}/{{SECRET:redacted}}/g' "$src" 2>/dev/null || true
        sed -i 's/xoxp-[a-zA-Z0-9-]\{10,\}/{{SECRET:redacted}}/g' "$src" 2>/dev/null || true
        # Feishu app IDs and open IDs
        sed -i 's/cli_[a-zA-Z0-9]\{16,\}/{{SECRET:redacted}}/g' "$src" 2>/dev/null || true
        # x-access-token in URLs
        sed -i 's|x-access-token:[a-zA-Z0-9_.-]\{10,\}|x-access-token:{{SECRET:redacted}}|g' "$src" 2>/dev/null || true
        # Bearer tokens
        sed -i 's/Bearer [a-zA-Z0-9._-]\{20,\}/Bearer {{SECRET:redacted}}/g' "$src" 2>/dev/null || true
        # PEM private keys embedded in JSON (escaped newlines)
        sed -i 's/-----BEGIN PRIVATE KEY-----\\n[^"]*\\n-----END PRIVATE KEY-----\\n/{{SECRET:private_key}}/g' "$src" 2>/dev/null || true
        sed -i 's/-----BEGIN[^-]*PRIVATE KEY-----[^"]*-----END[^-]*PRIVATE KEY-----/{{SECRET:private_key}}/g' "$src" 2>/dev/null || true
      done
    done < <(cfg_arr '.desensitize.glob_files')
  fi

  # ─ Manifest with file hashes ─
  if [[ "$dry_run" == "false" ]]; then
    section "📋 Manifest"

    # Build file hash map for incremental support
    local hash_json="{"
    local first=true
    while IFS= read -r -d '' f; do
      local rel="${f#$output_dir/}"
      [[ "$rel" == "manifest.json" || "$rel" == "secrets-template.json" ]] && continue
      local h; h=$(sha256sum "$f" 2>/dev/null | cut -d' ' -f1)
      if [[ "$first" == "true" ]]; then
        first=false
      else
        hash_json+=","
      fi
      hash_json+="\"${rel}\":\"${h}\""
    done < <(find "$output_dir" -type f -print0 2>/dev/null)
    hash_json+="}"

    cat > "$output_dir/manifest.json" <<EOF
{
  "version": "${VERSION}",
  "tool": "shadowclaw",
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "generated_by": "$(whoami)@$(hostname)",
  "state_dir": "${STATE_DIR}",
  "incremental": ${incremental},
  "stats": {
    "copied": ${stats_copied},
    "skipped": ${stats_skipped},
    "unchanged": ${stats_unchanged:-0}
  },
  "file_hashes": ${hash_json}
}
EOF
    ok "manifest.json (含文件哈希，支持增量比对)"

    # Secrets template
    cat > "$output_dir/secrets-template.json" <<'TMPL'
{
  "_说明": "恢复后，在对应文件中将 {{SECRET:xxx}} 替换为真实值",
  "openclaw.json": "gateway.auth.token, channels.*.appSecret, models.providers.*.apiKey",
  "auth-profiles.json": "所有 API Key",
  "credentials/*.json": "OAuth Token / 飞书配对 / WhatsApp 登录态",
  ".env": "环境变量中的 *_KEY, *_SECRET, *_TOKEN"
}
TMPL
    ok "secrets-template.json"

    # Deep security scan
    section "🛡️ 安全验证"
    deep_security_scan "$output_dir" || warn "请手动检查上述安全问题"
  fi

  # ─ Generate Report ─
  if [[ "$dry_run" == "false" ]]; then
    section "📊 生成快照报告"
    _generate_report "$output_dir" "$do_desensitize" "$incremental"
  fi

  # ─ Summary ─
  section "完成"
  info "已复制: $stats_copied | 已跳过: $stats_skipped | 未变更: ${stats_unchanged:-0}"
  info "输出: $output_dir"
  $do_desensitize && info "✅ 已脱敏 + 安全扫描"
  info "📊 报告: $output_dir/快照报告_*.md"
}

# ── Report Generator ────────────────────────────────────────────────
_generate_report() {
  local snap_dir="$1" desensitized="${2:-true}" is_incremental="${3:-false}"
  local report_name="快照报告_$(date +%Y%m%d_%H%M%S).md"
  local report="$snap_dir/$report_name"

  # 统计数据
  local total_files; total_files=$(find "$snap_dir" -type f -not -name "快照报告_*.md" | wc -l)
  local total_size; total_size=$(du -sh "$snap_dir" 2>/dev/null | cut -f1)
  local skill_count=0; [[ -d "$snap_dir/skills" ]] && skill_count=$(find "$snap_dir/skills" -maxdepth 1 -type d | wc -l); (( skill_count > 0 )) && (( skill_count-- )) || true
  local session_count=0; [[ -d "$snap_dir/agents/main/sessions" ]] && session_count=$(find "$snap_dir/agents/main/sessions" -name "*.jsonl" | wc -l)
  local workspace_files=0; [[ -d "$snap_dir/workspace" ]] && workspace_files=$(find "$snap_dir/workspace" -type f | wc -l)
  local memory_files=0; [[ -d "$snap_dir/workspace/memory" ]] && memory_files=$(find "$snap_dir/workspace/memory" -type f | wc -l)

  # 脱敏统计
  local secret_count=0
  [[ -d "$snap_dir" ]] && secret_count=$(grep -rl '{{SECRET:' "$snap_dir/" 2>/dev/null | wc -l)
  local placeholder_total=0
  [[ -d "$snap_dir" ]] && placeholder_total=$(grep -roh '{{SECRET:[^}]*}}' "$snap_dir/" 2>/dev/null | wc -l)

  # 检测脱敏了哪些平台
  local platforms=""
  if [[ -f "$snap_dir/openclaw.json" ]]; then
    grep -q '{{SECRET:' "$snap_dir/openclaw.json" 2>/dev/null && {
      grep -q 'feishu\|飞书' "$snap_dir/openclaw.json" 2>/dev/null && platforms="${platforms}飞书 "
      grep -q 'telegram' "$snap_dir/openclaw.json" 2>/dev/null && platforms="${platforms}Telegram "
      grep -q 'discord' "$snap_dir/openclaw.json" 2>/dev/null && platforms="${platforms}Discord "
      grep -q 'whatsapp' "$snap_dir/openclaw.json" 2>/dev/null && platforms="${platforms}WhatsApp "
      grep -q 'slack' "$snap_dir/openclaw.json" 2>/dev/null && platforms="${platforms}Slack "
      grep -q 'signal' "$snap_dir/openclaw.json" 2>/dev/null && platforms="${platforms}Signal "
      grep -q 'daxiang\|大象' "$snap_dir/openclaw.json" 2>/dev/null && platforms="${platforms}大象 "
      grep -qE 'apiKey|api_key' "$snap_dir/openclaw.json" 2>/dev/null && platforms="${platforms}模型API "
      grep -q 'github\|GITHUB' "$snap_dir/openclaw.json" 2>/dev/null && platforms="${platforms}GitHub "
    }
  fi
  [[ -z "$platforms" ]] && platforms="无（未检测到平台配置）"

  # 跳过文件列表
  local skipped_list=""
  # 从 manifest 获取跳过的原因
  local skip_reasons=""
  if (( stats_skipped > 0 )); then
    skip_reasons="共 ${stats_skipped} 项被跳过（文件不存在或体积超限）"
  fi

  # 检查大文件风险
  local large_files=""
  while IFS= read -r -d '' f; do
    local fsize
    if [[ "$(uname)" == "Darwin" ]]; then
      fsize=$(stat -f%z "$f" 2>/dev/null || echo 0)
    else
      fsize=$(stat -c%s "$f" 2>/dev/null || echo 0)
    fi
    if (( fsize > 5242880 )); then  # > 5MB
      local fname="${f#$STATE_DIR/}"
      local fmb=$(( fsize / 1024 / 1024 ))
      large_files="${large_files}  - ${fname}（${fmb}MB）\n"
    fi
  done < <(find "$STATE_DIR" -type f -print0 2>/dev/null)

  # 检查未备份的重要目录
  local missing_dirs=""
  for d in credentials memory agents/main/agent identity; do
    if [[ -d "$STATE_DIR/$d" && ! -d "$snap_dir/$d" ]]; then
      missing_dirs="${missing_dirs}  - ${d}/（当前环境存在但未备份）\n"
    fi
  done

  # 写报告
  local snap_id; snap_id="SNAP-$(date +%Y%m%d-%H%M%S)"
  local hostname_str; hostname_str=$(hostname 2>/dev/null || echo "unknown")
  local os_str; os_str=$(uname -srm 2>/dev/null || echo "unknown")
  local openclaw_ver; openclaw_ver=$(openclaw --version 2>/dev/null | head -1 || echo "未检测到")

  cat > "$report" <<REPORT
# ShadowClaw 快照报告

| 字段 | 值 |
|------|------|
| 报告编号 | ${snap_id} |
| 生成时间 | $(date '+%Y-%m-%d %H:%M:%S %Z') |
| 工具版本 | ShadowClaw v${VERSION} |
| OpenClaw 版本 | ${openclaw_ver} |
| 主机名 | ${hostname_str} |
| 操作系统 | ${os_str} |
| 源目录 | ${STATE_DIR} |
| 输出目录 | ${snap_dir} |
| 快照模式 | $( [[ "$is_incremental" == "true" ]] && echo "增量（仅变更文件）" || echo "全量" ) |
| 脱敏状态 | $( [[ "$desensitized" == "true" ]] && echo "✅ 已执行" || echo "⚠️ 未执行" ) |

---

## 备份概览

| 指标 | 数值 |
|------|------|
| 总文件数 | ${total_files} |
| 快照体积 | ${total_size} |
| Skills 数量 | ${skill_count} |
| 会话文件 | ${session_count} |
| 工作区文件 | ${workspace_files} |
| 记忆文件 | ${memory_files} |
| 已复制 | ${stats_copied} |
| 已跳过 | ${stats_skipped} |
| 未变更（增量跳过） | ${stats_unchanged:-0} |

## 已备份内容

REPORT

  # 列出已备份的顶级目录
  for d in "$snap_dir"/*/; do
    [[ -d "$d" ]] || continue
    local dname; dname=$(basename "$d")
    local dcount; dcount=$(find "$d" -type f | wc -l)
    echo "- **${dname}/**（${dcount} 个文件）" >> "$report"
  done
  # 顶级文件
  for f in "$snap_dir"/*; do
    [[ -f "$f" ]] || continue
    local fname; fname=$(basename "$f")
    [[ "$fname" == 快照报告_* ]] && continue
    echo "- ${fname}" >> "$report"
  done

  cat >> "$report" <<REPORT

## 安全与脱敏

| 指标 | 数值 |
|------|------|
| 脱敏处理 | $( [[ "$desensitized" == "true" ]] && echo "✅ 已执行" || echo "⚠️ 未执行" ) |
| 涉及文件数 | ${secret_count} |
| 脱敏占位符总数 | ${placeholder_total} |
| 涉及平台 | ${platforms} |

脱敏范围：API Key、OAuth Token、私钥（PEM）、Bearer Token、GitHub Token（ghp_/ghu_/ghs_）、Slack Token（xoxb_/xoxp_）、飞书 App ID（cli_）、x-access-token。

REPORT

  # 风险提示
  local has_risk=false
  if [[ -n "$large_files" || -n "$missing_dirs" || $stats_skipped -gt 0 ]]; then
    has_risk=true
    echo "## ⚠️ 风险提示" >> "$report"
    echo "" >> "$report"
  fi

  if [[ -n "$missing_dirs" ]]; then
    echo "**未备份的目录（当前环境存在但未包含在快照中）：**" >> "$report"
    echo "" >> "$report"
    echo -e "$missing_dirs" >> "$report"
    echo "如需备份，请在 config/default.json 的 critical 或 important 中添加对应路径。" >> "$report"
    echo "" >> "$report"
  fi

  if [[ -n "$large_files" ]]; then
    echo "**当前环境中的大文件（>5MB，可能未备份）：**" >> "$report"
    echo "" >> "$report"
    echo -e "$large_files" >> "$report"
    echo "大文件默认跳过。如需强制备份，在 config/default.json 中调高 size_limits 或使用 \`--no-size-limit\` 参数。" >> "$report"
    echo "" >> "$report"
  fi

  if (( stats_skipped > 0 )); then
    echo "**${skip_reasons}**" >> "$report"
    echo "" >> "$report"
    echo "跳过原因通常是：文件在当前环境中不存在（如未配置某通道），或体积超过限制。" >> "$report"
    echo "" >> "$report"
  fi

  if [[ "$has_risk" == "false" ]]; then
    echo "## ✅ 无风险" >> "$report"
    echo "" >> "$report"
    echo "所有配置范围内的文件已完整备份，无体积超限，无遗漏目录。" >> "$report"
    echo "" >> "$report"
  fi

  # 存储建议
  cat >> "$report" <<REPORT
## 存储建议

快照生成后需要存到安全的地方。几种选择：

| 方式 | 说明 | 适合场景 |
|------|------|----------|
| GitHub 私有仓库 | \`shadowclaw push -r github.com/user/repo -b main\` | 个人备份，版本可追溯 |
| 本地加密压缩 | \`tar czf snapshot.tar.gz <快照目录>\` + GPG 加密 | 离线保存 |
| 对象存储（S3/R2/B2） | 搭配 rclone 或 aws-cli 上传 | 团队协作，自动化 |
| NAS / 网盘 | 手动复制到 Synology、群晖等 | 家庭用户 |

恢复时从存储位置拉回快照目录，执行 \`shadowclaw restore --force <快照目录>\` 即可。

---
*本报告由 ShadowClaw v${VERSION} 自动生成*
REPORT

  ok "报告已生成: $report_name"
}

# ── CMD: restore ────────────────────────────────────────────────────
cmd_restore() {
  local snapshot_dir="" force=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force|-f) force=true; shift ;;
      *)          snapshot_dir="$1"; shift ;;
    esac
  done

  [[ -z "$snapshot_dir" ]] && { err "请指定快照目录"; echo "用法: shadowclaw restore [--force] <snapshot-dir>"; exit 1; }
  [[ -d "$snapshot_dir" ]] || { err "快照目录不存在: $snapshot_dir"; exit 1; }

  section "ShadowClaw Restore v${VERSION}"
  info "来源: $snapshot_dir"
  info "目标: $STATE_DIR"

  # Show manifest if present
  if [[ -f "$snapshot_dir/manifest.json" ]]; then
    info "快照信息:"
    jq -r '"  版本: \(.version)\n  时间: \(.generated_at)\n  来源: \(.generated_by)"' "$snapshot_dir/manifest.json" 2>/dev/null || true
  fi

  if [[ "$force" == "false" ]]; then
    warn "此操作将覆盖现有配置!"
    read -p "继续? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || { info "已取消"; exit 0; }
  fi

  # ─ Backup current ─
  local backup_dir="${STATE_DIR}/backup/$(date +%Y%m%d-%H%M%S)"
  section "📦 备份当前状态"
  mkdir -p "$backup_dir"

  for item in openclaw.json agents credentials memory workspace cron identity .env; do
    [[ -e "$STATE_DIR/$item" ]] && cp -r "$STATE_DIR/$item" "$backup_dir/" 2>/dev/null || true
  done
  ok "已备份到: $backup_dir"

  # ─ Restore ─
  section "📥 恢复文件"

  # Restore directories and files from snapshot, preserving structure
  for item in "$snapshot_dir"/*; do
    local name; name=$(basename "$item")

    # Skip meta files
    [[ "$name" == "manifest.json" || "$name" == "secrets-template.json" ]] && continue

    local target="$STATE_DIR/$name"

    if [[ -d "$item" ]]; then
      mkdir -p "$target"
      cp -r "$item/"* "$target/" 2>/dev/null || true
      ok "恢复目录: $name/"
    elif [[ -f "$item" ]]; then
      mkdir -p "$(dirname "$target")"
      cp "$item" "$target"
      ok "恢复文件: $name"
    fi
  done

  # ─ Post-restore ─
  section "✅ 恢复完成"
  echo ""
  echo "  后续步骤:"
  echo "  1. 参考 secrets-template.json，填入真实凭证"
  echo "  2. 在 openclaw.json 中替换 {{SECRET:xxx}} 占位符"
  echo "  3. 重启: openclaw gateway restart"
  echo "  4. 验证: openclaw status"
  echo ""
  info "回滚备份: $backup_dir"
}

# ── CMD: merge ──────────────────────────────────────────────────────
# Merge snapshot into local state: only add missing files, never overwrite.
# Like git merge: local wins on conflict, snapshot fills gaps.
# openclaw.json is ALWAYS skipped (snapshot has redacted secrets).
cmd_merge() {
  local snapshot_dir="" force=false dry_run=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force|-f) force=true; shift ;;
      --dry-run)  dry_run=true; shift ;;
      *)          snapshot_dir="$1"; shift ;;
    esac
  done

  [[ -z "$snapshot_dir" ]] && { err "请指定快照目录"; echo "用法: shadowclaw merge [--force] [--dry-run] <snapshot-dir>"; exit 1; }
  [[ -d "$snapshot_dir" ]] || { err "快照目录不存在: $snapshot_dir"; exit 1; }

  section "ShadowClaw Merge v${VERSION}"
  info "快照源: $snapshot_dir"
  info "目标:   $STATE_DIR"
  $dry_run && warn "模拟运行模式 (--dry-run)"

  # Show manifest
  if [[ -f "$snapshot_dir/manifest.json" ]]; then
    info "快照信息:"
    jq -r '"  版本: \(.version)\n  时间: \(.generated_at)\n  来源: \(.generated_by)"' "$snapshot_dir/manifest.json" 2>/dev/null || true
  fi

  if [[ "$force" == "false" && "$dry_run" == "false" ]]; then
    warn "此操作将把快照中缺失的文件合并到本地（不覆盖已有文件）"
    read -p "继续? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || { info "已取消"; exit 0; }
  fi

  # ─ Backup current (even merge deserves a safety net) ─
  if [[ "$dry_run" == "false" ]]; then
    local backup_dir="${STATE_DIR}/backup/merge-$(date +%Y%m%d-%H%M%S)"
    section "📦 备份当前状态"
    mkdir -p "$backup_dir"
    for item in openclaw.json agents credentials memory workspace cron identity .env; do
      [[ -e "$STATE_DIR/$item" ]] && cp -r "$STATE_DIR/$item" "$backup_dir/" 2>/dev/null || true
    done
    ok "已备份到: $backup_dir"
  fi

  # ─ Skip list: files that should NEVER be merged from snapshot ─
  local -a SKIP_FILES=("openclaw.json" "manifest.json" "secrets-template.json")
  # Also skip any snapshot report dirs (not part of runtime state)
  local -a SKIP_DIRS=("report")

  _is_skipped_file() {
    local name="$1"
    for s in "${SKIP_FILES[@]}"; do
      [[ "$name" == "$s" ]] && return 0
    done
    return 1
  }

  _is_skipped_dir() {
    local name="$1"
    for s in "${SKIP_DIRS[@]}"; do
      [[ "$name" == "$s" ]] && return 0
    done
    return 1
  }

  # ─ Merge: walk snapshot, copy only what's missing locally ─
  section "🔀 合并文件（本地优先）"

  local stats_added=0 stats_skipped=0 stats_existed=0

  while IFS= read -r -d '' src_file; do
    local rel="${src_file#$snapshot_dir/}"

    # Skip meta/config files
    local top_name="${rel%%/*}"
    [[ "$top_name" == "$rel" ]] && {
      # Top-level file
      _is_skipped_file "$rel" && { (( stats_skipped++ )) || true; continue; }
    }
    _is_skipped_dir "$top_name" && { (( stats_skipped++ )) || true; continue; }

    # Also skip any file matching 快照报告_*.md
    [[ "$(basename "$rel")" == 快照报告_* ]] && { (( stats_skipped++ )) || true; continue; }

    local dst="$STATE_DIR/$rel"

    if [[ -f "$dst" ]]; then
      # File exists locally → keep local version (no overwrite)
      (( stats_existed++ )) || true
    else
      # File missing locally → add from snapshot
      if [[ "$dry_run" == "false" ]]; then
        mkdir -p "$(dirname "$dst")"
        cp "$src_file" "$dst"
      fi
      ok "+ $rel"
      (( stats_added++ )) || true
    fi
  done < <(find "$snapshot_dir" -type f -print0 2>/dev/null)

  # ─ Summary ─
  section "完成"
  info "新增: $stats_added | 已存在(跳过): $stats_existed | 排除: $stats_skipped"
  if [[ "$dry_run" == "true" ]]; then
    info "（模拟运行，未实际写入文件）"
  else
    info "本地已有文件未被覆盖 ✅"
    info "openclaw.json 未被替换 ✅"
    [[ -n "${backup_dir:-}" ]] && info "回滚备份: $backup_dir"
  fi
}

# ── CMD: push ───────────────────────────────────────────────────────
cmd_push() {
  local repo="" branch="" snapshot_dir=""

  repo=$(jq -r '.github.repo // empty' "$CONFIG_FILE" 2>/dev/null)
  branch=$(jq -r '.github.branch // "main"' "$CONFIG_FILE" 2>/dev/null)

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -r|--repo)   repo="$2"; shift 2 ;;
      -b|--branch) branch="$2"; shift 2 ;;
      -s|--snapshot) snapshot_dir="$2"; shift 2 ;;
      *)           shift ;;
    esac
  done

  [[ -z "$repo" ]] && { err "未指定仓库。使用 -r 或在 config/default.json 中配置"; exit 1; }

  section "ShadowClaw Push v${VERSION}"
  info "仓库: $repo"
  info "分支: $branch"

  # Find token
  local token=""
  for env_var in $(jq -r '.github.token_env // [] | .[]' "$CONFIG_FILE" 2>/dev/null); do
    token="${!env_var:-}"
    [[ -n "$token" ]] && break
  done

  [[ -z "$token" ]] && { err "未找到 GitHub Token (检查 GH_TOKEN / GITHUB_TOKEN)"; exit 1; }

  # Generate snapshot first if not provided
  if [[ -z "$snapshot_dir" ]]; then
    snapshot_dir=$(mktemp -d)
    trap "rm -rf '$snapshot_dir'" EXIT
    cmd_snapshot -o "$snapshot_dir"
  fi

  # Security scan
  section "🔒 安全检查"
  local leaked=0
  while IFS= read -r -d '' f; do
    if grep -qE '"sk-[a-zA-Z0-9]{20,}"' "$f" 2>/dev/null; then
      err "发现未脱敏密钥: $f"
      leaked=1
    fi
    if grep -qE '"ghp_[a-zA-Z0-9]{36}"' "$f" 2>/dev/null; then
      err "发现 GitHub Token: $f"
      leaked=1
    fi
  done < <(find "$snapshot_dir" \( -name "*.json" -o -name ".env" \) -print0)

  (( leaked )) && { err "快照中存在明文密钥，推送已中止!"; exit 1; }
  ok "安全检查通过"

  # Push via temp repo
  local tmp; tmp=$(mktemp -d)
  trap "rm -rf '$tmp' '$snapshot_dir'" EXIT

  cd "$tmp"
  git init -q
  git config user.email "shadowclaw@openclaw.dev"
  git config user.name "ShadowClaw"

  cp -r "$snapshot_dir/"* .
  git add -A
  git commit -q -m "shadowclaw snapshot $(date '+%Y-%m-%d %H:%M:%S')"
  git remote add origin "https://x-access-token:${token}@${repo}.git"

  if git push -f origin "HEAD:${branch}" 2>&1; then
    ok "推送成功! → ${repo} (${branch})"
  else
    err "推送失败"
    exit 1
  fi
}

# ── CMD: verify ─────────────────────────────────────────────────────
cmd_verify() {
  local snapshot_dir="$1"
  [[ -d "$snapshot_dir" ]] || { err "目录不存在: $snapshot_dir"; exit 1; }

  section "ShadowClaw Verify v${VERSION}"
  info "检查: $snapshot_dir"

  local issues=0

  # Check critical files exist
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    if [[ ! -e "$snapshot_dir/$rel" ]]; then
      warn "缺少必备文件: $rel"
      (( issues++ )) || true
    else
      ok "✓ $rel"
    fi
  done < <(cfg_arr '.critical.files')

  # Check for leaked secrets
  local leaked=0
  while IFS= read -r -d '' f; do
    if grep -qE '"sk-[a-zA-Z0-9]{20,}"' "$f" 2>/dev/null; then
      err "发现明文密钥: ${f#$snapshot_dir/}"
      (( leaked++ )) || true
    fi
  done < <(find "$snapshot_dir" -name "*.json" -print0)

  echo ""
  if (( issues == 0 && leaked == 0 )); then
    ok "快照验证通过 ✓"
  else
    warn "发现 $issues 个缺失文件, $leaked 个安全问题"
  fi
}

# ── CMD: cron ────────────────────────────────────────────────────────
cmd_cron() {
  local interval="6h" remove=false push_after=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --interval|-i) interval="$2"; shift 2 ;;
      --remove)       remove=true; shift ;;
      --push)         push_after=true; shift ;;
      *)              shift ;;
    esac
  done

  section "ShadowClaw Cron v${VERSION}"

  if [[ "$remove" == "true" ]]; then
    if command -v openclaw >/dev/null 2>&1; then
      openclaw cron remove shadowclaw-auto-snapshot 2>/dev/null || true
      ok "已移除定时快照任务"
    else
      # Fallback: crontab
      crontab -l 2>/dev/null | grep -v "shadowclaw snapshot" | crontab - 2>/dev/null || true
      ok "已从 crontab 移除"
    fi
    return
  fi

  local script_path; script_path=$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")

  # Try OpenClaw cron first
  if command -v openclaw >/dev/null 2>&1; then
    # Convert interval to cron expression
    local cron_expr
    case "$interval" in
      1h)  cron_expr="0 * * * *" ;;
      2h)  cron_expr="0 */2 * * *" ;;
      4h)  cron_expr="0 */4 * * *" ;;
      6h)  cron_expr="0 */6 * * *" ;;
      12h) cron_expr="0 */12 * * *" ;;
      24h|1d) cron_expr="0 2 * * *" ;;
      *)   cron_expr="0 */6 * * *"; warn "不识别的间隔 $interval，使用默认 6h" ;;
    esac

    local cron_cmd="$script_path snapshot --incremental -o ${STATE_DIR}/snapshots/auto"
    if [[ "$push_after" == "true" ]]; then
      cron_cmd="$script_path snapshot --incremental -o ${STATE_DIR}/snapshots/auto && $script_path push -s ${STATE_DIR}/snapshots/auto"
    fi

    info "配置 OpenClaw cron: $cron_expr"
    $push_after && info "快照后自动推送到 GitHub"
    openclaw cron add \
      --name "shadowclaw-auto-snapshot" \
      --schedule "$cron_expr" \
      --command "$cron_cmd" \
      2>/dev/null && ok "OpenClaw cron 已配置 (每 $interval)" || {
        warn "OpenClaw cron 配置失败，回退到系统 crontab"
        _setup_system_cron "$script_path" "$interval"
      }
  else
    _setup_system_cron "$script_path" "$interval"
  fi
}

_setup_system_cron() {
  local script_path="$1" interval="$2"
  local cron_expr
  case "$interval" in
    1h)  cron_expr="0 * * * *" ;;
    2h)  cron_expr="0 */2 * * *" ;;
    6h)  cron_expr="0 */6 * * *" ;;
    12h) cron_expr="0 */12 * * *" ;;
    *)   cron_expr="0 */6 * * *" ;;
  esac

  # Add to crontab (idempotent)
  (crontab -l 2>/dev/null | grep -v "shadowclaw snapshot"; echo "$cron_expr $script_path snapshot --incremental -o ${STATE_DIR}/snapshots/auto") | crontab -
  ok "系统 crontab 已配置 (每 $interval)"
}

# ── CMD: diff ────────────────────────────────────────────────────────
cmd_diff() {
  local snapshot_dir="${1:-}"
  [[ -z "$snapshot_dir" || ! -d "$snapshot_dir" ]] && { err "请指定快照目录"; exit 1; }

  section "ShadowClaw Diff v${VERSION}"
  info "对比: $STATE_DIR ↔ $snapshot_dir"

  local added=0 modified=0 deleted=0

  # Files in snapshot but not in state_dir or different
  while IFS= read -r -d '' f; do
    local rel="${f#$snapshot_dir/}"
    [[ "$rel" == "manifest.json" || "$rel" == "secrets-template.json" ]] && continue

    local current="$STATE_DIR/$rel"
    if [[ ! -e "$current" ]]; then
      echo -e "  ${GREEN}+ $rel${NC} (快照中有，当前缺失)"
      (( added++ )) || true
    elif ! diff -q "$f" "$current" >/dev/null 2>&1; then
      echo -e "  ${YELLOW}~ $rel${NC} (已变更)"
      (( modified++ )) || true
    fi
  done < <(find "$snapshot_dir" -type f -print0 2>/dev/null)

  echo ""
  info "新增: $added | 变更: $modified"
}

# ── CMD: test ─────────────────────────────────────────────────────────
cmd_test() {
  set +e  # Disable exit-on-error for test suite
  section "ShadowClaw Self-Test v${VERSION}"

  local pass=0 fail=0 total=0

  _assert() {
    (( total++ )) || true
    local desc="$1"; shift
    local rc=0
    "$@" >/dev/null 2>&1 || rc=$?
    if (( rc == 0 )); then
      ok "PASS: $desc"
      (( pass++ )) || true
    else
      err "FAIL: $desc"
      (( fail++ )) || true
    fi
  }

  # Test 1: help runs
  _assert "help 命令可用" bash "${BASH_SOURCE[0]}" help

  # Test 2: dry-run snapshot
  _assert "snapshot --dry-run 可执行" bash "${BASH_SOURCE[0]}" snapshot --dry-run

  # Test 3: actual snapshot
  local snap; snap=$(mktemp -d)
  _assert "snapshot 生成成功" bash "${BASH_SOURCE[0]}" snapshot -o "$snap"

  # Test 4: manifest exists
  _assert "manifest.json 存在" test -f "$snap/manifest.json"

  # Test 5: manifest has file_hashes
  _assert "manifest 包含文件哈希" jq -e '.file_hashes | length > 0' "$snap/manifest.json"

  # Test 6: critical files present
  _assert "workspace/MEMORY.md 已备份" test -f "$snap/workspace/MEMORY.md"

  # Test 7: desensitization worked
  if [[ -f "$snap/openclaw.json" ]]; then
    _assert "openclaw.json 已脱敏" grep -q '{{SECRET:' "$snap/openclaw.json"
  else
    warn "跳过脱敏检查（openclaw.json 不存在）"
  fi

  # Test 8: no plaintext GitHub tokens
  local ghp_count; ghp_count=$(grep -rlE 'ghp_[a-zA-Z0-9]{10,}' "$snap/" 2>/dev/null | wc -l)
  _assert "无明文 GitHub token 泄漏" test "$ghp_count" -eq 0

  # Test 9: verify command
  _assert "verify 命令可用" bash "${BASH_SOURCE[0]}" verify "$snap"

  # Test 10: diff command
  _assert "diff 命令可用" bash "${BASH_SOURCE[0]}" diff "$snap"

  # Test 11: restore (to temp dir)
  local restore_target; restore_target=$(mktemp -d)
  _assert "restore --force 可执行" env OPENCLAW_DIR="$restore_target" bash "${BASH_SOURCE[0]}" restore --force "$snap"

  # Test 12: backup created during restore
  _assert "恢复前自动备份存在" test -d "$restore_target/backup"

  # ── Merge tests ──────────────────────────────────────────────────
  # Setup: create a fake "local" state and a fake "snapshot" with overlapping + unique files
  local merge_local; merge_local=$(mktemp -d)
  local merge_snap; merge_snap=$(mktemp -d)

  # Local state: has file_a and file_common
  mkdir -p "$merge_local/workspace/memory"
  echo "local-content-a" > "$merge_local/workspace/memory/local_only.md"
  echo "local-version" > "$merge_local/workspace/memory/common.md"
  echo '{"local":"config"}' > "$merge_local/openclaw.json"

  # Snapshot: has file_b, file_common (different content), and openclaw.json (redacted)
  mkdir -p "$merge_snap/workspace/memory"
  echo "snap-content-b" > "$merge_snap/workspace/memory/snap_only.md"
  echo "snap-version" > "$merge_snap/workspace/memory/common.md"
  echo '{"secret":"{{SECRET:redacted}}"}' > "$merge_snap/openclaw.json"
  echo '{}' > "$merge_snap/manifest.json"
  echo '{}' > "$merge_snap/secrets-template.json"
  mkdir -p "$merge_snap/report"
  echo "report" > "$merge_snap/report/some_report.md"

  # Test 13: merge --dry-run works
  _assert "merge --dry-run 可执行" env OPENCLAW_DIR="$merge_local" bash "${BASH_SOURCE[0]}" merge --force --dry-run "$merge_snap"

  # Test 14: dry-run does NOT add missing file
  _assert "dry-run 不写入文件" test ! -f "$merge_local/workspace/memory/snap_only.md"

  # Test 15: actual merge
  _assert "merge --force 可执行" env OPENCLAW_DIR="$merge_local" bash "${BASH_SOURCE[0]}" merge --force "$merge_snap"

  # Test 16: missing file was added
  _assert "合并补充了缺失文件" test -f "$merge_local/workspace/memory/snap_only.md"

  # Test 17: existing file was NOT overwritten (local wins)
  _assert "已有文件未被覆盖（本地优先）" grep -q "local-version" "$merge_local/workspace/memory/common.md"

  # Test 18: openclaw.json was NOT replaced
  _assert "openclaw.json 未被替换" grep -q "local" "$merge_local/openclaw.json"

  # Test 19: report dir was not merged
  _assert "report 目录未合并" test ! -f "$merge_local/report/some_report.md"

  # Test 20: backup created during merge
  _assert "合并前自动备份存在" test -d "$merge_local/backup"

  # Cleanup
  rm -rf "$snap" "$restore_target" "$merge_local" "$merge_snap"

  # Summary
  section "测试结果"
  info "通过: $pass / $total | 失败: $fail"
  set -e  # Re-enable exit-on-error
  if (( fail == 0 )); then
    ok "🎉 所有测试通过!"
    return 0
  else
    err "存在 $fail 个失败"
    return 1
  fi
}

# ── CMD: help ───────────────────────────────────────────────────────
cmd_help() {
  cat <<EOF
ShadowClaw v${VERSION} — OpenClaw Snapshot & Restore

命令:
  snapshot  [-o dir] [--dry-run] [--incremental]       生成快照
  restore   [--force] <snapshot-dir>                   覆盖恢复（全量替换）
  merge     [--force] [--dry-run] <snapshot-dir>       合并快照（只补缺失，不覆盖）
  push      [-r repo] [-b branch] [-s snapshot-dir]    推送到 GitHub
  verify    <snapshot-dir>                             验证快照完整性
  cron      [--interval 6h] [--push] [--remove]        配置定时快照(+推送)
  diff      <snapshot-dir>                             对比快照与当前差异
  test                                                 运行自测
  help                                                 显示帮助

示例:
  shadowclaw snapshot                     # 完整快照
  shadowclaw snapshot --incremental       # 增量快照（仅变更文件）
  shadowclaw snapshot --dry-run           # 模拟运行
  shadowclaw restore ./my-snapshot        # 覆盖恢复
  shadowclaw merge ./my-snapshot          # 合并快照（本地优先）
  shadowclaw merge --dry-run ./snap       # 预览合并（不写入）
  shadowclaw push -b main              # 推送到 catclaw 分支
  shadowclaw cron --interval 6h           # 每6小时自动快照
  shadowclaw cron --interval 6h --push    # 每6小时快照+推送
  shadowclaw cron --remove                # 移除定时任务
  shadowclaw diff ./my-snapshot           # 查看差异
  shadowclaw test                         # 运行自测

环境变量:
  GH_TOKEN / GITHUB_TOKEN   GitHub 访问令牌
  OPENCLAW_DIR               覆盖默认 state 目录 (~/.openclaw)

配置: $(realpath "$CONFIG_FILE" 2>/dev/null || echo "$CONFIG_FILE")
EOF
}

# ── Main ────────────────────────────────────────────────────────────
main() {
  need jq git

  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    snapshot|s)  cmd_snapshot "$@" ;;
    restore|r)   cmd_restore "$@" ;;
    merge|m)     cmd_merge "$@" ;;
    push|p)      cmd_push "$@" ;;
    verify|v)    cmd_verify "$@" ;;
    cron|c)      cmd_cron "$@" ;;
    diff|d)      cmd_diff "$@" ;;
    test|t)      cmd_test "$@" ;;
    help|--help|-h) cmd_help ;;
    version|--version|-V) echo "ShadowClaw v${VERSION}" ;;
    *) err "未知命令: $cmd"; cmd_help; exit 1 ;;
  esac
}

main "$@"
