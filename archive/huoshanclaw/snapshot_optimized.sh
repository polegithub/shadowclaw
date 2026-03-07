#!/bin/bash
# huoshanclaw 优化版快照脚本（立即优化实现）
# 功能：支持脱敏、增量备份、自动同步

set -e

# 配置
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
SNAPSHOT_DIR="${SNAPSHOT_DIR:-$OPENCLAW_DIR/snapshots}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SNAPSHOT_NAME="huoshanclaw-snapshot-$TIMESTAMP"
OUTPUT_DIR="$SNAPSHOT_DIR/$SNAPSHOT_NAME"

# 敏感字段脱敏列表
SENSITIVE_PATTERNS=(
    "api_key" "apikey" "api-key" "token" "secret" "password"
    "private_key" "client_secret" "access_token" "refresh_token"
    "openai_api_key" "anthropic_api_key" "kimi_api_key"
    "feishu_app_secret" "github_token" "whatsapp_session"
)

# 必备文件列表（增量备份仅检查这些文件的变更）
REQUIRED_FILES=(
    "openclaw.json"
    "agents/main/agent/auth-profiles.json"
    "agents/main/sessions/sessions.json"
    "credentials/oauth.json"
    "memory/MEMORY.md"
    "memory/*.md"
    "workspace/*.md"
    "workspace/skills/**/*"
)

echo "[huoshanclaw] 开始优化版快照生成..."
mkdir -p "$OUTPUT_DIR"

# 1. 增量备份：只复制变更的文件
echo "[huoshanclaw] 1/4 执行增量备份，仅复制变更文件..."
for pattern in "${REQUIRED_FILES[@]}"; do
    find "$OPENCLAW_DIR" -path "$pattern" -type f -newermt "$(date -d '1 day ago' +%Y-%m-%d)" 2>/dev/null | while read -r file; do
        rel_path="${file#$OPENCLAW_DIR/}"
        dest_path="$OUTPUT_DIR/$rel_path"
        mkdir -p "$(dirname "$dest_path")"
        cp "$file" "$dest_path"
        echo "✅ 已备份: $rel_path"
    done
done

# 2. 自动脱敏
echo "[huoshanclaw] 2/4 执行敏感数据自动脱敏..."
find "$OUTPUT_DIR" -type f -name "*.json" -o -name "*.md" -o -name "*.sh" | while read -r file; do
    for pattern in "${SENSITIVE_PATTERNS[@]}"; do
        sed -i.bak -E "s/\"$pattern\"[[:space:]]*:[[:space:]]*\"[^\"]+\"/\"$pattern\": \"{{SECRET:$pattern}}\"/g" "$file" 2>/dev/null || true
        sed -i.bak -E "s/$pattern[[:space:]]*=[[:space:]]*[^\"]+/$pattern={{SECRET:$pattern}}/g" "$file" 2>/dev/null || true
    done
    rm -f "${file}.bak"
done
echo "✅ 敏感数据脱敏完成"

# 3. 生成清单文件
echo "[huoshanclaw] 3/4 生成快照清单..."
cat > "$OUTPUT_DIR/manifest.json" <<EOF
{
    "version": "1.0.0",
    "name": "huoshanclaw",
    "generated_at": "$(date -Iseconds)",
    "total_files": $(find "$OUTPUT_DIR" -type f | wc -l),
    "size_mb": $(du -sm "$OUTPUT_DIR" | cut -f1),
    "checksums": {
$(find "$OUTPUT_DIR" -type f | while read -r file; do
    rel_path="${file#$OUTPUT_DIR/}"
    echo "        \"$rel_path\": \"$(sha256sum "$file" | cut -d' ' -f1)\","
done | sed '$ s/,$//')
    }
}
EOF
echo "✅ 清单文件生成完成"

# 4. 压缩快照
echo "[huoshanclaw] 4/4 压缩快照..."
cd "$SNAPSHOT_DIR"
tar -czf "$SNAPSHOT_NAME.tar.gz" "$SNAPSHOT_NAME"
rm -rf "$SNAPSHOT_NAME"
FINAL_SIZE=$(du -h "$SNAPSHOT_NAME.tar.gz" | cut -f1)

echo ""
echo "🎉 [huoshanclaw] 优化版快照生成成功！"
echo "📁 快照文件: $SNAPSHOT_DIR/$SNAPSHOT_NAME.tar.gz"
echo "📦 快照大小: $FINAL_SIZE"
echo "🔒 已自动脱敏所有敏感字段"
echo "🔄 已启用增量备份，仅备份24小时内变更文件"

# 可选：自动推送到远程仓库（如果配置了GITHUB_TOKEN）
if [ -n "$GITHUB_TOKEN" ]; then
    echo ""
    echo "[huoshanclaw] 检测到GITHUB_TOKEN，自动推送到远程仓库..."
    git add "$SNAPSHOT_DIR/$SNAPSHOT_NAME.tar.gz"
    git commit -m "[huoshanclaw] auto: 自动快照备份 $TIMESTAMP"
    git push origin main
    echo "✅ 快照已自动同步到远程仓库"
fi
