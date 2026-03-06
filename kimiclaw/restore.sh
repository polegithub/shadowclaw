#!/bin/bash
# OpenClaw 恢复脚本
# 用法: ./restore.sh

echo "🔄 开始恢复 OpenClaw..."

# 1. 恢复配置
cp snapshot/openclaw-config.json ~/.openclaw/openclaw.json
echo "✅ 配置已恢复（请手动填入 secrets-template.json 中的敏感信息）"

# 2. 恢复 workspace 文件
cp -r memory/ ~/.openclaw/workspace/ 2>/dev/null || true
cp -r skills/ ~/.openclaw/workspace/ 2>/dev/null || true
cp *.md ~/.openclaw/workspace/ 2>/dev/null || true
echo "✅ 工作区文件已恢复"

# 3. 重启 gateway
openclaw gateway restart
echo "✅ Gateway 已重启"

echo "🎉 恢复完成！请检查配置并填入 API keys"
