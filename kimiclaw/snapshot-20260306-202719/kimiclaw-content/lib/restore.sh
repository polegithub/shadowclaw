#!/bin/bash
#
# KimiClaw Restore
# 从快照恢复环境
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

# 检查参数
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

log_info "KimiClaw Restore"
log_info "==============="
log_info "快照来源: $SNAPSHOT_DIR"
log_info "目标目录: $STATE_DIR"

if [ "$FORCE" = false ]; then
    log_warn "此操作将覆盖现有配置!"
    read -p "是否继续? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "已取消"
        exit 0
    fi
fi

# 备份当前环境
log_info ""
log_info "备份当前环境..."
mkdir -p "$BACKUP_DIR"

if [ -d "$STATE_DIR" ]; then
    # 备份关键文件
    cp -r "$STATE_DIR/openclaw.json" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$STATE_DIR/agents" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$STATE_DIR/credentials" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$STATE_DIR/memory" "$BACKUP_DIR/" 2>/dev/null || true
    log_success "已备份到: $BACKUP_DIR"
fi

# 恢复文件
log_info ""
log_info "恢复文件..."

# openclaw.json
if [ -f "$SNAPSHOT_DIR/openclaw.json" ]; then
    cp "$SNAPSHOT_DIR/openclaw.json" "$STATE_DIR/"
    log_success "恢复: openclaw.json"
fi

# agents/
if [ -d "$SNAPSHOT_DIR/agents" ]; then
    mkdir -p "$STATE_DIR/agents"
    cp -r "$SNAPSHOT_DIR/agents/"* "$STATE_DIR/agents/" 2>/dev/null || true
    log_success "恢复: agents/"
fi

# credentials/
if [ -d "$SNAPSHOT_DIR/credentials" ]; then
    mkdir -p "$STATE_DIR/credentials"
    cp -r "$SNAPSHOT_DIR/credentials/"* "$STATE_DIR/credentials/" 2>/dev/null || true
    log_success "恢复: credentials/"
fi

# memory/
if [ -d "$SNAPSHOT_DIR/memory" ]; then
    mkdir -p "$STATE_DIR/memory"
    cp -r "$SNAPSHOT_DIR/memory/"* "$STATE_DIR/memory/" 2>/dev/null || true
    log_success "恢复: memory/"
fi

# cron/
if [ -d "$SNAPSHOT_DIR/cron" ]; then
    mkdir -p "$STATE_DIR/cron"
    cp -r "$SNAPSHOT_DIR/cron/"* "$STATE_DIR/cron/" 2>/dev/null || true
    log_success "恢复: cron/"
fi

log_info ""
log_success "恢复完成!"
log_info ""
log_warn "⚠️  请注意:"
echo "  1. 检查并填入脱敏的凭证信息"
echo "  2. 重启 OpenClaw: openclaw gateway restart"
echo "  3. 验证配置: openclaw status"
log_info ""
log_info "如需回滚，备份位于: $BACKUP_DIR"
