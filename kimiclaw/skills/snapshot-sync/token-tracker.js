#!/usr/bin/env node
/**
 * Token Tracker - OpenClaw Token 消耗追踪器
 * 
 * 功能：
 * - 实时记录每次 API 调用的 token 消耗
 * - 累计统计（按小时/天/周/月）
 * - 与快照系统集成，自动备份到 GitHub
 */

const fs = require('fs').promises;
const path = require('path');
const { execSync } = require('child_process');

const CONFIG = {
  dataDir: path.join(process.env.HOME, '.openclaw', 'token-tracker'),
  logFile: 'token-log.jsonl',
  summaryFile: 'token-summary.json',
  maxLogSizeMB: 50
};

// 确保目录存在
async function ensureDir() {
  await fs.mkdir(CONFIG.dataDir, { recursive: true });
}

/**
 * 记录一次 token 消耗
 * @param {Object} usage - { input, output, total, model, provider, timestamp }
 */
async function recordUsage(usage) {
  await ensureDir();
  
  const entry = {
    timestamp: usage.timestamp || new Date().toISOString(),
    inputTokens: usage.input || 0,
    outputTokens: usage.output || 0,
    totalTokens: usage.total || (usage.input + usage.output),
    model: usage.model || 'unknown',
    provider: usage.provider || 'unknown',
    sessionKey: usage.sessionKey || 'unknown'
  };
  
  // 追加到日志文件
  const logPath = path.join(CONFIG.dataDir, CONFIG.logFile);
  await fs.appendFile(logPath, JSON.stringify(entry) + '\n');
  
  // 更新汇总统计
  await updateSummary(entry);
  
  return entry;
}

/**
 * 更新汇总统计
 */
async function updateSummary(entry) {
  const summaryPath = path.join(CONFIG.dataDir, CONFIG.summaryFile);
  
  let summary = {
    totalInput: 0,
    totalOutput: 0,
    totalTokens: 0,
    callCount: 0,
    firstCall: null,
    lastCall: null,
    byModel: {},
    byDay: {}
  };
  
  try {
    const existing = await fs.readFile(summaryPath, 'utf8');
    summary = JSON.parse(existing);
  } catch {}
  
  // 更新总计
  summary.totalInput += entry.inputTokens;
  summary.totalOutput += entry.outputTokens;
  summary.totalTokens += entry.totalTokens;
  summary.callCount += 1;
  
  if (!summary.firstCall) summary.firstCall = entry.timestamp;
  summary.lastCall = entry.timestamp;
  
  // 按模型统计
  const model = entry.model || 'unknown';
  if (!summary.byModel[model]) {
    summary.byModel[model] = { input: 0, output: 0, total: 0, calls: 0 };
  }
  summary.byModel[model].input += entry.inputTokens;
  summary.byModel[model].output += entry.outputTokens;
  summary.byModel[model].total += entry.totalTokens;
  summary.byModel[model].calls += 1;
  
  // 按天统计
  const day = entry.timestamp.slice(0, 10); // YYYY-MM-DD
  if (!summary.byDay[day]) {
    summary.byDay[day] = { input: 0, output: 0, total: 0, calls: 0 };
  }
  summary.byDay[day].input += entry.inputTokens;
  summary.byDay[day].output += entry.outputTokens;
  summary.byDay[day].total += entry.totalTokens;
  summary.byDay[day].calls += 1;
  
  await fs.writeFile(summaryPath, JSON.stringify(summary, null, 2));
}

/**
 * 获取统计报告
 */
async function getReport(options = {}) {
  const { days = 7, model = null } = options;
  
  await ensureDir();
  const summaryPath = path.join(CONFIG.dataDir, CONFIG.summaryFile);
  
  try {
    const data = await fs.readFile(summaryPath, 'utf8');
    const summary = JSON.parse(data);
    
    // 计算指定天数的统计
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);
    const cutoffStr = cutoffDate.toISOString().slice(0, 10);
    
    let recentInput = 0;
    let recentOutput = 0;
    let recentTotal = 0;
    let recentCalls = 0;
    
    for (const [day, stats] of Object.entries(summary.byDay)) {
      if (day >= cutoffStr) {
        recentInput += stats.input;
        recentOutput += stats.output;
        recentTotal += stats.total;
        recentCalls += stats.calls;
      }
    }
    
    return {
      period: `${days} days`,
      totalLifetime: {
        input: summary.totalInput,
        output: summary.totalOutput,
        tokens: summary.totalTokens,
        calls: summary.callCount
      },
      recent: {
        input: recentInput,
        output: recentOutput,
        tokens: recentTotal,
        calls: recentCalls
      },
      byModel: summary.byModel,
      dailyBreakdown: Object.entries(summary.byDay)
        .filter(([day]) => day >= cutoffStr)
        .sort(([a], [b]) => a.localeCompare(b))
    };
  } catch (err) {
    return { error: 'No data yet', message: err.message };
  }
}

/**
 * 导出数据到快照目录
 */
async function exportForSnapshot(snapshotDir) {
  await ensureDir();
  
  const targetDir = path.join(snapshotDir, 'token-tracker');
  await fs.mkdir(targetDir, { recursive: true });
  
  // 复制数据文件
  const files = [CONFIG.logFile, CONFIG.summaryFile];
  for (const file of files) {
    const src = path.join(CONFIG.dataDir, file);
    const dest = path.join(targetDir, file);
    try {
      await fs.copyFile(src, dest);
    } catch {}
  }
  
  // 生成报告
  const report = await getReport({ days: 30 });
  await fs.writeFile(
    path.join(targetDir, 'report.json'),
    JSON.stringify(report, null, 2)
  );
  
  return targetDir;
}

/**
 * 从快照导入数据
 */
async function importFromSnapshot(snapshotDir) {
  const sourceDir = path.join(snapshotDir, 'token-tracker');
  
  try {
    await fs.access(sourceDir);
  } catch {
    console.log('No token-tracker data in snapshot');
    return false;
  }
  
  await ensureDir();
  
  const files = [CONFIG.logFile, CONFIG.summaryFile];
  for (const file of files) {
    const src = path.join(sourceDir, file);
    const dest = path.join(CONFIG.dataDir, file);
    try {
      await fs.copyFile(src, dest);
    } catch {}
  }
  
  console.log('Token tracker data restored from snapshot');
  return true;
}

/**
 * 显示当前统计（命令行用）
 */
async function displayStats() {
  const report = await getReport({ days: 1 });
  
  if (report.error) {
    console.log('暂无 token 数据');
    return;
  }
  
  console.log('\n📊 Token 消耗统计 (最近 24 小时)');
  console.log('=====================================');
  console.log(`输入 Tokens:  ${report.recent.input.toLocaleString()}`);
  console.log(`输出 Tokens:  ${report.recent.output.toLocaleString()}`);
  console.log(`总计 Tokens:  ${report.recent.tokens.toLocaleString()}`);
  console.log(`API 调用次数: ${report.recent.calls.toLocaleString()}`);
  console.log('=====================================\n');
  
  console.log('📈 累计消耗 (全部时间)');
  console.log(`输入:  ${report.totalLifetime.input.toLocaleString()}`);
  console.log(`输出:  ${report.totalLifetime.output.toLocaleString()}`);
  console.log(`总计:  ${report.totalLifetime.tokens.toLocaleString()}`);
  console.log(`调用: ${report.totalLifetime.calls.toLocaleString()}`);
}

// 命令行处理
async function main() {
  const command = process.argv[2];
  
  switch (command) {
    case 'record':
      // 从标准输入读取 JSON 数据
      let data = '';
      process.stdin.on('data', chunk => data += chunk);
      process.stdin.on('end', async () => {
        try {
          const usage = JSON.parse(data);
          await recordUsage(usage);
          console.log('✅ Token 记录已保存');
        } catch (err) {
          console.error('❌ 记录失败:', err.message);
          process.exit(1);
        }
      });
      break;
      
    case 'report':
      const days = parseInt(process.argv[3]) || 7;
      const report = await getReport({ days });
      console.log(JSON.stringify(report, null, 2));
      break;
      
    case 'stats':
      await displayStats();
      break;
      
    case 'export':
      const snapshotDir = process.argv[3];
      if (!snapshotDir) {
        console.error('请提供快照目录路径');
        process.exit(1);
      }
      await exportForSnapshot(snapshotDir);
      console.log('✅ Token 数据已导出到快照');
      break;
      
    case 'import':
      const importDir = process.argv[3];
      if (!importDir) {
        console.error('请提供快照目录路径');
        process.exit(1);
      }
      await importFromSnapshot(importDir);
      break;
      
    default:
      console.log(`
Token Tracker - OpenClaw Token 消耗追踪器

Usage:
  token-tracker record          从 stdin 读取并记录 token 数据
  token-tracker report [days]   生成统计报告 (默认7天)
  token-tracker stats           显示当前统计
  token-tracker export <dir>    导出到快照目录
  token-tracker import <dir>    从快照目录导入

示例:
  echo '{"input": 100, "output": 50, "model": "kimi-k2p5"}' | token-tracker record
  token-tracker report 30
      `);
  }
}

if (require.main === module) {
  main().catch(err => {
    console.error(err);
    process.exit(1);
  });
}

module.exports = {
  recordUsage,
  getReport,
  exportForSnapshot,
  importFromSnapshot
};