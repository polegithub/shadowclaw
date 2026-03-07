#!/usr/bin/env node
/**
 * OpenClaw 每日资讯收集脚本
 * 功能：
 * 1. 搜索 OpenClaw 相关新闻和技术分享
 * 2. 去重、筛选高质量内容
 * 3. 生成结构化表格
 */

const fs = require('fs');
const path = require('path');

// 存储文件路径
const DATA_DIR = path.join(__dirname, '..', 'data');
const HISTORY_FILE = path.join(DATA_DIR, 'news_history.json');
const OUTPUT_FILE = path.join(DATA_DIR, 'daily_news.md');

// 确保数据目录存在
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

// 加载历史记录（用于去重）
function loadHistory() {
  if (fs.existsSync(HISTORY_FILE)) {
    return JSON.parse(fs.readFileSync(HISTORY_FILE, 'utf8'));
  }
  return { urls: [], lastUpdate: null };
}

// 保存历史记录
function saveHistory(history) {
  fs.writeFileSync(HISTORY_FILE, JSON.stringify(history, null, 2));
}

// 评估内容质量（简单规则）
function evaluateQuality(item) {
  let score = 50; // 基础分
  
  // 来源权重
  const highQualitySources = ['github.com', 'csdn.net', 'zhihu.com', 'juejin.cn', 'blog.csdn.net'];
  const mediumQualitySources = ['36kr.com', 'nbd.com.cn', 'sina.com', 'ifanr.com'];
  
  if (highQualitySources.some(s => item.url?.includes(s))) score += 20;
  else if (mediumQualitySources.some(s => item.url?.includes(s))) score += 10;
  
  // 标题关键词权重
  const techKeywords = ['技术', '教程', '指南', '架构', '源码', '部署', '配置', '开发', 'API'];
  const newsKeywords = ['发布', '更新', '推出', '实测', '评测'];
  
  const title = item.title || '';
  if (techKeywords.some(k => title.includes(k))) score += 15;
  if (newsKeywords.some(k => title.includes(k))) score += 10;
  
  // 内容长度
  const summary = item.summary || '';
  if (summary.length > 200) score += 10;
  else if (summary.length < 50) score -= 10;
  
  // 去重惩罚
  if (item.isDuplicate) score -= 30;
  
  return Math.min(100, Math.max(0, score));
}

// 生成质量标签
function getQualityLabel(score) {
  if (score >= 80) return '🟢 高';
  if (score >= 60) return '🟡 中';
  return '🔴 低';
}

// 生成 Markdown 表格
function generateMarkdownTable(newsList, date) {
  const dateStr = date.toISOString().split('T')[0];
  
  let markdown = `# 📰 OpenClaw 每日资讯 - ${dateStr}\n\n`;
  markdown += `> 共收集 ${newsList.length} 条资讯 | 生成时间: ${date.toLocaleString('zh-CN')}\n\n`;
  
  if (newsList.length === 0) {
    markdown += '今日暂无新资讯。\n';
    return markdown;
  }
  
  // 表格头部
  markdown += '| 质量 | 标题 | 来源 | 摘要 |\n';
  markdown += '|------|------|------|------|\n';
  
  // 按质量排序
  const sortedNews = newsList.sort((a, b) => b.qualityScore - a.qualityScore);
  
  for (const item of sortedNews) {
    const quality = getQualityLabel(item.qualityScore);
    const title = item.title?.replace(/\|/g, '｜') || '无标题';
    const source = new URL(item.url).hostname.replace(/^www\./, '');
    const summary = (item.summary || '').substring(0, 80).replace(/\|/g, '｜') + '...';
    
    markdown += `| ${quality} | [${title}](${item.url}) | ${source} | ${summary} |\n`;
  }
  
  // 添加统计
  const highQuality = newsList.filter(n => n.qualityScore >= 80).length;
  const mediumQuality = newsList.filter(n => n.qualityScore >= 60 && n.qualityScore < 80).length;
  const lowQuality = newsList.filter(n => n.qualityScore < 60).length;
  
  markdown += `\n---\n\n`;
  markdown += `**统计**: 🟢 高质量 ${highQuality} 条 | 🟡 中质量 ${mediumQuality} 条 | 🔴 低质量 ${lowQuality} 条\n\n`;
  markdown += `**说明**: 质量评分基于来源权威性、内容完整度、技术深度等维度自动计算。\n`;
  
  return markdown;
}

// 主函数
async function main() {
  console.log('📰 OpenClaw 每日资讯收集器启动...\n');
  
  const now = new Date();
  const history = loadHistory();
  
  // 这里会调用 kimi_search 进行搜索
  // 实际执行时由外部调用 search 工具获取数据
  
  console.log('✅ 脚本已准备就绪');
  console.log('数据目录:', DATA_DIR);
  console.log('历史记录:', history.urls.length, '条');
}

main().catch(console.error);
