#!/bin/bash
# cron-helper.sh: Cron 任务执行辅助函数

CRON_EXECUTOR_DIR="${HOME}/.openclaw/cron-executor"
mkdir -p "$CRON_EXECUTOR_DIR"/{locks,status,logs}

# 日志函数
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*" | tee -a "$CRON_EXECUTOR_DIR/logs/cron-executor.log"
}

log_warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $*" | tee -a "$CRON_EXECUTOR_DIR/logs/cron-executor.log"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" | tee -a "$CRON_EXECUTOR_DIR/logs/cron-executor.log"
}

# 防重入锁
cron_guard() {
    local job_name="$1"
    local timeout="${2:-600}"  # 默认10分钟超时
    local lock_file="$CRON_EXECUTOR_DIR/locks/${job_name}.lock"
    
    # 检查是否已有锁
    if [ -f "$lock_file" ]; then
        local lock_time=$(cat "$lock_file")
        local current_time=$(date +%s)
        local elapsed=$((current_time - lock_time))
        
        if [ $elapsed -lt $timeout ]; then
            log_warn "Job '$job_name' is already running (locked ${elapsed}s ago)"
            return 1
        else
            log_warn "Job '$job_name' lock expired (${elapsed}s > ${timeout}s), forcing unlock"
            rm -f "$lock_file"
        fi
    fi
    
    # 创建锁
    date +%s > "$lock_file"
    log_info "Job '$job_name' locked"
    
    # 设置退出时自动解锁
    trap "cron_unlock '$job_name'" EXIT
    
    return 0
}

# 解锁
cron_unlock() {
    local job_name="$1"
    local lock_file="$CRON_EXECUTOR_DIR/locks/${job_name}.lock"
    
    rm -f "$lock_file"
    log_info "Job '$job_name' unlocked"
}

# 记录状态
record_status() {
    local job_name="$1"
    local status="$2"  # success/failed
    local error_msg="${3:-}"
    local status_file="$CRON_EXECUTOR_DIR/status/${job_name}.json"
    
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local fail_count=0
    
    # 读取现有状态
    if [ -f "$status_file" ]; then
        fail_count=$(jq -r '.fail_count // 0' "$status_file" 2>/dev/null || echo 0)
    fi
    
    # 更新失败计数
    if [ "$status" == "failed" ]; then
        fail_count=$((fail_count + 1))
    else
        fail_count=0
    fi
    
    # 写入新状态
    cat > "$status_file" << EOF
{
  "job_name": "$job_name",
  "last_run": "$timestamp",
  "last_status": "$status",
  "fail_count": $fail_count,
  "last_error": "$error_msg"
}
EOF
}

# 指数退避重试
with_backoff() {
    local max_retries=3
    local base_delay=30
    local attempt=0
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --max-retries) max_retries="$2"; shift 2 ;;
            --base-delay) base_delay="$2"; shift 2 ;;
            --) shift; break ;;
            *) break ;;
        esac
    done
    
    local cmd="$@"
    
    while [ $attempt -lt $max_retries ]; do
        log_info "Attempt $((attempt + 1))/$max_retries: $cmd"
        
        if eval "$cmd"; then
            log_info "Command succeeded on attempt $((attempt + 1))"
            return 0
        fi
        
        local exit_code=$?
        attempt=$((attempt + 1))
        
        if [ $attempt -lt $max_retries ]; then
            # 计算退避时间: base * 2^attempt
            local backoff=$((base_delay * (2 ** (attempt - 1))))
            log_warn "Command failed with exit code $exit_code, waiting ${backoff}s before retry"
            sleep $backoff
        fi
    done
    
    log_error "Command failed after $max_retries attempts: $cmd"
    return 1
}

# 通知用户
notify_user() {
    local title="$1"
    local message="$2"
    
    # 使用 OpenClaw 的消息工具发送通知
    echo ""
    echo "📢 $title"
    echo "=============="
    echo "$message"
    echo ""
}

# 检查是否应该跳过（基于上次失败时间）
should_skip_due_to_failure() {
    local job_name="$1"
    local min_interval="${2:-300}"  # 默认5分钟
    local status_file="$CRON_EXECUTOR_DIR/status/${job_name}.json"
    
    if [ ! -f "$status_file" ]; then
        return 1  # 没有状态文件，不跳过
    fi
    
    local last_run=$(jq -r '.last_run // empty' "$status_file" 2>/dev/null)
    local last_status=$(jq -r '.last_status // empty' "$status_file" 2>/dev/null)
    
    if [ "$last_status" != "failed" ]; then
        return 1  # 上次成功，不跳过
    fi
    
    # 解析上次运行时间
    local last_ts=$(date -d "$last_run" +%s 2>/dev/null || echo 0)
    local current_ts=$(date +%s)
    local elapsed=$((current_ts - last_ts))
    
    if [ $elapsed -lt $min_interval ]; then
        log_warn "Skipping job '$job_name' - last failure was ${elapsed}s ago (min interval: ${min_interval}s)"
        return 0
    fi
    
    return 1
}
