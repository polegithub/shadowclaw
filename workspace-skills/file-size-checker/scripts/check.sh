#!/bin/bash
# 智能文件大小检测和过滤工具

set -e

MAX_SIZE_MB=${MAX_SIZE_MB:-50}
WHITELIST=${WHITELIST:-}
BLACKLIST=${BLACKLIST:-}

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

# 格式化文件大小
format_size() {
    local size=$1
    if [ $size -ge 1073741824 ]; then
        echo "$(echo "scale=2; $size/1073741824" | bc)G"
    elif [ $size -ge 1048576 ]; then
        echo "$(echo "scale=2; $size/1048576" | bc)M"
    elif [ $size -ge 1024 ]; then
        echo "$(echo "scale=2; $size/1024" | bc)K"
    else
        echo "${size}B"
    fi
}

# 检查是否在白名单
is_whitelisted() {
    local file=$1
    if [ -z "$WHITELIST" ]; then
        return 1
    fi
    [[ "$WHITELIST" == *"$file"* ]]
}

# 检查是否在黑名单
is_blacklisted() {
    local file=$1
    if [ -z "$BLACKLIST" ]; then
        return 1
    fi
    [[ "$BLACKLIST" == *"$file"* ]]
}

# 扫描目录
scan_directory() {
    local dir=$1
    
    if [ ! -d "$dir" ]; then
        log_error "目录不存在: $dir"
        return 1
    fi
    
    echo ""
    echo "📊 文件大小报告"
    echo "================"
    echo ""
    echo "扫描目录: $dir"
    echo "大小阈值: ${MAX_SIZE_MB}MB"
    echo ""
    
    local large_files=()
    local small_files=()
    local total_large_size=0
    local total_small_size=0
    
    while IFS= read -r -d '' file; do
        local size=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null)
        local size_mb=$(echo "scale=2; $size/1048576" | bc 2>/dev/null || echo 0)
        
        # 检查黑名单
        if is_blacklisted "$file"; then
            log_warning "跳过（黑名单）: $file"
            continue
        fi
        
        # 检查白名单
        if is_whitelisted "$file"; then
            small_files+=("$file")
            total_small_size=$((total_small_size + size))
            continue
        fi
        
        # 检查大小
        if (( $(echo "$size_mb > $MAX_SIZE_MB" | bc -l) )); then
            large_files+=("$file")
            total_large_size=$((total_large_size + size))
        else
            small_files+=("$file")
            total_small_size=$((total_small_size + size))
        fi
    done < <(find "$dir" -type f -print0 2>/dev/null)
    
    # 显示大文件
    if [ ${#large_files[@]} -gt 0 ]; then
        echo "⚠️ 大文件（超过 ${MAX_SIZE_MB}MB）:"
        echo ""
        local i=1
        for file in "${large_files[@]}"; do
            local size=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null)
            local formatted_size=$(format_size $size)
            local rel_path="${file#$dir/}"
            echo "  $i. $rel_path ($formatted_size) - 建议跳过"
            ((i++))
        done
        echo ""
        echo "大文件总计: $(format_size $total_large_size)"
        echo ""
    fi
    
    # 显示小文件
    if [ ${#small_files[@]} -gt 0 ]; then
        echo "✅ 可安全备份:"
        echo ""
        echo "  文件数量: ${#small_files[@]}"
        echo "  总计大小: $(format_size $total_small_size)"
        echo ""
    fi
    
    # 总结
    echo "📋 建议:"
    echo "  跳过: ${#large_files[@]} 个文件 ($(format_size $total_large_size))"
    echo "  备份: ${#small_files[@]} 个文件 ($(format_size $total_small_size))"
    echo ""
}

# 快照前检查
pre_snapshot_check() {
    echo "🔍 快照前检查"
    echo "==============="
    echo ""
    
    local dir="$HOME/.openclaw"
    
    # 检查常见的大文件目录
    log_info "检查 extensions 目录..."
    if [ -d "$dir/extensions" ]; then
        local ext_size=$(du -sm "$dir/extensions" 2>/dev/null | cut -f1)
        if [ "$ext_size" -gt "$MAX_SIZE_MB" ]; then
            log_warning "extensions 目录很大: ${ext_size}MB - 建议跳过"
        fi
    fi
    
    # 检查 node_modules
    log_info "检查 node_modules..."
    local nm_count=$(find "$dir" -name "node_modules" -type d 2>/dev/null | wc -l | tr -d ' ')
    if [ "$nm_count" -gt 0 ]; then
        log_warning "发现 $nm_count 个 node_modules 目录 - 建议跳过"
    fi
    
    echo ""
    log_info "运行完整扫描..."
    scan_directory "$dir"
}

# 显示帮助
show_help() {
    echo "File Size Checker v1.0.0"
    echo ""
    echo "用法: ./scripts/check.sh [命令] [目录]"
    echo ""
    echo "命令:"
    echo "  scan <dir>     - 扫描指定目录"
    echo "  pre-snapshot   - 快照前检查（扫描 ~/.openclaw）"
    echo "  help           - 显示帮助"
    echo ""
    echo "环境变量:"
    echo "  MAX_SIZE_MB    - 大小阈值（默认 50）"
    echo "  WHITELIST      - 白名单文件（空格分隔）"
    echo "  BLACKLIST      - 黑名单文件（空格分隔）"
    echo ""
    echo "示例:"
    echo "  ./scripts/check.sh scan ~/.openclaw"
    echo "  MAX_SIZE_MB=100 ./scripts/check.sh pre-snapshot"
    echo "  BLACKLIST='node_modules extensions' ./scripts/check.sh scan ~/.openclaw"
}

# 主函数
main() {
    case "${1:-help}" in
        scan)
            scan_directory "$2"
            ;;
        pre-snapshot)
            pre_snapshot_check
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
