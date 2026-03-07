#!/bin/bash
# huoshanclaw 优化版恢复脚本（立即优化实现）
# 功能：一键恢复、自动备份当前状态、错误回滚

set -e

if [ $# -lt 1 ]; then
    echo "用法: $0 <快照文件路径>"
    exit 1
fi

SNAPSHOT_FILE="$1"
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
BACKUP_DIR="$OPENCLAW_DIR/backup-$(date +%Y%m%d-%H%M%S)"

echo "[huoshanclaw] 开始优化版恢复流程..."

# 1. 自动备份当前状态
echo "[huoshanclaw] 1/5 自动备份当前状态到 $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"
cp -r "$OPENCLAW_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
echo "✅ 当前状态备份完成"

# 2. 解压快照
echo "[huoshanclaw] 2/5 解压快照文件..."
TEMP_DIR=$(mktemp -d)
tar -xzf "$SNAPSHOT_FILE" -C "$TEMP_DIR"
SNAPSHOT_CONTENT=$(find "$TEMP_DIR" -maxdepth 1 -type d | tail -n1)
echo "✅ 快照解压完成"

# 3. 校验快照完整性
echo "[huoshanclaw] 3/5 校验快照完整性..."
MANIFEST_FILE="$SNAPSHOT_CONTENT/manifest.json"
if [ ! -f "$MANIFEST_FILE" ]; then
    echo "❌ 错误：快照缺少manifest.json文件，恢复中止"
    exit 1
fi

# 校验文件哈希
jq -r '.checksums | to_entries[] | "\(.key) \(.value)"' "$MANIFEST_FILE" | while read -r path expected_hash; do
    actual_hash=$(sha256sum "$SNAPSHOT_CONTENT/$path" 2>/dev/null | cut -d' ' -f1)
    if [ "$actual_hash" != "$expected_hash" ]; then
        echo "❌ 错误：文件 $path 校验失败，可能已损坏"
        echo "🔄 自动回滚到备份状态..."
        cp -r "$BACKUP_DIR"/* "$OPENCLAW_DIR/"
        rm -rf "$TEMP_DIR" "$BACKUP_DIR"
        exit 1
    fi
done
echo "✅ 快照完整性校验通过"

# 4. 恢复文件
echo "[huoshanclaw] 4/5 恢复文件到 $OPENCLAW_DIR..."
cp -r "$SNAPSHOT_CONTENT"/* "$OPENCLAW_DIR/"
echo "✅ 文件恢复完成"

# 5. 验证恢复结果
echo "[huoshanclaw] 5/5 验证恢复结果..."
# 检查核心文件是否存在
REQUIRED_FILES=(
    "openclaw.json"
    "agents/main/agent/auth-profiles.json"
    "agents/main/sessions/sessions.json"
)
all_exist=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$OPENCLAW_DIR/$file" ]; then
        echo "⚠️  警告：核心文件 $file 未找到"
        all_exist=false
    fi
done

if [ "$all_exist" = true ]; then
    echo "✅ 所有核心文件恢复成功"
else
    echo "⚠️  部分核心文件缺失，请手动检查"
fi

# 清理临时文件
rm -rf "$TEMP_DIR"
echo ""
echo "🎉 [huoshanclaw] 恢复完成！"
echo "📋 恢复前的状态已备份到: $BACKUP_DIR"
echo "🔑 请手动填入敏感字段（已脱敏为{{SECRET:xxx}}占位符）"
echo "🔄 建议重启OpenClaw服务使配置生效"
