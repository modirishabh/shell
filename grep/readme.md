# Advanced `grep` Cheatsheet (DevOps & Log Analysis, Beginner‑Friendly)

A practical guide to **finding, filtering, and extracting** with `grep` in real production scenarios. Includes explanations and copy‑pasteable commands.

---

## Quick Basics
- `grep 'pattern' file` → print lines matching regex `pattern`.
- Useful flags:
  - `-E` (extended regex), `-F` (fixed string, faster), `-P` (Perl regex; not always available).
  - `-i` case‑insensitive, `-v` invert match, `-w` whole word.
  - `-n` show line numbers, `-H` show filename, `-r`/`-R` recursive.
  - `--color=auto` highlight matches.
  - Context: `-A N` (after), `-B N` (before), `-C N` (both).
- Exit code: 0 if found, 1 if not found, >1 on error → great for scripts/CI checks.

> **Regex choice:** Prefer `-F` for literal strings (fast), `-E` for simple patterns, `-P` only if you need advanced regex and your `grep` supports it.

---

## 1) Hunting errors in logs (with context)
```bash
# Show ERROR lines with 3 lines of context around each match
grep -n --color=auto -C3 'ERROR' app.log

# Only 5xx HTTP errors with 2 lines before
grep -n -B2 -E ' (5[0-9]{2}) ' access.log

# Exclude noisy healthchecks while searching for 500s
grep -n -E ' 5[0-9]{2} ' access.log | grep -v '/healthz'
```
➡️ Context options help you see what happened before/after the error without opening the whole file.

---

## 2) Real‑time tailing + grep
```bash
# Follow the log and only show lines mentioning timeout
tail -F app.log | grep --line-buffered -i 'timeout'
```
➡️ `--line-buffered` flushes output line‑by‑line so you see matches immediately.

---

## 3) Extracting fields quickly
```bash
# Just print matched part (status codes) from access log
grep -oE ' [0-9]{3} ' access.log | tr -d ' ' | sort | uniq -c | sort -nr

# Extract IPv4s from text (use -P if available)
grep -oP '(?<![0-9.])(?:[0-9]{1,3}\.){3}[0-9]{1,3}(?![0-9.])' *.log | sort -u
```
➡️ `-o` prints only the match (great for pipelines). `-P` uses PCRE lookarounds (portable only where available).

---

## 4) Recursive code/config searches
```bash
# Find all references to a feature flag in repo (ignore vendor and node_modules)
grep -RIn --exclude-dir={vendor,node_modules,.git} 'ENABLE_BETA' .

# Case‑insensitive search for env var across YAML/INI/TOML only
grep -RIn --include='*.{yml,yaml,ini,toml}' -i 'log_level' config/

# Show function definitions but ignore tests
grep -RIn --include='*.go' --exclude='*_test.go' '^func ' src/
```
➡️ Combine `--include/--exclude` and `--exclude-dir` to narrow search scope.

---

## 5) Kubernetes + containers
```bash
# Grep logs from a pod for a specific request id
kubectl logs deploy/api -c api --since=1h | grep -n "req_id=abcd1234"

# Find CrashLoopBackOff events in recent describe output
kubectl describe pods | grep -n -E 'CrashLoopBackOff|Back-off restarting'

# Filter k8s logs for 5xx but ignore liveness/readiness probes
kubectl logs svc/myapp -c web --since=1h | grep -E ' 5[0-9]{2} ' | grep -vE '/(healthz|ready)'
```
➡️ Use `kubectl logs ... | grep` for quick investigations; switch to `kubectl logs --previous` for last terminated container.

---

## 6) NGINX/Apache access logs
```bash
# Requests to /api with slow times (>2s) assuming time is last field in seconds
grep ' \/api' access.log | awk '{if($NF+0>2) print}'

# Top failing endpoints (status 5xx) then aggregate
grep -E ' 5[0-9]{2} ' access.log | awk '{print $7}' | sort | uniq -c | sort -nr | head

# Filter by date range (ISO date prefix in log)
grep -E '^2025-09-(2[0-9]|30)' access.log
```
➡️ `grep` narrows the stream; `awk` aggregates—classic combo.

---

## 7) Security & compliance quick wins
```bash
# Check for accidental secrets in repo (tokens, AWS keys pattern)
grep -RIn --exclude-dir=.git -E '(AKIA[0-9A-Z]{16}|secret[_-]?key|Bearer [A-Za-z0-9._-]{20,})' .

# Show only filenames (quietly)
grep -RIl -E '(password|passwd|pwd)\s*=' .

# Find world‑writable files (perm string in ls -l)
ls -lR | grep -E '^[-d].*w. .w. .w. '
```
➡️ For serious secret scanning, use dedicated tools—this is a quick, local hygiene check.

---

## 8) CI/CD and health checks
```bash
# Fail a CI job if "ERROR" appears in output
make build 2>&1 | tee build.log | { ! grep -q 'ERROR'; }

# Ensure a service started within 30s (log contains "Started")
(timeout 30s journalctl -fu my.service &) | grep -q 'Started' && echo OK || echo FAIL

# Validate that changelog includes today’s date
DATE=$(date +%F); grep -q "^## $DATE" CHANGELOG.md || { echo "Missing changelog for $DATE"; exit 1; }
```
➡️ Use grep’s exit code to guard conditions in scripts.

---

## 9) Performance & binary‑ish input
```bash
# Treat binary as text when necessary (e.g., compressed strings or control chars)
grep -a -n 'needle' suspect.bin

# Search many large files faster by restricting with -F and filename globs
grep -RInF --include='*.log' 'connection reset by peer' /var/log

# Null‑separated filenames for safety with spaces/newlines
grep -RIlZ 'TODO' . | xargs -0 -r sed -i 's/TODO/TO‑DO/g'
```
➡️ `-a` forces text mode; `-F` is faster for fixed substrings; `-Z` pairs with `xargs -0`.

---

## 10) JSON/YAML quick picks (best‑effort)
```bash
# Pull HTTP status codes from JSON logs (pcap‑like lines)
grep -oE '"status" *: *[0-9]{3}' *.json | awk -F: '{print $2}' | tr -d ' ' | sort | uniq -c

# Extract k/v pairs from env‑like YAML (rough; prefer yq)
grep -nE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*:' values.yaml
```
➡️ For structured data, prefer `jq`/`yq`; `grep` is for quick peeks and narrowing.

---

## 11) Unicode, locales, and portability notes
- Use `LC_ALL=C` to speed up regex on ASCII logs (careful with non‑ASCII data).
- `-P` may be missing on some distros (BusyBox Alpine). Fall back to `-E` or use `rg`/`ag`.
- macOS BSD `grep` differs slightly; install GNU `grep` (`ggrep`) for full parity.

---

## 12) Handy patterns to memorize
```bash
# Numeric: integers/decimals
-E '(^|[^0-9])[0-9]+(\.[0-9]+)?([^0-9]|$)'

# ISO 8601 date
-E '\\b[0-9]{4}-[0-9]{2}-[0-9]{2}\\b'

# UUID v4 (rough)
-E '\\b[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\\b'
```
➡️ Escape backslashes properly in shells and YAML.

---

## Visual: Grep in the pipeline
```
            ┌───────────┐     ┌─────────┐     ┌──────────┐
source → →  │  grep     │ → → │  awk    │ → → │  sort    │ → uniq -c → head
            └───────────┘     └─────────┘     └──────────┘
   narrow fast            compute/aggregate      rank
```

---

## Beginner Tips
- Start with `-F` for speed; switch to `-E`/`-P` only when patterns require it.
- Always add `-n` while exploring so you can jump back in an editor.
- Use `--include/--exclude` early to avoid scanning the world.
- Chain tools: `grep` to **filter**, `awk` to **summarize**, `sed` to **edit**.

---

✅ With these examples you can quickly triage incidents, search code/configs, and build robust CLI checks for CI/CD and operations.

