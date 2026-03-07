#!/bin/bash
# token-tracker-wrapper.sh - 拦截 OpenClaw API 调用并记录 Token
# 
# 使用方法：
# 1. 将此脚本放在 PATH 中
# 2. 在 openclaw.json 中配置模型调用前置钩子
# 3. 或者手动包装 API 调用

TOKEN_TRACKER="${HOME}/.openclaw/workspace/skills/snapshot-sync/token-tracker.js"
NODE="${NODE:-node}"

# 记录 token 的函数
record_tokens() {
    local input_tokens=$1
    local output_tokens=$2
    local model=$3
    local provider=$4
    
    # 构造 JSON 数据
    local json_data=$(cat <<EOF
{
  "input": ${input_tokens:-0},
  "output": ${output_tokens:-0},
  "model": "${model:-unknown}",
  "provider": "${provider:-unknown}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"
}
EOF
)
    
    # 发送给 tracker
    echo "$json_data" | "$NODE" "$TOKEN_TRACKER" record 2>/dev/null &
}

# 解析 OpenClaw 日志并提取 token 使用
parse_openclaw_log() {
    local log_line="$1"
    
    # 尝试从日志中提取 token 信息
    # 格式示例: "Tokens: 1234 in / 567 out" 或类似
    if echo "$log_line" | grep -q "Tokens:"; then
        local input=$(echo "$log_line" | grep -oE '[0-9]+ in' | head -1 | grep -oE '[0-9]+')
        local output=$(echo "$log_line" | grep -oE '[0-9]+ out' | head -1 | grep -oE '[0-9]+')
        
        if [[ -n "$input" && -n "$output" ]]; then
            record_tokens "$input" "$output" "from-log" "openclaw"
        fi
    fi
}

# 从 session_status 获取当前统计
check_session_stats() {
    local status_output=$(openclaw status 2>&1)
    
    # 提取 token 信息
    local input=$(echo "$status_output" | grep -oE 'Tokens: [0-9]+k? in' | grep -oE '[0-9]+k?' | head -1)
    local output=$(echo "$status_output" | grep -oE '[0-9]+k? out' | grep -oE '[0-9]+k?' | head -1)
    
    # 转换 k 为单位
    input=$(echo "$input" | sed 's/k/000/')
    output=$(echo "$output" | sed 's/k/000/')
    
    if [[ -n "$input" && -n "$output" ]]; then
        # 检查是否有变化（简单比较）
        local last_file="${HOME}/.openclaw/token-tracker/.last_session_check"
        local current="${input}-${output}"
        
        if [[ -f "$last_file" ]]; then
            local last=$(cat "$last_file")
            if [[ "$last" != "$current" ]]; then
                record_tokens "$input" "$output" "kimi-k2p5" "kimi-coding"
            fi
        fi
        
        echo "$current" > "$last_file"
    fi
}

# 显示帮助
show_help() {
    cat <<EOF
Token Tracker Wrapper - OpenClaw Token 拦截器

用法:
  $0 record <input> <output> [model] [provider]  记录一次 token 使用
  $0 parse "<log line>"                                      解析日志行
  $0 check                                                    检查当前 session 状态
  $0 stats                                                    显示统计
  $0 export <snapshot-dir>                                   导出到快照

示例:
  $0 record 1000 500 kimi-k2p5 kimi-coding
  $0 parse "Tokens: 12k in / 94 out"
  $0 stats
EOF
}

# 主逻辑
case "${1:-}" in
    record)
        shift
        record_tokens "$1" "$2" "${3:-}" "${4:-}"
        ;;
    parse)
        shift
        parse_openclaw_log "$*"
        ;;
    check)
        check_session_stats
        ;;
    stats)
        "$NODE" "$TOKEN_TRACKER" stats
        ;;
    export)
        shift
        "$NODE" "$TOKEN_TRACKER" export "$1"
        ;;
    import)
        shift
        "$NODE" "$TOKEN_TRACKER" import "$1"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac