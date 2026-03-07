#!/bin/bash
#
# KimiClaw Push
# 推送快照到远程仓库
#

REPO="${1:-github.com/polegithub/shadowclaw}"
BRANCH="${2:-kimiclaw}"
SNAPSHOT_DIR="${3:-$(ls -td ${HOME}/.openclaw/snapshots/kimiclaw-* 2>/dev/null | head -1)}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ -z "$SNAPSHOT_DIR" ] || [ ! -d "$SNAPSHOT_DIR" ]; then
    log_error "未找到快照目录"
    exit 1
fi

log_info "KimiClaw Push"
log_info "============="
log_info "仓库: $REPO"
log_info "分支: $BRANCH"
log_info "快照: $SNAPSHOT_DIR"

# 创建临时工作目录
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

log_info ""
log_info "准备推送..."

# 复制快照到临时目录
rsync -av "$SNAPSHOT_DIR/" "$TEMP_DIR/" --exclude="*.tmp" --exclude=".git"

# 添加 README
cat > "$TEMP_DIR/README.md" << EOF
# KimiClaw Snapshot

自动生成的 OpenClaw 环境快照。

## 信息

- 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
- 版本: 3.0.0
- 来源: $(whoami)@$(hostname)

## 目录结构

\`\`\`
openclaw.json       - 主配置文件
agents/             - Agent 配置和会话
credentials/        - 凭证（已脱敏）
memory/             - 记忆文件
cron/               - 定时任务
\`\`\`

## 恢复

使用 [KimiClaw](https://github.com/polegithub/shadowclaw) 恢复：

\`\`\`bash
kimiclaw restore $SNAPSHOT_DIR
\`\`\`

## 注意

凭证信息已被脱敏，恢复后需手动填入真实值。
EOF

# 初始化 git
cd "$TEMP_DIR"
git init
git add -A
git commit -m "KimiClaw snapshot - $(date '+%Y-%m-%d %H:%M:%S')"

# 推送
log_info "推送到远程..."
if git remote add origin "https://${GITHUB_TOKEN}@${REPO}.git" 2>/dev/null || git remote set-url origin "https://${GITHUB_TOKEN}@${REPO}.git" 2>/dev/null; then
    git push -f origin "HEAD:${BRANCH}" && log_success "推送成功!"
else
    # 无 token 模式
    git remote add origin "https://${REPO}.git"
    log_warn "未配置 GITHUB_TOKEN，请手动推送:"
    log_info "cd $TEMP_DIR"
    log_info "git push origin HEAD:${BRANCH}"
    # 不删除 temp dir
    trap - EXIT
fi
