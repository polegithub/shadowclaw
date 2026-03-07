#!/bin/bash
#
# CatClaw Push
# 推送快照到远程 Git 仓库
#

set -e

REPO="${1:-github.com/polegithub/shadowclaw}"
BRANCH="${2:-catclaw}"
SNAPSHOT_DIR="${3:-./catclaw-snapshot}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ ! -d "$SNAPSHOT_DIR" ]; then
    log_error "快照目录不存在: $SNAPSHOT_DIR"
    log_info "请先运行 snapshot.sh 生成快照"
    exit 1
fi

log_info "🐱 CatClaw Push v1.0"
log_info "====================="
log_info "仓库: $REPO"
log_info "分支: $BRANCH"
log_info "快照: $SNAPSHOT_DIR"

# 安全检查：确认无明文密钥
log_info ""
log_info "🔒 安全检查..."

LEAKED=0
for f in $(find "$SNAPSHOT_DIR" -name "*.json" -o -name ".env"); do
    if grep -qE '"sk-[a-zA-Z0-9]+"' "$f" 2>/dev/null; then
        log_error "发现未脱敏的密钥: $f"
        LEAKED=1
    fi
done

if [ $LEAKED -eq 1 ]; then
    log_error "❌ 快照中存在明文密钥，推送已中止！"
    log_info "请重新运行 snapshot.sh 确保脱敏完成"
    exit 1
fi

log_success "安全检查通过，无明文密钥"

# 创建临时目录
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

log_info ""
log_info "📤 准备推送..."

rsync -av "$SNAPSHOT_DIR/" "$TEMP_DIR/" --exclude="*.tmp" --exclude=".git"

# 生成 README
cat > "$TEMP_DIR/README.md" << EOF
# CatClaw Snapshot 🐱

由 16的书包 自动生成的 OpenClaw 环境快照。

## 信息

- 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
- 方案版本: CatClaw v1.0
- 基于: KimiClaw v3.0 + HuoshanClaw v2.0

## 恢复

\`\`\`bash
bash catclaw/lib/restore.sh <snapshot-dir>
\`\`\`

## 注意

凭证信息已脱敏，恢复后需根据 \`secrets-template.json\` 手动填入真实值。
EOF

cd "$TEMP_DIR"
git init
git add -A
git commit -m "【catclaw花椒】CatClaw snapshot - $(date '+%Y-%m-%d %H:%M:%S')"

# 推送
TOKEN="${GH_TOKEN:-$GITHUB_TOKEN}"
if [ -n "$TOKEN" ]; then
    git remote add origin "https://x-access-token:${TOKEN}@${REPO}.git"
    git push -f origin "HEAD:${BRANCH}" && log_success "✅ 推送成功!"
else
    log_warn "未配置 GH_TOKEN，请手动推送:"
    log_info "cd $TEMP_DIR && git push origin HEAD:${BRANCH}"
    trap - EXIT
fi
