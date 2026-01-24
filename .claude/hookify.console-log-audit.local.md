---
name: console-log-audit
enabled: true
event: stop
pattern: .*
action: warn
---

Before stopping, check for console.log statements in modified files:

Run: `git diff --name-only | xargs grep -l "console\.log" 2>/dev/null`

If any console.log statements are found:
- Remove debug logging before committing
- Or replace with proper logging library
- Ensure production code is clean

This audit helps prevent debug code from shipping to production.
