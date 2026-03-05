#!/usr/bin/env python3
# 解析 OpenClaw 会话文件，计算真正的累计 token 使用量

import json
import os
import sys

# 查找会话文件
def find_latest_session():
    session_dir = os.path.expanduser("~/.openclaw/agents/main/sessions/")
    if not os.path.exists(session_dir):
        return None
    
    jsonl_files = []
    for f in os.listdir(session_dir):
        if f.endswith('.jsonl'):
            full_path = os.path.join(session_dir, f)
            jsonl_files.append((os.path.getmtime(full_path), full_path))
    
    if not jsonl_files:
        return None
    
    # 按修改时间排序，取最新的
    jsonl_files.sort(reverse=True, key=lambda x: x[0])
    return jsonl_files[0][1]

session_file = find_latest_session()

if not session_file:
    print("未找到会话文件")
    sys.exit(1)

print()
print("📊 OpenClaw Token 累计统计")
print("==========================")
print()
print("会话文件:", os.path.basename(session_file))
print()

total_input = 0
total_output = 0
total_cache_read = 0
total_cache_write = 0
total_tokens = 0
call_count = 0
usage_by_time = []

with open(session_file, 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            data = json.loads(line)
            if data.get('type') == 'message':
                msg = data.get('message', {})
                if msg.get('role') == 'assistant':
                    usage = msg.get('usage', {})
                    if usage:
                        inp = usage.get('input', 0)
                        out = usage.get('output', 0)
                        cr = usage.get('cacheRead', 0)
                        cw = usage.get('cacheWrite', 0)
                        tt = usage.get('totalTokens', 0)
                        
                        total_input += inp
                        total_output += out
                        total_cache_read += cr
                        total_cache_write += cw
                        total_tokens += tt
                        call_count += 1
                        
                        ts = data.get('timestamp', '')
                        usage_by_time.append((ts, inp, out, tt))
        except Exception as e:
            pass

print(f"📈 调用次数: {call_count}")
print()
print("📊 Token 使用量（累计）:")
print(f"  输入 Tokens:  {total_input:>10,}")
print(f"  输出 Tokens:  {total_output:>10,}")
print(f"  缓存读取:    {total_cache_read:>10,}")
print(f"  缓存写入:    {total_cache_write:>10,}")
print(f"  总计 Tokens:  {total_tokens:>10,}")
print()
print("💡 说明:")
print("  - session_status 只显示单次输出，不是累计的")
print("  - 这里是从会话文件解析的真实累计数据")

if usage_by_time:
    print()
    print("📜 最近 5 次调用:")
    for i, (ts, inp, out, tt) in enumerate(usage_by_time[-5:], 1):
        print(f"  {i}. 输入: {inp:>6,}  输出: {out:>5,}  总计: {tt:>7,}")
