# OpenClaw 记忆恢复方案测试方案
## 测试目标
验证记忆系统在会话重启、跨设备同步、数据损坏等场景下的恢复能力，确保记忆完整、一致、准确。
## 前置条件
1. OpenClaw 环境正常运行，记忆模块已启用
2. 有写入权限到 `memory/` 目录
3. 已安装 `coding-agent` 技能支持Git操作
## 测试用例（可直接执行）
### 测试用例1：基础记忆写入与读取验证
**执行步骤**：
```bash
# 1. 写入测试记忆
echo "测试记忆1: 2026-03-07 测试内容A" >> memory/2026-03-07.md
echo "测试记忆2: 用户偏好设置: 深色模式" >> MEMORY.md
# 2. 读取验证
grep "测试内容A" memory/2026-03-07.md
grep "深色模式" MEMORY.md
```
**预期结果**：两条命令都能匹配到对应内容，返回码为0。
### 测试用例2：会话重启后记忆恢复验证
**执行步骤**：
```bash
# 1. 重启前写入标记
echo "RESTART_TEST_MARKER: $(date +%s)" >> MEMORY.md
# 2. 模拟会话重启（重新加载记忆）
# 实际操作中为重启OpenClaw进程，此处用内存重载模拟
rm -f /tmp/openclaw_memory_cache/*
# 3. 重启后读取验证
grep "RESTART_TEST_MARKER" MEMORY.md
```
**预期结果**：能读取到重启前写入的时间标记，记忆未丢失。
### 测试用例3：跨设备同步一致性验证
**执行步骤**：
```bash
# 1. 本地写入同步标记
echo "SYNC_TEST: $(uuidgen)" >> memory/sync_test.md
# 2. 推送到远程仓库
git add memory/sync_test.md
git commit -m "test: add sync test marker"
git push origin main
# 3. 另一设备拉取验证（此处模拟拉取）
cd /tmp && git clone <仓库地址> test_sync && cd test_sync
grep "SYNC_TEST" memory/sync_test.md
```
**预期结果**：拉取后的文件包含相同的UUID标记，无差异。
### 测试用例4：部分文件损坏恢复验证
**执行步骤**：
```bash
# 1. 备份正常记忆
cp MEMORY.md /tmp/memory_backup.md
# 2. 模拟文件损坏
echo "CORRUPTED_DATA" > MEMORY.md
# 3. 执行记忆恢复操作
openclaw memory recover
# 4. 验证恢复结果
diff MEMORY.md /tmp/memory_backup.md
```
**预期结果**：diff无输出，文件恢复到损坏前状态。
### 测试用例5：历史记忆召回准确性验证
**执行步骤**：
```bash
# 1. 写入带关键词的测试记忆
echo "KEYWORD_TEST: 项目X的截止时间是2026-06-30" >> memory/2026-03-01.md
# 2. 语义搜索验证
openclaw memory search "项目X 截止时间"
```
**预期结果**：搜索结果返回包含"2026-06-30"的记忆片段，匹配度>90%。
## 评测指标
| 指标 | 合格标准 |
|------|----------|
| 记忆完整率 | 100%（写入的内容全部可读取） |
| 恢复成功率 | 100%（所有故障场景下都能恢复） |
| 召回准确率 | ≥95%（语义搜索返回正确结果的比例） |
| 恢复耗时 | <2s（常规场景下记忆加载时间） |
## 执行说明
1. 所有测试用例可直接在终端执行
2. 测试结果记录到 `selfalive/evaluate_module/test_results.md`
3. 未通过的用例需记录错误日志到对应issue
