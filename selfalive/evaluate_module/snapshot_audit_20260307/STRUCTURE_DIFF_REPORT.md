# OpenClaw Snapshot Structure Diff Report

- Generated: `2026-03-07T21:37:43`
- State root: `/root/.openclaw`
- Snapshot audit dir: `/tmp/snapshot_audit_20260307-213622`
- Rule: compare **file-level relative paths** against OpenClaw stateful tree (runtime noise excluded)
- DB files: compare by **size + DB header** only (not full text diff)

## Summary

| Scheme | State Files | Snapshot Files | Matched | Missing from Snapshot | Extra in Snapshot | Changed |
|---|---:|---:|---:|---:|---:|---:|
| catpawclaw | 193 | 91 | 89 | 104 | 2 | 8 |
| kimiclaw | 193 | 13 | 12 | 181 | 1 | 1 |
| huoshanclaw | 193 | 22 | 10 | 183 | 12 | 1 |

## catpawclaw

### Top missing files (red, up to 80)
```diff
- .init-done.lock
- .ssh/config
- .ssh/id_ed25519_github
- .ssh/id_ed25519_github.pub
- .ssh/known_hosts
- agents/main/sessions/5fe72f1c-94a9-4b89-a274-61774506ecd6.jsonl.lock
- agents/main/sessions/sessions.json.bak
- cron/jobs.json.bak
- openclaw.json.bak
- openclaw.json.bak.1
- openclaw.json.bak.2
- openclaw.json.bak.20260307001035
- openclaw.json.bak.20260307002241
- openclaw.json.bak.3
- openclaw.json.bak.groupfix
- workspace/.openclaw/workspace-state.json
- workspace/shadowclaw/%1
- workspace/shadowclaw/.clawhub/lock.json
- workspace/shadowclaw/.gitignore
- workspace/shadowclaw/KIMICLAW-SENSITIVE-CHECKLIST.md
- workspace/shadowclaw/README.md
- workspace/shadowclaw/catclaw/README.md
- workspace/shadowclaw/catclaw/bin/shadowclaw
- workspace/shadowclaw/catclaw/config/paths.json
- workspace/shadowclaw/catclaw/docs/design.md
- workspace/shadowclaw/catclaw/skills/feishu-quote-debug/SKILL.md
- workspace/shadowclaw/huoshanclaw/.env
- workspace/shadowclaw/huoshanclaw/DESIGN.md
- workspace/shadowclaw/huoshanclaw/INTEGRATION.md
- workspace/shadowclaw/huoshanclaw/README.md
- workspace/shadowclaw/huoshanclaw/SCORE_CERTIFICATION.md
- workspace/shadowclaw/huoshanclaw/agents/main/agent/auth-profiles.json
- workspace/shadowclaw/huoshanclaw/agents/main/agent/models.json
- workspace/shadowclaw/huoshanclaw/agents/main/sessions/example.jsonl
- workspace/shadowclaw/huoshanclaw/agents/main/sessions/sessions.json
- workspace/shadowclaw/huoshanclaw/config/paths.json
- workspace/shadowclaw/huoshanclaw/config/settings.json
- workspace/shadowclaw/huoshanclaw/credentials/feishu-pairing.json
- workspace/shadowclaw/huoshanclaw/credentials/oauth.json
- workspace/shadowclaw/huoshanclaw/credentials/whatsapp/default/creds.json
- workspace/shadowclaw/huoshanclaw/credentials/whatsapp/default/creds.json.bak
- workspace/shadowclaw/huoshanclaw/cron/jobs.json
- workspace/shadowclaw/huoshanclaw/huoshanclaw.md
- workspace/shadowclaw/huoshanclaw/huoshanclaw_super_v1.sh
- workspace/shadowclaw/huoshanclaw/identity/device.json
- workspace/shadowclaw/huoshanclaw/memory/lancedb/README.md
- workspace/shadowclaw/huoshanclaw/memory/main.sqlite
- workspace/shadowclaw/huoshanclaw/openclaw.json
- workspace/shadowclaw/huoshanclaw/optimization_full_score.md
- workspace/shadowclaw/huoshanclaw/optimization_plan.md
- workspace/shadowclaw/huoshanclaw/restore_optimized.sh
- workspace/shadowclaw/huoshanclaw/skills/git-ssh-auth-config.md
- workspace/shadowclaw/huoshanclaw/snapshot.sh
- workspace/shadowclaw/huoshanclaw/snapshot/AGENTS.md
- workspace/shadowclaw/huoshanclaw/snapshot/HEARTBEAT.md
- workspace/shadowclaw/huoshanclaw/snapshot/IDENTITY.md
- workspace/shadowclaw/huoshanclaw/snapshot/README.md
- workspace/shadowclaw/huoshanclaw/snapshot/SOUL.md
- workspace/shadowclaw/huoshanclaw/snapshot/TOOLS.md
- workspace/shadowclaw/huoshanclaw/snapshot/USER.md
- workspace/shadowclaw/huoshanclaw/snapshot/feishu-pairing.json
- workspace/shadowclaw/huoshanclaw/snapshot/main.sqlite
- workspace/shadowclaw/huoshanclaw/snapshot/models.json
- workspace/shadowclaw/huoshanclaw/snapshot/openclaw.json
- workspace/shadowclaw/huoshanclaw/snapshot/sessions.json
- workspace/shadowclaw/huoshanclaw/snapshot_optimized.sh
- workspace/shadowclaw/huoshanclaw/workspace/AGENTS.md
- workspace/shadowclaw/huoshanclaw/workspace/HEARTBEAT.md
- workspace/shadowclaw/huoshanclaw/workspace/IDENTITY.md
- workspace/shadowclaw/huoshanclaw/workspace/SOUL.md
- workspace/shadowclaw/huoshanclaw/workspace/TOOLS.md
- workspace/shadowclaw/huoshanclaw/workspace/USER.md
- workspace/shadowclaw/huoshanclaw/workspace/memory/2026-03-06.md
- workspace/shadowclaw/huoshanclaw/workspace/tasks.json
- workspace/shadowclaw/kimiclaw/README.md
- workspace/shadowclaw/kimiclaw/bin/kimiclaw
- workspace/shadowclaw/kimiclaw/config/default.json
- workspace/shadowclaw/kimiclaw/docs/DESIGN.md
- workspace/shadowclaw/kimiclaw/kimiclaw.md
- workspace/shadowclaw/kimiclaw/snapshots/snapshot-20260307-173342/openclaw.json
- ... (24 more)
```

### Top extra files (green, up to 80)
```diff
+ manifest.json
+ secrets-template.json
```

### Top changed files (content/size/header, up to 40)
```diff
~ agents/main/sessions/3c87b715-25a0-4aa9-9d96-9f151345518e.jsonl [content-diff] state=730289 snap=730285
~ agents/main/sessions/5fe72f1c-94a9-4b89-a274-61774506ecd6.jsonl [content-diff] state=1226605 snap=1214811
~ agents/main/sessions/6ad9d2be-04ed-41b9-93c0-24721aecab21.jsonl [content-diff] state=611780 snap=611329
~ agents/main/sessions/7a7f6af1-5807-43d4-9b1b-c7e39b4337d6.jsonl [content-diff] state=57348 snap=57243
~ agents/main/sessions/fb48eb0a-59ee-4ede-bc0a-01ab70fd0497.jsonl [content-diff] state=326748 snap=326664
~ identity/device-auth.json [content-diff] state=428 snap=401
~ identity/device.json [content-diff] state=416 snap=318
~ openclaw.json [content-diff] state=4148 snap=4144
```

## kimiclaw

### Top missing files (red, up to 80)
```diff
- .init-done.lock
- .ssh/config
- .ssh/id_ed25519_github
- .ssh/id_ed25519_github.pub
- .ssh/known_hosts
- agents/main/agent/models.json
- agents/main/sessions/3c87b715-25a0-4aa9-9d96-9f151345518e.jsonl
- agents/main/sessions/5fe72f1c-94a9-4b89-a274-61774506ecd6.jsonl
- agents/main/sessions/5fe72f1c-94a9-4b89-a274-61774506ecd6.jsonl.lock
- agents/main/sessions/6ad9d2be-04ed-41b9-93c0-24721aecab21.jsonl
- agents/main/sessions/7a7f6af1-5807-43d4-9b1b-c7e39b4337d6.jsonl
- agents/main/sessions/d19c61a4-3402-48dd-876a-00e5d3b1f933.jsonl
- agents/main/sessions/db0374f4-048a-476f-9373-324b253986df.jsonl
- agents/main/sessions/fb48eb0a-59ee-4ede-bc0a-01ab70fd0497.jsonl
- agents/main/sessions/sessions.json.bak
- canvas/index.html
- cron/jobs.json.bak
- devices/paired.json
- devices/pending.json
- feishu/dedup/default.json
- identity/device-auth.json
- openclaw.json.bak
- openclaw.json.bak.1
- openclaw.json.bak.2
- openclaw.json.bak.20260307001035
- openclaw.json.bak.20260307002241
- openclaw.json.bak.3
- openclaw.json.bak.groupfix
- skills/coding-agent/SKILL.md
- skills/find-skills/SKILL.md
- skills/github/SKILL.md
- skills/github/_meta.json
- skills/react-best-practices-cn/AGENTS.md
- skills/react-best-practices-cn/CHANGES.md
- skills/react-best-practices-cn/README.md
- skills/react-best-practices-cn/SKILL.md
- skills/react-best-practices-cn/metadata.json
- skills/react-best-practices-cn/rules/_sections.md
- skills/react-best-practices-cn/rules/advanced-event-handler-refs.md
- skills/react-best-practices-cn/rules/advanced-use-latest.md
- skills/react-best-practices-cn/rules/async-defer-await.md
- skills/react-best-practices-cn/rules/async-parallel.md
- skills/react-best-practices-cn/rules/bundle-barrel-imports.md
- skills/react-best-practices-cn/rules/bundle-defer-third-party.md
- skills/react-best-practices-cn/rules/bundle-dynamic-imports.md
- skills/react-best-practices-cn/rules/client-event-listeners.md
- skills/react-best-practices-cn/rules/client-localstorage-schema.md
- skills/react-best-practices-cn/rules/client-passive-event-listeners.md
- skills/react-best-practices-cn/rules/client-swr-dedup.md
- skills/react-best-practices-cn/rules/js-batch-dom-css.md
- skills/react-best-practices-cn/rules/js-cache-function-results.md
- skills/react-best-practices-cn/rules/js-cache-property-access.md
- skills/react-best-practices-cn/rules/js-cache-storage.md
- skills/react-best-practices-cn/rules/js-early-exit.md
- skills/react-best-practices-cn/rules/js-hoist-regexp.md
- skills/react-best-practices-cn/rules/js-index-maps.md
- skills/react-best-practices-cn/rules/js-set-map-lookups.md
- skills/react-best-practices-cn/rules/js-tosorted-immutable.md
- skills/react-best-practices-cn/rules/rendering-animate-svg-wrapper.md
- skills/react-best-practices-cn/rules/rendering-conditional-render.md
- skills/react-best-practices-cn/rules/rendering-content-visibility.md
- skills/react-best-practices-cn/rules/rendering-hoist-jsx.md
- skills/react-best-practices-cn/rules/rendering-hydration-no-flicker.md
- skills/react-best-practices-cn/rules/rendering-svg-precision.md
- skills/react-best-practices-cn/rules/rerender-defer-reads.md
- skills/react-best-practices-cn/rules/rerender-dependencies.md
- skills/react-best-practices-cn/rules/rerender-derived-state.md
- skills/react-best-practices-cn/rules/rerender-functional-setstate.md
- skills/react-best-practices-cn/rules/rerender-lazy-state-init.md
- skills/react-best-practices-cn/rules/rerender-memo.md
- skills/react-best-practices-cn/rules/rerender-transitions.md
- skills/react-best-practices-cn/хоЙшгЕшп┤цШО.md
- skills/self-improving-agent/SKILL.md
- skills/self-improving-agent/_meta.json
- skills/self-improving-agent/assets/LEARNINGS.md
- skills/self-improving-agent/assets/SKILL-TEMPLATE.md
- skills/self-improving-agent/hooks/openclaw/HOOK.md
- skills/self-improving-agent/hooks/openclaw/handler.js
- skills/self-improving-agent/hooks/openclaw/handler.ts
- skills/self-improving-agent/references/examples.md
- ... (101 more)
```

### Top extra files (green, up to 80)
```diff
+ manifest.json
```

### Top changed files (content/size/header, up to 40)
```diff
~ openclaw.json [content-diff] state=4148 snap=4169
```

## huoshanclaw

### Top missing files (red, up to 80)
```diff
- .init-done.lock
- .ssh/config
- .ssh/id_ed25519_github
- .ssh/id_ed25519_github.pub
- .ssh/known_hosts
- agents/main/agent/models.json
- agents/main/sessions/3c87b715-25a0-4aa9-9d96-9f151345518e.jsonl
- agents/main/sessions/5fe72f1c-94a9-4b89-a274-61774506ecd6.jsonl
- agents/main/sessions/5fe72f1c-94a9-4b89-a274-61774506ecd6.jsonl.lock
- agents/main/sessions/6ad9d2be-04ed-41b9-93c0-24721aecab21.jsonl
- agents/main/sessions/7a7f6af1-5807-43d4-9b1b-c7e39b4337d6.jsonl
- agents/main/sessions/d19c61a4-3402-48dd-876a-00e5d3b1f933.jsonl
- agents/main/sessions/db0374f4-048a-476f-9373-324b253986df.jsonl
- agents/main/sessions/fb48eb0a-59ee-4ede-bc0a-01ab70fd0497.jsonl
- agents/main/sessions/sessions.json.bak
- canvas/index.html
- cron/jobs.json.bak
- devices/paired.json
- devices/pending.json
- feishu/dedup/default.json
- identity/device-auth.json
- openclaw.json.bak
- openclaw.json.bak.1
- openclaw.json.bak.2
- openclaw.json.bak.20260307001035
- openclaw.json.bak.20260307002241
- openclaw.json.bak.3
- openclaw.json.bak.groupfix
- skills/coding-agent/SKILL.md
- skills/find-skills/SKILL.md
- skills/github/SKILL.md
- skills/github/_meta.json
- skills/react-best-practices-cn/AGENTS.md
- skills/react-best-practices-cn/CHANGES.md
- skills/react-best-practices-cn/README.md
- skills/react-best-practices-cn/SKILL.md
- skills/react-best-practices-cn/metadata.json
- skills/react-best-practices-cn/rules/_sections.md
- skills/react-best-practices-cn/rules/advanced-event-handler-refs.md
- skills/react-best-practices-cn/rules/advanced-use-latest.md
- skills/react-best-practices-cn/rules/async-defer-await.md
- skills/react-best-practices-cn/rules/async-parallel.md
- skills/react-best-practices-cn/rules/bundle-barrel-imports.md
- skills/react-best-practices-cn/rules/bundle-defer-third-party.md
- skills/react-best-practices-cn/rules/bundle-dynamic-imports.md
- skills/react-best-practices-cn/rules/client-event-listeners.md
- skills/react-best-practices-cn/rules/client-localstorage-schema.md
- skills/react-best-practices-cn/rules/client-passive-event-listeners.md
- skills/react-best-practices-cn/rules/client-swr-dedup.md
- skills/react-best-practices-cn/rules/js-batch-dom-css.md
- skills/react-best-practices-cn/rules/js-cache-function-results.md
- skills/react-best-practices-cn/rules/js-cache-property-access.md
- skills/react-best-practices-cn/rules/js-cache-storage.md
- skills/react-best-practices-cn/rules/js-early-exit.md
- skills/react-best-practices-cn/rules/js-hoist-regexp.md
- skills/react-best-practices-cn/rules/js-index-maps.md
- skills/react-best-practices-cn/rules/js-set-map-lookups.md
- skills/react-best-practices-cn/rules/js-tosorted-immutable.md
- skills/react-best-practices-cn/rules/rendering-animate-svg-wrapper.md
- skills/react-best-practices-cn/rules/rendering-conditional-render.md
- skills/react-best-practices-cn/rules/rendering-content-visibility.md
- skills/react-best-practices-cn/rules/rendering-hoist-jsx.md
- skills/react-best-practices-cn/rules/rendering-hydration-no-flicker.md
- skills/react-best-practices-cn/rules/rendering-svg-precision.md
- skills/react-best-practices-cn/rules/rerender-defer-reads.md
- skills/react-best-practices-cn/rules/rerender-dependencies.md
- skills/react-best-practices-cn/rules/rerender-derived-state.md
- skills/react-best-practices-cn/rules/rerender-functional-setstate.md
- skills/react-best-practices-cn/rules/rerender-lazy-state-init.md
- skills/react-best-practices-cn/rules/rerender-memo.md
- skills/react-best-practices-cn/rules/rerender-transitions.md
- skills/react-best-practices-cn/хоЙшгЕшп┤цШО.md
- skills/self-improving-agent/SKILL.md
- skills/self-improving-agent/_meta.json
- skills/self-improving-agent/assets/LEARNINGS.md
- skills/self-improving-agent/assets/SKILL-TEMPLATE.md
- skills/self-improving-agent/hooks/openclaw/HOOK.md
- skills/self-improving-agent/hooks/openclaw/handler.js
- skills/self-improving-agent/hooks/openclaw/handler.ts
- skills/self-improving-agent/references/examples.md
- ... (103 more)
```

### Top extra files (green, up to 80)
```diff
+ agents/main/sessions/sessions.json.bak.bak
+ catpawclaw_manifest.json
+ cron/jobs.json.bak.bak
+ identity/device.json.bak.bak
+ kimiclaw_manifest.json
+ manifest.json
+ workspace/AGENTS.md.bak.bak
+ workspace/IDENTITY.md.bak.bak
+ workspace/MEMORY.md.bak.bak
+ workspace/SOUL.md.bak.bak
+ workspace/TOOLS.md.bak.bak
+ workspace/USER.md.bak.bak
```

### Top changed files (content/size/header, up to 40)
```diff
~ openclaw.json [content-diff] state=4148 snap=4205
```