#!/bin/bash
# OpenClaw 智能快照同步系统 v2.0
# 设计原则：与 OpenClaw 目录结构一致，Git 友好，智能过滤

set -e

# ==================== 配置 ====================
OPENCLAW_DIR="$HOME/.openclaw"
SYNC_DIR="$HOME/.openclaw-sync"
MAX_FILE_SIZE_MB=50  # 超过 50MB 的文件跳过
GIT_REPO="${GIT_REPO:-}"

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

# ==================== 工具函数 ====================

# 检查文件大小
check_file_size() {
    local file="$1"
    local size_mb=$(du -m "$file" 2>/dev/null | cut -f1)
    
    if [ "$size_mb" -gt "$MAX_FILE_SIZE_MB" ] 2>/dev/null; then
        return 1  # 太大，跳过
    fi
    return 0  # 可以备份
}

# 初始化同步目录
init_sync_dir() {
    if [ ! -d "$SYNC_DIR" ]; then
        log_info "创建同步目录: $SYNC_DIR"
        mkdir -p "$SYNC_DIR"
    fi
    
    cd "$SYNC_DIR"
    
    if [ ! -d ".git" ]; then
        log_info "初始化 Git 仓库"
        git init
        git config user.name "OpenClaw Sync"
        git config user.email "openclaw-sync@localhost"
        
        # 创建 .gitignore
        cat > .gitignore <<EOF
# 大文件（超过 ${MAX_FILE_SIZE_MB}MB）
*.tar.gz
*.zip
*.log
node_modules/
extensions/
cache/
tmp/
temp/
EOF
        
        # 创建 README
        cat > README.md <<EOF
# OpenClaw Sync

智能快照同步系统。

## 目录结构

\`\`\`
config/          # ~/.openclaw/config
agents/          # ~/.openclaw/agents
workspace-skills/ # ~/.openclaw/workspace/skills
snapshot.json    # 快照元数据
\`\`\`

## 恢复方法

### 方法一：如果已有 openclaw-sync skill

\`\`\`bash
cd ~/.openclaw/workspace/skills/openclaw-sync
./scripts/sync.sh restore
\`\`\`

### 方法二：如果是全新的 OpenClaw

1. 先把这个仓库 clone 下来：
\`\`\`bash
git clone <this-repo-url> ~/.openclaw-sync
cd ~/.openclaw-sync
\`\`\`

2. 手动复制内容：
\`\`\`bash
# 复制配置
cp -r config/* ~/.openclaw/config/ 2>/dev/null || true

# 复制 agents
cp -r agents/* ~/.openclaw/agents/ 2>/dev/null || true

# 复制 skills
cp -r workspace-skills/* ~/.openclaw/workspace/skills/ 2>/dev/null || true
\`\`\`

3. 然后你就有 openclaw-sync skill 了，以后可以用它来管理快照！

## 快照信息

详见 snapshot.json
EOF
        
        git add .
        git commit -m "Initial commit: OpenClaw sync repo"
    fi
}

# 创建快照元数据
create_snapshot_metadata() {
    cat > "$SYNC_DIR/snapshot.json" <<EOF
{
  "version": "2.0.0",
  "timestamp": "$(date -Iseconds)",
  "hostname": "$(hostname)",
  "max_file_size_mb": $MAX_FILE_SIZE_MB,
  "summary": {
    "config": "$(ls -la "$OPENCLAW_DIR/config" 2>/dev/null | wc -l | tr -d ' ')",
    "agents": "$(ls -la "$OPENCLAW_DIR/agents" 2>/dev/null | wc -l | tr -d ' ')",
    "skills": "$(ls -la "$OPENCLAW_DIR/workspace/skills" 2>/dev/null | wc -l | tr -d ' ')"
  }
}
EOF
}

# ==================== 核心功能 ====================

# 创建快照
create_snapshot() {
    log_info "开始创建快照..."
    
    init_sync_dir
    cd "$SYNC_DIR"
    
    # 清理旧内容（保留 .git）
    log_info "清理旧快照..."
    rm -rf config agents workspace-skills 2>/dev/null
    mkdir -p config agents workspace-skills
    
    local skipped_count=0
    local copied_count=0
    
    # 1. 备份 config
    log_info "备份 config..."
    if [ -d "$OPENCLAW_DIR/config" ]; then
        while IFS= read -r -d '' file; do
            if check_file_size "$file"; then
                local rel_path="${file#$OPENCLAW_DIR/config/}"
                local dest_dir="$SYNC_DIR/config/$(dirname "$rel_path")"
                mkdir -p "$dest_dir"
                cp "$file" "$dest_dir/" 2>/dev/null
                ((copied_count++))
            else
                log_warning "跳过大文件: $file"
                ((skipped_count++))
            fi
        done < <(find "$OPENCLAW_DIR/config" -type f -print0)
    fi
    
    # 2. 备份 agents
    log_info "备份 agents..."
    if [ -d "$OPENCLAW_DIR/agents" ]; then
        while IFS= read -r -d '' file; do
            if check_file_size "$file"; then
                local rel_path="${file#$OPENCLAW_DIR/agents/}"
                local dest_dir="$SYNC_DIR/agents/$(dirname "$rel_path")"
                mkdir -p "$dest_dir"
                cp "$file" "$dest_dir/" 2>/dev/null
                ((copied_count++))
            else
                log_warning "跳过大文件: $file"
                ((skipped_count++))
            fi
        done < <(find "$OPENCLAW_DIR/agents" -type f -print0)
    fi
    
    # 3. 备份 skills（包括 openclaw-sync 和 file-size-checker 自身）
    log_info "备份 skills..."
    if [ -d "$OPENCLAW_DIR/workspace/skills" ]; then
        while IFS= read -r -d '' file; do
            if check_file_size "$file"; then
                local rel_path="${file#$OPENCLAW_DIR/workspace/skills/}"
                local dest_dir="$SYNC_DIR/workspace-skills/$(dirname "$rel_path")"
                mkdir -p "$dest_dir"
                cp "$file" "$dest_dir/" 2>/dev/null
                ((copied_count++))
            else
                log_warning "跳过大文件: $file"
                ((skipped_count++))
            fi
        done < <(find "$OPENCLAW_DIR/workspace/skills" -type f -print0)
    fi
    
    # 创建元数据
    create_snapshot_metadata
    
    # Git 提交
    log_info "Git 提交..."
    git add .
    git commit -m "Sync snapshot: $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null || {
        log_warning "没有新的变更需要提交"
    }
    
    log_success "快照创建完成！"
    echo "  已复制: $copied_count 个文件"
    echo "  已跳过: $skipped_count 个大文件"
    echo "  同步目录: $SYNC_DIR"
}

# 推送到远程仓库
push_to_remote() {
    if [ -z "$GIT_REPO" ]; then
        log_error "请设置 GIT_REPO 环境变量"
        echo "示例: export GIT_REPO=git@github.com:username/repo.git"
        return 1
    fi
    
    cd "$SYNC_DIR"
    
    # 设置远程仓库
    if ! git remote | grep -q "^origin$"; then
        git remote add origin "$GIT_REPO"
    else
        git remote set-url origin "$GIT_REPO"
    fi
    
    log_info "推送到远程仓库..."
    git push -u origin main || git push -u origin master
}

# 从快照恢复
restore_snapshot() {
    log_info "开始恢复快照..."
    
    if [ ! -d "$SYNC_DIR" ]; then
        log_error "同步目录不存在: $SYNC_DIR"
        return 1
    fi
    
    cd "$SYNC_DIR"
    
    # 显示快照信息
    if [ -f "snapshot.json" ]; then
        log_info "快照信息:"
        cat snapshot.json | jq .
    fi
    
    # 确认
    echo ""
    read -p "确认恢复？这将覆盖当前的 OpenClaw 配置！(yes/NO): " confirm
    if [ "$confirm" != "yes" ] && [ "$confirm" != "YES" ]; then
        log_info "已取消"
        return
    fi
    
    # 恢复 config
    if [ -d "config" ]; then
        log_info "恢复 config..."
        mkdir -p "$OPENCLAW_DIR/config"
        cp -r config/* "$OPENCLAW_DIR/config/" 2>/dev/null || true
    fi
    
    # 恢复 agents
    if [ -d "agents" ]; then
        log_info "恢复 agents..."
        mkdir -p "$OPENCLAW_DIR/agents"
        cp -r agents/* "$OPENCLAW_DIR/agents/" 2>/dev/null || true
    fi
    
    # 恢复 skills
    if [ -d "workspace-skills" ]; then
        log_info "恢复 skills..."
        mkdir -p "$OPENCLAW_DIR/workspace/skills"
        cp -r workspace-skills/* "$OPENCLAW_DIR/workspace/skills/" 2>/dev/null || true
    fi
    
    log_success "快照恢复完成！"
    echo "建议重启 OpenClaw Gateway"
}

# 显示帮助
show_help() {
    echo "OpenClaw Sync v2.0.0"
    echo ""
    echo "用法: ./scripts/sync.sh [命令]"
    echo ""
    echo "命令:"
    echo "  snapshot    - 创建快照"
    echo "  push        - 推送到远程仓库（需设置 GIT_REPO）"
    echo "  restore     - 从快照恢复"
    echo "  status      - 显示状态"
    echo "  help        - 显示帮助"
    echo ""
    echo "环境变量:"
    echo "  GIT_REPO    - Git 远程仓库 URL"
    echo "  MAX_FILE_SIZE_MB - 最大文件大小（默认 50MB）"
    echo ""
    echo "示例:"
    echo "  ./scripts/sync.sh snapshot"
    echo "  export GIT_REPO=git@github.com:user/repo.git"
    echo "  ./scripts/sync.sh push"
    echo "  ./scripts/sync.sh restore"
}

# 显示状态
show_status() {
    echo "OpenClaw Sync Status"
    echo "===================="
    echo ""
    
    if [ -d "$SYNC_DIR/.git" ]; then
        echo "✓ Git 仓库: 已初始化"
        
        cd "$SYNC_DIR"
        echo "  分支: $(git branch --show-current)"
        echo "  最后提交: $(git log -1 --pretty=format:'%h %s' 2>/dev/null || 'none')"
        
        if [ -f "snapshot.json" ]; then
            echo ""
            echo "✓ 快照元数据:"
            cat snapshot.json
        fi
    else
        echo "✗ Git 仓库: 未初始化"
    fi
    
    echo ""
    echo "同步目录: $SYNC_DIR"
}

# ==================== 主函数 ====================

main() {
    case "${1:-help}" in
        snapshot)
            create_snapshot
            ;;
        push)
            push_to_remote
            ;;
        restore)
            restore_snapshot
            ;;
        status)
            show_status
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
