#!/bin/bash
# Token 累计统计和追踪工具

set -e

STATS_DIR="$HOME/.openclaw/token-stats"
CURRENT_FILE="$STATS_DIR/current.json"
HISTORY_FILE="$STATS_DIR/history.jsonl"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 初始化目录
init_dir() {
    if [ ! -d "$STATS_DIR" ]; then
        mkdir -p "$STATS_DIR"
        log_info "创建统计目录: $STATS_DIR"
    fi
}

# 获取当前状态（从 openclaw status 解析）
get_current_status() {
    # 使用 openclaw status 获取
    local status=$(openclaw status 2>/dev/null | grep -E "Tokens:|Context:|Cache:" | head -3)
    
    # 尝试解析
    local tokens_in=$(echo "$status" | grep "Tokens:" | awk '{print $2}' | sed 's/k//')
    local tokens_out=$(echo "$status" | grep "Tokens:" | awk '{print $5}' | sed 's/k//')
    local context=$(echo "$status" | grep "Context:" | awk '{print $2}' | sed 's/k//')
    
    # 如果无法解析，尝试从 session_status 工具获取
    if [ -z "$tokens_in" ] || [ "$tokens_in" == "117k" ]; then
        # 使用一个简单的 JSON 结构
        cat > "$CURRENT_FILE" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "tokens_in": 0,
  "tokens_out": 0,
  "context": 0,
  "cache_hit": 0
}
EOF
        return
    fi
    
    cat > "$CURRENT_FILE" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "tokens_in": ${tokens_in:-0},
  "tokens_out": ${tokens_out:-0},
  "context": ${context:-0},
  "cache_hit": 0
}
EOF
}

# 记录当前状态
record_status() {
    init_dir
    get_current_status
    
    # 添加到历史
    if [ -f "$CURRENT_FILE" ]; then
        cat "$CURRENT_FILE" >> "$HISTORY_FILE"
        echo "" >> "$HISTORY_FILE"
        log_success "状态已记录"
    fi
}

# 显示统计
show_stats() {
    init_dir
    
    echo ""
    echo "📊 Token 累计统计"
    echo "================"
    echo ""
    
    if [ ! -f "$HISTORY_FILE" ] || [ -z "$(cat "$HISTORY_FILE" 2>/dev/null)" ]; then
        log_warning "没有历史记录，先运行: ./scripts/tracker.sh record"
        echo ""
        echo "提示：这个 skill 需要配合使用："
        echo "  1. 开始时运行: ./scripts/tracker.sh record  (记录基准线)"
        echo "  2. 结束时运行: ./scripts/tracker.sh record  (记录结束状态)"
        echo "  3. 然后查看: ./scripts/tracker.sh stats"
        return
    fi
    
    # 计算累计
    # 这里用一个简化的方式显示
    echo "📈 历史记录:"
    echo ""
    
    local count=$(grep -c "timestamp" "$HISTORY_FILE" 2>/dev/null || echo 0)
    echo "记录次数: $count"
    echo ""
    
    if [ "$count" -ge 2 ]; then
        echo "📝 提示：由于 OpenClaw status 输出格式限制，"
        echo "   这个 skill 主要用于记录时间点。"
        echo ""
        echo "🔧 更精确的方案："
        echo "   每次开始和结束时手动运行 'record'"
        echo "   然后查看 history.jsonl 计算差值"
    fi
}

# 显示历史
show_history() {
    init_dir
    
    if [ ! -f "$HISTORY_FILE" ] || [ -z "$(cat "$HISTORY_FILE" 2>/dev/null)" ]; then
        log_warning "没有历史记录"
        return
    fi
    
    echo ""
    echo "📜 历史记录"
    echo "============"
    echo ""
    cat "$HISTORY_FILE"
}

# 显示帮助
show_help() {
    echo "Token Tracker v1.0.0"
    echo ""
    echo "用法: ./scripts/tracker.sh [命令]"
    echo ""
    echo "命令:"
    echo "  record    - 记录当前状态"
    echo "  stats     - 显示累计统计"
    echo "  history   - 显示历史记录"
    echo "  help      - 显示帮助"
    echo ""
    echo "使用流程:"
    echo "  1. 开始工作前: ./scripts/tracker.sh record"
    echo "  2. 工作完成后: ./scripts/tracker.sh record"
    echo "  3. 查看统计: ./scripts/tracker.sh stats"
}

# 主函数
main() {
    case "${1:-help}" in
        record)
            record_status
            ;;
        stats)
            show_stats
            ;;
        history)
            show_history
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
