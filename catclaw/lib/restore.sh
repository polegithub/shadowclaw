#!/bin/bash
#
# CatClaw Restore
# 从快照恢复环境（恢复前自动备份当前状态）
#

set -e

SNAPSHOT_DIR="$1"
FORCE=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ "$1" = "--force" ]; then
    FORCE=true
    SNAPSHOT_DIR="$2"
fi

if [ -z "$SNAPSHOT_DIR" ]; then
    log_error "请指定快照目录"
    echo "用法: restore.sh [--force] <snapshot-dir>"
    exit 1
fi

if [ ! -d "$SNAPSHOT_DIR" ]; then
    log_error "快照目录不存在: $SNAPSHOT_DIR"
    exit 1
fi

STATE_DIR="${HOME}/.openclaw"
BACKUP_DIR="${STATE_DIR}/backup/$(date +%Y%m%d-%H%M%S)"

log_info "🐱 CatClaw Restore v1.0"
log_info "========================"
log_info "快照来源: $SNAPSHOT_DIR"
log_info "目标目录: $STATE_DIR"

# 检查 manifest
if [ -f "$SNAPSHOT_DIR/manifest.json" ]; then
    log_info "快照信息:"
    cat "$SNAPSHOT_DIR/manifest.json" | grep -E '"(name|generated_at|based_on)"' | sed 's/^/  /'
fi

if [ "$FORCE" = false ]; then
    log_warn "⚠️  此操作将覆盖现有配置!"
    read -p "是否继续? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "已取消"
        exit 0
    fi
fi

# ==========================================
# 自动备份当前环境
# ==========================================
log_info ""
log_info "📦 自动备份当前环境..."
mkdir -p "$BACKUP_DIR"

backup_if_exists() {
    local src="$1"
    local dst="$BACKUP_DIR/$(echo "$src" | sed "s|$STATE_DIR/||")"
    if [ -e "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        cp -r "$src" "$dst"
    fi
}

backup_if_exists "$STATE_DIR/openclaw.json"
backup_if_exists "$STATE_DIR/agents"
backup_if_exists "$STATE_DIR/credentials"
backup_if_exists "$STATE_DIR/memory"
backup_if_exists "$STATE_DIR/workspace"
backup_if_exists "$STATE_DIR/cron"
backup_if_exists "$STATE_DIR/identity"
backup_if_exists "$STATE_DIR/.env"

log_success "已备份到: $BACKUP_DIR"

# ==========================================
# 恢复文件
# ==========================================
log_info ""
log_info "📥 恢复文件..."

restore_item() {
    local src="$1"
    local dst="$2"
    local desc="$3"

    if [ ! -e "$src" ]; then
        return
    fi

    mkdir -p "$(dirname "$dst")"

    if [ -d "$src" ]; then
        cp -r "$src/"* "$dst/" 2>/dev/null || true
    else
        cp "$src" "$dst"
    fi

    log_success "恢复: $desc"
}

# 主配置
restore_item "$SNAPSHOT_DIR/openclaw.json" "$STATE_DIR/openclaw.json" "openclaw.json"

# Agents
if [ -d "$SNAPSHOT_DIR/agents" ]; then
    mkdir -p "$STATE_DIR/agents"
    restore_item "$SNAPSHOT_DIR/agents" "$STATE_DIR/agents" "agents/"
fi

# Credentials
if [ -d "$SNAPSHOT_DIR/credentials" ]; then
    mkdir -p "$STATE_DIR/credentials"
    restore_item "$SNAPSHOT_DIR/credentials" "$STATE_DIR/credentials" "credentials/"
fi

# Memory
if [ -d "$SNAPSHOT_DIR/memory" ]; then
    mkdir -p "$STATE_DIR/memory"
    restore_item "$SNAPSHOT_DIR/memory" "$STATE_DIR/memory" "memory/"
fi

# Workspace
if [ -d "$SNAPSHOT_DIR/workspace" ]; then
    mkdir -p "$STATE_DIR/workspace"
    restore_item "$SNAPSHOT_DIR/workspace" "$STATE_DIR/workspace" "workspace/"
fi

# Cron
if [ -d "$SNAPSHOT_DIR/cron" ]; then
    mkdir -p "$STATE_DIR/cron"
    restore_item "$SNAPSHOT_DIR/cron" "$STATE_DIR/cron" "cron/"
fi

# Identity（来自 huoshanclaw）
if [ -d "$SNAPSHOT_DIR/identity" ]; then
    mkdir -p "$STATE_DIR/identity"
    restore_item "$SNAPSHOT_DIR/identity" "$STATE_DIR/identity" "identity/"
fi

# .env（来自 huoshanclaw）
restore_item "$SNAPSHOT_DIR/.env" "$STATE_DIR/.env" ".env"

# ==========================================
# 完成
# ==========================================
log_info ""
log_success "🐱 CatClaw 恢复完成!"
log_info ""
log_warn "⚠️  恢复后请完成以下步骤:"
echo "  1. 检查 secrets-template.json，填入真实凭证"
echo "  2. 编辑 $STATE_DIR/openclaw.json 替换 {{SECRET:xxx}} 占位符"
echo "  3. 编辑 $STATE_DIR/.env 替换敏感环境变量"
echo "  4. 重启 Gateway: openclaw gateway restart"
echo "  5. 验证: openclaw status"
log_info ""
log_info "如需回滚，备份位于: $BACKUP_DIR"
