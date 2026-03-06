#!/bin/bash
#
# KimiClaw Snapshot Generator
# 生成符合目录结构的快照
#

set -e

OUTPUT_DIR="${1:-./kimiclaw-snapshot}"
DRY_RUN=false

# 源目录
STATE_DIR="${HOME}/.openclaw"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查参数
if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
    OUTPUT_DIR="${2:-./kimiclaw-snapshot}"
fi

log_info "KimiClaw Snapshot Generator"
log_info "=========================="
log_info "输出目录: $OUTPUT_DIR"

if [ "$DRY_RUN" = true ]; then
    log_warn "模拟运行模式"
fi

# 创建输出目录结构
if [ "$DRY_RUN" = false ]; then
    mkdir -p "$OUTPUT_DIR"
fi

# 要备份的文件列表（按优先级）
declare -A REQUIRED_FILES=(
    ["openclaw.json"]="⭐⭐⭐ 必备 - 主配置文件"
    ["agents/main/agent/auth-profiles.json"]="⭐⭐⭐ 必备 - API Keys"
    ["agents/main/sessions/sessions.json"]="⭐⭐⭐ 必备 - 会话索引"
    ["credentials/oauth.json"]="⭐⭐⭐ 必备 - OAuth Token"
)

declare -A IMPORTANT_FILES=(
    ["agents/main/agent/models.json"]="⭐⭐ 重要 - 模型配置"
    ["agents/main/sessions/*.jsonl"]="⭐⭐ 重要 - 对话历史"
    ["memory/MEMORY.md"]="⭐⭐ 重要 - 长期记忆"
    ["cron/jobs.json"]="⭐⭐ 重要 - 定时任务"
)

declare -A OPTIONAL_FILES=(
    ["memory/lancedb/"]="⭐ 可选 - 向量数据库"
    ["plugins/"]="⭐ 可选 - 插件配置"
    ["snapshots/"]="⭐ 可选 - 历史快照"
)

# 统计
total_files=0
copied_files=0
excluded_files=0

# 复制文件函数
copy_file() {
    local src="$1"
    local dst="$2"
    local desc="$3"
    
    if [ ! -e "$src" ]; then
        log_warn "跳过（不存在）: $src"
        ((excluded_files++))
        return
    fi
    
    # 检查文件大小（10MB 限制）
    if [ -f "$src" ]; then
        local size=$(stat -f%z "$src" 2>/dev/null || stat -c%s "$src" 2>/dev/null || echo 0)
        local size_mb=$((size / 1024 / 1024))
        
        if [ "$size_mb" -gt 10 ]; then
            log_warn "跳过（过大 ${size_mb}MB）: $src"
            ((excluded_files++))
            return
        fi
    fi
    
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$(dirname "$dst")"
        
        if [ -d "$src" ]; then
            cp -r "$src" "$dst"
        else
            cp "$src" "$dst"
            
            # 脱敏处理
            if [[ "$src" == *"auth-profiles.json"* ]] || [[ "$src" == *"oauth.json"* ]] || [[ "$src" == *"creds.json"* ]]; then
                log_info "脱敏处理: $dst"
                sed -i 's/"token": "[^"]*"/"token": "{{SECRET:token}}"/g' "$dst" 2>/dev/null || true
                sed -i 's/"api_key": "[^"]*"/"api_key": "{{SECRET:api_key}}"/g' "$dst" 2>/dev/null || true
                sed -i 's/"secret": "[^"]*"/"secret": "{{SECRET:secret}}"/g' "$dst" 2>/dev/null || true
            fi
        fi
    fi
    
    log_success "$desc"
    ((copied_files++))
}

log_info ""
log_info "备份 ⭐⭐⭐ 必备文件..."
for file in "${!REQUIRED_FILES[@]}"; do
    src="${STATE_DIR}/${file}"
    dst="${OUTPUT_DIR}/${file}"
    copy_file "$src" "$dst" "${REQUIRED_FILES[$file]}"
done

log_info ""
log_info "备份 ⭐⭐ 重要文件..."
for file in "${!IMPORTANT_FILES[@]}"; do
    # 处理通配符
    for src in ${STATE_DIR}/${file}; do
        if [ -e "$src" ]; then
            rel_path="${src#$STATE_DIR/}"
            dst="${OUTPUT_DIR}/${rel_path}"
            copy_file "$src" "$dst" "${IMPORTANT_FILES[$file]}"
        fi
    done
done

log_info ""
log_info "备份 ⭐ 可选文件..."
for file in "${!OPTIONAL_FILES[@]}"; do
    src="${STATE_DIR}/${file}"
    dst="${OUTPUT_DIR}/${file}"
    copy_file "$src" "$dst" "${OPTIONAL_FILES[$file]}"
done

# 生成 manifest.json
if [ "$DRY_RUN" = false ]; then
cat > "${OUTPUT_DIR}/manifest.json" << EOF
{
  "version": "3.0.0",
  "name": "kimiclaw",
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "generated_by": "$(whoami)@$(hostname)",
  "state_dir": "${STATE_DIR}",
  "stats": {
    "copied_files": ${copied_files},
    "excluded_files": ${excluded_files}
  },
  "directories": [
    "openclaw.json",
    "agents/",
    "credentials/",
    "memory/",
    "cron/"
  ]
}
EOF
fi

log_info ""
log_info "=========================="
log_success "快照生成完成!"
log_info "输出目录: $OUTPUT_DIR"
log_info "已复制: $copied_files 个文件"
log_info "已排除: $excluded_files 个文件"
