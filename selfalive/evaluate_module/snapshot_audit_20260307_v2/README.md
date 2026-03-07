# Snapshot Audit v2 (Code-Review Diff View)

本目录是按用户要求重新生成的结构对比报告：
- 三个方案都在同一台机器上重新执行 1 次
- 与当前 OpenClaw 原始目录做文件级结构对比
- 使用 code-review 风格（红色缺失 / 绿色新增）
- DB 不做全文 diff，只做 size + header 对比

## 文件说明
- `STRUCTURE_DIFF_REPORT.md`：Markdown 报告（GitHub 可直接看 diff 风格）
- `STRUCTURE_DIFF_REPORT.html`：带红绿高亮的 HTML 报告
- `STRUCTURE_DIFF_REPORT.json`：机器可读原始结果
- `run.env`：三套方案执行状态与耗时
- `*_filelist.txt`：每套方案本次实际生成的文件清单
