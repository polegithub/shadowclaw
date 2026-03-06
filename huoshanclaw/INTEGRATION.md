# HuoshanClaw 整合说明

**版本：** v1.0  
**创建日期：** 2026-03-06  
**说明：** 整合其他有用的 snapshot 相关 skills

---

## 📋 已整合的内容

### 1. openclaw-sync - 智能快照同步
**来源：** `workspace-skills/openclaw-sync/`  
**整合内容：**
- ✅ Git 版本管理原则
- ✅ 智能过滤建议
- ✅ 元数据记录方案
- ✅ 恢复流程说明

### 2. file-size-checker - 文件大小检测
**来源：** `workspace-skills/file-size-checker/`  
**整合内容：**
- ✅ 大文件检测阈值建议
- ✅ 白名单/黑名单配置
- ✅ 快照前检查清单

### 3. token-tracker - Token 统计
**来源：** `workspace-skills/token-tracker/`  
**整合内容：**
- ✅ 可选的扩展功能说明
- ✅ 不作为快照必备项

---

## 🎯 整合原则

### 保留在 huoshanclaw 中的（快照必备）
- 完整的目录结构示例
- 文件优先级说明（⭐⭐⭐ 必备 / ⭐⭐ 重要 / ⭐ 可选）
- 基本快照创建和恢复流程

### 作为可选扩展的（放在 INTEGRATION.md）
- openclaw-sync 的 Git 同步功能
- file-size-checker 的大文件检测
- token-tracker 的使用量统计

---

## 📊 文件大小建议

### 快照过滤阈值（参考 file-size-checker）
| 文件类型 | 建议阈值 | 处理方式 |
|---------|----------|---------|
| `node_modules/` | 任何大小 | ❌ 跳过（可重新安装） |
| `extensions/*/node_modules/` | 任何大小 | ❌ 跳过 |
| `logs/*.log` | > 10MB | ⚠️ 可选备份 |
| `agents/*/sessions/*.jsonl` | > 50MB | ⚠️ 可选备份 |
| `snapshots/*.tar.gz` | 任何大小 | ❌ 跳过（快照本身） |

### 白名单（始终备份）
- `openclaw.json`
- `agents/*/agent/auth-profiles.json`
- `agents/*/sessions/sessions.json`
- `credentials/*.json`

---

## 🔄 Git 同步流程（参考 openclaw-sync）

### 创建快照并提交
```bash
cd ~/.openclaw/workspace/huoshanclaw
# 更新文件
git add .
git commit -m "更新快照：$(date +%Y-%m-%d)"
git push origin huoshanclaw
```

### 从快照恢复
```bash
# 在新机器上
git clone <repo_url> ~/.openclaw-sync
cd ~/.openclaw-sync
# 复制对应文件到 ~/.openclaw/
```

---

## 📈 Token 统计（可选扩展）

如果需要统计 token 使用量，可以：
1. 启用 `token-tracker` Skill
2. 定期记录到 `huoshanclaw/USAGE.md`（可选）
3. **不纳入快照必备内容**

---

*最后更新：2026-03-06*
