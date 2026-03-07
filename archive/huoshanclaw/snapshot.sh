#!/bin/bash
#
# HuoshanClaw Snapshot Generator
# 生成符合 huoshanclaw 目录结构的快照
#

set -euo pipefail

OUTPUT_DIR="${1:-./huoshanclaw-snapshot}"
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
    OUTPUT_DIR="${2:-./huoshanclaw-snapshot}"
fi

log_info "HuoshanClaw Snapshot Generator"
log_info "=============================="
log_info "输出目录: $OUTPUT_DIR"

if [ "$DRY_RUN" = true ]; then
    log_warn "模拟运行模式"
fi

# 创建输出目录结构
if [ "$DRY_RUN" = false ]; then
    mkdir -p "$OUTPUT_DIR"
fi

# 要备份的文件列表（按优先级）
REQUIRED_FILES=(
    "openclaw.json|⭐⭐⭐ 必备 - 主配置文件（渠道、模型、Agent、Hook）"
    "agents/main/agent/auth-profiles.json|⭐⭐⭐ 必备 - 所有 API Key（OpenAI/Anthropic/etc）"
    "agents/main/sessions/sessions.json|⭐⭐⭐ 必备 - 会话索引（记录所有对话的元信息）"
    "credentials/oauth.json|⭐⭐⭐ 必备 - Web/OAuth token"
    "credentials/feishu-pairing.json|⭐⭐⭐ 必备 - 飞书配对信息"
    "memory/main.sqlite|⭐⭐⭐ 必备 - 主记忆数据库（SQLite）"
    "workspace/AGENTS.md|⭐⭐⭐ 必备 - Agent 工作区配置"
    "workspace/SOUL.md|⭐⭐⭐ 必备 - Agent 人格和灵魂"
    "workspace/USER.md|⭐⭐⭐ 必备 - 用户信息"
    "workspace/IDENTITY.md|⭐⭐⭐ 必备 - Agent 身份"
    "workspace/memory/|⭐⭐⭐ 必备 - 短期记忆日志（每日对话）"
)

IMPORTANT_FILES=(
    ".env|⭐⭐ 重要 - 环境变量"
    "agents/main/agent/models.json|⭐⭐ 重要 - 模型配置（可重新生成，但备份省时）"
    "agents/main/sessions/*.jsonl|⭐⭐ 重要 - 对话 transcript（对话历史本身）"
    "workspace/TOOLS.md|⭐⭐ 重要 - 工具配置"
    "workspace/HEARTBEAT.md|⭐⭐ 重要 - 心跳检查清单"
    "workspace/skills/|⭐⭐ 重要 - 自定义 Skills"
    "workspace/tasks.json|⭐⭐ 重要 - 任务管理数据库"
    "cron/jobs.json|⭐⭐ 重要 - 定时任务配置"
    "identity/device.json|⭐⭐ 重要 - 设备身份信息"
)

# 统计
total_files=0
copied_files=0
excluded_files=0
total_size=0

# 复制文件函数
copy_file() {
    local src_pattern="$1"
    local desc="$2"
    
    # 展开通配符（忽略不存在的文件）
    local files=()
    for f in $STATE_DIR/$src_pattern; do
        if [ -e "$f" ]; then
            files+=("$f")
        fi
    done
    
    if [ ${#files[@]} -eq 0 ]; then
        log_warn "跳过（不存在）: $src_pattern"
        ((excluded_files++))
        return 0
    fi
    
    for src in "${files[@]}"; do
        ((total_files++))
        
        # 检查文件大小（默认 10MB 限制，记忆文件放宽到 100MB）
        local size_limit=10485760  # 10MB
        if [[ "$src" == *"memory"* || "$src" == *"sessions"* ]]; then
            size_limit=104857600  # 100MB
        fi
        
        if [ -f "$src" ]; then
            local size=$(stat -c%s "$src" 2>/dev/null || echo 0)
            
            if [ "$size" -gt "$size_limit" ]; then
                local size_mb=$((size / 1024 / 1024))
                local limit_mb=$((size_limit / 1024 / 1024))
                log_warn "跳过（过大 ${size_mb}MB > ${limit_mb}MB）: $src_pattern"
                ((excluded_files++))
                continue
            fi
            
            ((total_size += size))
        fi
        
        local rel_path="${src#$STATE_DIR/}"
        local dst="$OUTPUT_DIR/$rel_path"
        
        log_info "复制: $rel_path"
        log_info "  $desc"
        
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$(dirname "$dst")"
            
            if [ -d "$src" ]; then
                cp -r "$src" "$dst"
            else
                cp "$src" "$dst"
            fi
            
            if [ $? -eq 0 ]; then
                ((copied_files++))
            else
                log_error "复制失败: $src_pattern"
                ((excluded_files++))
            fi
        else
            ((copied_files++))
        fi
    done
}

# 开始复制
log_info ""
log_info "开始复制必备文件..."
log_info "====================="

for entry in "${REQUIRED_FILES[@]}"; do
    IFS='|' read -r file desc <<< "$entry"
    copy_file "$file" "$desc"
done

log_info ""
log_info "开始复制重要文件..."
log_info "====================="

for entry in "${IMPORTANT_FILES[@]}"; do
    IFS='|' read -r file desc <<< "$entry"
    copy_file "$file" "$desc"
done

# 生成说明文件
if [ "$DRY_RUN" = false ]; then
    cat > "$OUTPUT_DIR/README_SNAPSHOT.md" << EOF
# HuoshanClaw 快照

**生成时间:** $(date '+%Y-%m-%d %H:%M:%S')
**生成工具:** snapshot.sh
**文件统计:** 
- 总文件数: $total_files
- 复制成功: $copied_files
- 跳过: $excluded_files
- 总大小: $((total_size / 1024 / 1024))MB

## 快照包含内容

### ⭐⭐⭐ 必备文件
$(for entry in "${REQUIRED_FILES[@]}"; do IFS='|' read -r f d <<< "$entry"; echo "- $f: $d"; done)

### ⭐⭐ 重要文件
$(for entry in "${IMPORTANT_FILES[@]}"; do IFS='|' read -r f d <<< "$entry"; echo "- $f: $d"; done)

## 恢复步骤

1. 停止 Gateway: \`openclaw gateway stop\`
2. 备份当前状态: \`mv ~/.openclaw ~/.openclaw.backup.$(date +%Y%m%d)\`
3. 复制快照内容: \`cp -r ./huoshanclaw-snapshot/* ~/.openclaw/\`
4. 启动 Gateway: \`openclaw gateway start\`

EOF
fi

# 统计结果
log_info ""
log_info "快照生成完成！"
log_info "====================="
log_info "总文件数: $total_files"
log_info "复制成功: $copied_files"
log_info "跳过: $excluded_files"
log_info "总大小: $((total_size / 1024 / 1024))MB"
log_info "输出目录: $OUTPUT_DIR"

if [ "$DRY_RUN" = false ]; then
    log_success "快照文件已生成: $OUTPUT_DIR"
    log_success "说明文件: $OUTPUT_DIR/README_SNAPSHOT.md"
fi
