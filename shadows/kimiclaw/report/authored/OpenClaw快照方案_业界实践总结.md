# OpenClaw 快照与恢复方案 - 业界实践总结

**调研日期**: 2026-03-08  
**调研范围**: 官方插件、社区方案、云厂商实践  

---

## 【官方/半官方方案】

### 1. openclaw-b2-backup 插件 ⭐推荐

**来源**: Backblaze 官方博客 (2026-03-06)  
**定位**: 官方认可的备份插件  

**核心特性**:
| 特性 | 说明 |
|------|------|
| 存储后端 | Backblaze B2 (S3兼容) |
| 加密 | 默认AES加密，客户端加密 |
| 触发方式 | 定时cron + gateway关闭前 + compaction前 |
| 恢复方式 | 聊天指令 `b2_rollback` 或新机器自动检测恢复 |
| 安全快照 | 恢复前自动创建当前状态的安全快照 |

**配置示例**:
```json
{
  "openclaw-b2-backup": {
    "enabled": true,
    "config": {
      "keyId": "004a...",
      "applicationKey": "K004...",
      "bucket": "my-openclaw-backups"
    }
  }
}
```

**新机器恢复流程**:
```bash
openclaw plugins install openclaw-b2-backup
# 配置相同B2凭证
openclaw gateway restart
# 插件检测空状态 + 存在快照 → 自动恢复最新版本
```

**评价**: 最成熟的商业级方案，但依赖Backblaze B2服务。

---

### 2. OpenClaw Operator (Kubernetes) ⭐企业级

**来源**: openclaw.rocks 官方博客 (2026-02-17)  
**定位**: K8s环境下的企业级方案  

**核心特性**:
- CRD定义: `OpenClawInstance` 资源描述完整实例
- GitOps支持: 与ArgoCD/Flux集成，配置版本化
- S3兼容备份: 自动备份workspace PVC
- 自动恢复: `spec.restoreFrom` 字段指定S3路径

**恢复示例**:
```yaml
apiVersion: openclaw.rocks/v1alpha1
kind: OpenClawInstance
metadata:
  name: my-agent-restored
spec:
  restoreFrom: "s3://bucket/path/to/backup.tar.gz"
  storage:
    persistence:
      enabled: true
      size: 10Gi
```

**适用场景**: 有K8s基础设施的企业用户。

---

## 【社区方案】

### 3. quick-backup-restore Skill ⭐轻量级

**来源**: Termo.ai 社区 (2026-03-05)  
**GitHub**: github.com/marzliak/quick-backup-restore  

**核心特性**:
| 特性 | 说明 |
|------|------|
| 引擎 | Restic (增量备份神器) |
| 频率 | 每小时自动快照 |
| 保留 | 72小时历史 |
| 通知 | Telegram错误告警 |
| 触发 | 手动 + cron自动 |

**使用方式**:
```bash
# 手动备份
sudo bash {baseDir}/bin/backup.sh

# 查看快照
restic -r /var/backups/quick-backup-restore snapshots

# 恢复指定快照
restic -r /var/backups/quick-backup-restore restore <snapshot-id> --target /
```

**评价**: 适合个人用户，Restic的增量备份效率极高。

---

### 4. Duplicati 跨平台备份

**来源**: LumaDock 教程 (2026-02-22)  
**定位**: 跨平台GUI工具  

**备份范围**:
- Linux/macOS: `~/.openclaw` + workspace
- Windows: `C:\Users\<User>\.openclaw` + workspace

**推荐保留策略**:
- 每日1份，保留7-14天
- 每周1份，保留4-8周
- 每月1份，保留3-6个月

**关键建议**: **一定要做恢复测试**，不要等灾难日才发现备份不可用。

---

### 5. 手动 tar 归档 (官方基础方案)

**来源**: OpenClaw 官方迁移文档  
**适用**: 一次性迁移或简单备份  

**备份**:
```bash
openclaw gateway stop
cd ~
tar -czf openclaw-state-$(date +%Y%m%d).tgz .openclaw
```

**恢复到新机器**:
```bash
# 新机器安装OpenClaw后
cd ~
tar -xzf openclaw-state-20260308.tgz
openclaw gateway start
openclaw doctor  # 验证配置
```

**注意事项**: 
- WhatsApp需要重新配对（session绑定设备状态）
- Telegram/Discord bot token可直接迁移

---

## 【云厂商方案】

### 6. 腾讯云 Lighthouse 快照

**来源**: 腾讯云官方技术文档 (2026-03-03)  
**定位**: 基础设施级备份  

**3-2-1原则**:
- 3份数据副本
- 2种不同介质
- 1份异地存储

**快照 + COS同步**:
```bash
# 同步到对象存储
coscli sync /backup/openclaw/ cos://your-bucket/openclaw-backups/ \
  --include "*.tar.gz" --include "*.sqlite"
```

**恢复流程**:
1. 创建新Lighthouse实例
2. 从快照恢复（5分钟）
3. 更新DNS/webhook URL
4. 测试所有channel连接

---

## 【方案对比】

| 方案 | 复杂度 | 自动化 | 成本 | 适用场景 |
|------|--------|--------|------|----------|
| openclaw-b2-backup | 低 | 高 | 免费(10GB内) | 个人/小团队 |
| K8s Operator | 高 | 高 | 运维成本 | 企业K8s环境 |
| quick-backup-restore | 低 | 中 | 免费 | 技术爱好者 |
| Duplicati | 低 | 中 | 免费 | 多平台用户 |
| 手动tar | 低 | 低 | 免费 | 一次性迁移 |
| 云快照 | 低 | 高 | 云厂商费用 | 云服务器用户 |

---

## 【关键建议】

1. **3-2-1备份原则**: 不管用什么方案，至少保留3份副本
2. **定期恢复演练**: 未经测试的备份 = 没有备份
3. **分离密钥与数据**: `openclaw.json` 含敏感信息，Git备份时需脱敏
4. ** compaction前快照**: 官方插件会在session压缩前自动备份，防止记忆丢失
5. **新机器注意**: WhatsApp需重新配对，其他channel通常直接可用

---

## 【与KimiClaw方案对比】

| 维度 | 业界方案 | KimiClaw自建 |
|------|----------|--------------|
| 存储后端 | B2/S3/本地 | GitHub私有仓库 |
| 增量备份 | 支持 | 支持(SHA256) |
| 自动触发 | 支持 | 需配置cron |
| 脱敏 | 部分支持 | 28+规则深度脱敏 |
| 恢复复杂度 | 一键/自动 | 需手动clone+restore |
| 跨机器恢复 | 支持 | 支持 |

**结论**: 业界方案更成熟，KimiClaw自建方案胜在深度脱敏和GitHub集成。
