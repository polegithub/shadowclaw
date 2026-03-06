#!/bin/bash
#
# CatClaw Snapshot Generator
# 基于 KimiClaw v3.0，融合 HuoshanClaw 覆盖范围
#

set -e

OUTPUT_DIR="${1:-./catclaw-snapshot}"
DRY_RUN=false

STATE_DIR="${HOME}/.openclaw"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
    OUTPUT_DIR="${2:-./catclaw-snapshot}"
fi

log_info "🐱 CatClaw Snapshot Generator v1.0"
log_info "==================================="
log_info "源目录: $STATE_DIR"
log_info "输出目录: $OUTPUT_DIR"

if [ "$DRY_RUN" = true ]; then
    log_warn "模拟运行模式"
fi

# 统计
total_files=0
copied_files=0
excluded_files=0
desensitized_files=0

# 复制文件函数
copy_file() {
    local src="$1"
    local dst="$2"
    local desc="$3"

    ((total_files++)) || true

    if [ ! -e "$src" ]; then
        log_warn "跳过（不存在）: $src"
        ((excluded_files++)) || true
        return
    fi

    # 文件大小检查（10MB 限制）
    if [ -f "$src" ]; then
        local size=$(stat -c%s "$src" 2>/dev/null || stat -f%z "$src" 2>/dev/null || echo 0)
        local size_mb=$((size / 1024 / 1024))

        if [ "$size_mb" -gt 10 ]; then
            log_warn "跳过（${size_mb}MB 超过限制）: $src"
            ((excluded_files++)) || true
            return
        fi
    fi

    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$(dirname "$dst")"

        if [ -d "$src" ]; then
            cp -r "$src" "$dst"
        else
            cp "$src" "$dst"
        fi
    fi

    log_success "$desc: $(basename "$src")"
    ((copied_files++)) || true
}

# 脱敏函数（增强版，覆盖更多字段）
desensitize_file() {
    local file="$1"
    if [ ! -f "$file" ]; then return; fi

    log_info "🔒 脱敏处理: $file"

    # JSON 文件中的敏感字段
    sed -i 's/"token": "[^"]*"/"token": "{{SECRET:token}}"/g' "$file" 2>/dev/null || true
    sed -i 's/"api_key": "[^"]*"/"api_key": "{{SECRET:api_key}}"/g' "$file" 2>/dev/null || true
    sed -i 's/"apiKey": "[^"]*"/"apiKey": "{{SECRET:apiKey}}"/g' "$file" 2>/dev/null || true
    sed -i 's/"secret": "[^"]*"/"secret": "{{SECRET:secret}}"/g' "$file" 2>/dev/null || true
    sed -i 's/"appSecret": "[^"]*"/"appSecret": "{{SECRET:appSecret}}"/g' "$file" 2>/dev/null || true
    sed -i 's/"password": "[^"]*"/"password": "{{SECRET:password}}"/g' "$file" 2>/dev/null || true
    sed -i 's/"private_key": "[^"]*"/"private_key": "{{SECRET:private_key}}"/g' "$file" 2>/dev/null || true
    sed -i 's/"client_secret": "[^"]*"/"client_secret": "{{SECRET:client_secret}}"/g' "$file" 2>/dev/null || true
    sed -i 's/"access_token": "[^"]*"/"access_token": "{{SECRET:access_token}}"/g' "$file" 2>/dev/null || true
    sed -i 's/"refresh_token": "[^"]*"/"refresh_token": "{{SECRET:refresh_token}}"/g' "$file" 2>/dev/null || true
    # sk- 开头的 key
    sed -i 's/"sk-[^"]*"/"{{SECRET:sk_key}}"/g' "$file" 2>/dev/null || true
    # kimiCodeAPIKey / kimiPluginAPIKey
    sed -i 's/"kimiCodeAPIKey": "[^"]*"/"kimiCodeAPIKey": "{{SECRET:kimiCodeAPIKey}}"/g' "$file" 2>/dev/null || true
    sed -i 's/"kimiPluginAPIKey": "[^"]*"/"kimiPluginAPIKey": "{{SECRET:kimiPluginAPIKey}}"/g' "$file" 2>/dev/null || true

    # .env 文件中的 KEY=value
    sed -i 's/\(API_KEY=\).*/\1{{SECRET:api_key}}/g' "$file" 2>/dev/null || true
    sed -i 's/\(SECRET=\).*/\1{{SECRET:secret}}/g' "$file" 2>/dev/null || true
    sed -i 's/\(TOKEN=\).*/\1{{SECRET:token}}/g' "$file" 2>/dev/null || true

    ((desensitized_files++)) || true
}

# ==========================================
# 开始备份
# ==========================================

if [ "$DRY_RUN" = false ]; then
    mkdir -p "$OUTPUT_DIR"
fi

# --- ⭐⭐⭐ 必备文件 ---
log_info ""
log_info "📦 备份 ⭐⭐⭐ 必备文件..."

copy_file "$STATE_DIR/openclaw.json" "$OUTPUT_DIR/openclaw.json" "⭐⭐⭐ 主配置"
copy_file "$STATE_DIR/agents/main/agent/auth-profiles.json" "$OUTPUT_DIR/agents/main/agent/auth-profiles.json" "⭐⭐⭐ API Keys"
copy_file "$STATE_DIR/agents/main/sessions/sessions.json" "$OUTPUT_DIR/agents/main/sessions/sessions.json" "⭐⭐⭐ 会话索引"
copy_file "$STATE_DIR/credentials/oauth.json" "$OUTPUT_DIR/credentials/oauth.json" "⭐⭐⭐ OAuth"

# WhatsApp 凭证
if [ -f "$STATE_DIR/credentials/whatsapp/default/creds.json" ]; then
    copy_file "$STATE_DIR/credentials/whatsapp/default/creds.json" "$OUTPUT_DIR/credentials/whatsapp/default/creds.json" "⭐⭐⭐ WhatsApp"
fi

# SQLite 记忆库（来自 huoshanclaw 方案）
copy_file "$STATE_DIR/memory/main.sqlite" "$OUTPUT_DIR/memory/main.sqlite" "⭐⭐⭐ SQLite 记忆"

# 向量记忆库
if [ -d "$STATE_DIR/memory/lancedb" ]; then
    copy_file "$STATE_DIR/memory/lancedb" "$OUTPUT_DIR/memory/lancedb" "⭐⭐⭐ 向量记忆"
fi

# Workspace 核心文件
for f in AGENTS.md SOUL.md USER.md IDENTITY.md MEMORY.md; do
    copy_file "$STATE_DIR/workspace/$f" "$OUTPUT_DIR/workspace/$f" "⭐⭐⭐ workspace/$f"
done

# Workspace 每日记忆（来自 huoshanclaw 方案）
if [ -d "$STATE_DIR/workspace/memory" ]; then
    mkdir -p "$OUTPUT_DIR/workspace/memory"
    for f in "$STATE_DIR/workspace/memory"/*.md; do
        if [ -f "$f" ]; then
            fname=$(basename "$f")
            copy_file "$f" "$OUTPUT_DIR/workspace/memory/$fname" "⭐⭐⭐ 每日记忆"
        fi
    done
fi

# --- ⭐⭐ 重要文件 ---
log_info ""
log_info "📦 备份 ⭐⭐ 重要文件..."

copy_file "$STATE_DIR/agents/main/agent/models.json" "$OUTPUT_DIR/agents/main/agent/models.json" "⭐⭐ 模型配置"
copy_file "$STATE_DIR/cron/jobs.json" "$OUTPUT_DIR/cron/jobs.json" "⭐⭐ 定时任务"
copy_file "$STATE_DIR/identity/device.json" "$OUTPUT_DIR/identity/device.json" "⭐⭐ 设备身份"

# .env（来自 huoshanclaw 方案）
copy_file "$STATE_DIR/.env" "$OUTPUT_DIR/.env" "⭐⭐ 环境变量"

# Workspace 辅助文件（来自 huoshanclaw 方案）
for f in TOOLS.md HEARTBEAT.md tasks.json; do
    copy_file "$STATE_DIR/workspace/$f" "$OUTPUT_DIR/workspace/$f" "⭐⭐ workspace/$f"
done

# 飞书配对信息（来自 huoshanclaw）
copy_file "$STATE_DIR/credentials/feishu-pairing.json" "$OUTPUT_DIR/credentials/feishu-pairing.json" "⭐⭐ 飞书配对"

# Skills
if [ -d "$STATE_DIR/workspace/skills" ]; then
    log_info "备份 Skills..."
    cp -r "$STATE_DIR/workspace/skills" "$OUTPUT_DIR/workspace/skills" 2>/dev/null || true
    log_success "⭐⭐ workspace/skills/"
fi

# 对话历史（jsonl）
if [ -d "$STATE_DIR/agents/main/sessions" ]; then
    for f in "$STATE_DIR/agents/main/sessions"/*.jsonl; do
        if [ -f "$f" ]; then
            local_size=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo 0)
            local_mb=$((local_size / 1024 / 1024))
            if [ "$local_mb" -le 50 ]; then
                fname=$(basename "$f")
                copy_file "$f" "$OUTPUT_DIR/agents/main/sessions/$fname" "⭐⭐ 对话历史"
            else
                log_warn "跳过对话历史（${local_mb}MB）: $f"
            fi
        fi
    done
fi

# ==========================================
# 脱敏处理
# ==========================================
log_info ""
log_info "🔒 脱敏处理..."

if [ "$DRY_RUN" = false ]; then
    # 对敏感文件执行脱敏
    desensitize_file "$OUTPUT_DIR/openclaw.json"
    desensitize_file "$OUTPUT_DIR/agents/main/agent/auth-profiles.json"
    desensitize_file "$OUTPUT_DIR/credentials/oauth.json"
    desensitize_file "$OUTPUT_DIR/credentials/whatsapp/default/creds.json"
    desensitize_file "$OUTPUT_DIR/credentials/feishu-pairing.json"
    desensitize_file "$OUTPUT_DIR/.env"
fi

# ==========================================
# 生成 manifest
# ==========================================
if [ "$DRY_RUN" = false ]; then
    log_info ""
    log_info "📋 生成 manifest..."

    cat > "${OUTPUT_DIR}/manifest.json" << EOF
{
  "version": "1.0.0",
  "name": "catclaw",
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "generated_by": "$(whoami)@$(hostname)",
  "state_dir": "${STATE_DIR}",
  "based_on": "kimiclaw-v3.0 + huoshanclaw-v2.0",
  "stats": {
    "total_files": ${total_files},
    "copied_files": ${copied_files},
    "excluded_files": ${excluded_files},
    "desensitized_files": ${desensitized_files}
  }
}
EOF
    log_success "manifest.json 已生成"
fi

# ==========================================
# 生成 secrets-template
# ==========================================
if [ "$DRY_RUN" = false ]; then
    cat > "${OUTPUT_DIR}/secrets-template.json" << 'EOF'
{
  "说明": "恢复快照后，请将以下占位符替换为真实值",
  "openclaw.json": {
    "env.*_API_KEY": "你的 API Key",
    "models.providers.*.apiKey": "模型 API Key",
    "channels.*.appSecret": "渠道 App Secret",
    "gateway.auth.token": "Gateway 认证 Token",
    "plugins.*.config.*.token": "插件 Token"
  },
  ".env": {
    "*_KEY, *_SECRET, *_TOKEN": "环境变量中的敏感值"
  },
  "credentials/": {
    "oauth.json": "OAuth Token",
    "whatsapp/default/creds.json": "WhatsApp 登录态"
  }
}
EOF
    log_success "secrets-template.json 已生成"
fi

# ==========================================
# 完成
# ==========================================
log_info ""
log_info "==================================="
log_success "🐱 CatClaw 快照生成完成!"
log_info "输出目录: $OUTPUT_DIR"
log_info "已复制: $copied_files 个文件"
log_info "已排除: $excluded_files 个文件"
log_info "已脱敏: $desensitized_files 个文件"
log_info ""
log_warn "⚠️  请检查快照内容，确保无敏感信息泄漏"
