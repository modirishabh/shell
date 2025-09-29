# DevOps Automations Playbook: `grep+sed`, `grep+awk`, `awk+sed`

Real scenarios you can drop into CI/CD, cron, and incident tooling. Each recipe shows:
**Goal → Command/Pipeline → Why it works → Automation hook (exit code / usage).**

> Tip: In automations, **exit codes** are the contract. `grep -q`/`awk` conditions should return 0 for PASS and non‑zero for FAIL unless noted.

---

## 0) Reusable wrappers (copy‑paste)
```bash
# Gate a step: fail if pattern appears
log_guard() { local pat="$1"; shift; "$@" 2>&1 | tee run.log | { ! grep -qE "$pat"; } }

# Cron‑safe runner: log and alert on failure
run_or_alert() { "$@" >>/var/log/ops.log 2>&1 || echo "$(date -Is) FAIL: $*" >&2; }

# Commit hook: block secrets (git pre-commit)
secret_scan() { grep -RInE '(AKIA[0-9A-Z]{16}|secret[_-]?key|Bearer [A-Za-z0-9._-]{20,})' . && return 1 || return 0; }
```

---

## A) `grep + sed` — filter then fix (or prove fixed)

### A1) Mask secrets in logs during collection
**Goal:** prevent tokens from reaching long‑term storage.
```bash
journalctl -u my.service -n 1000 \
 | grep -E '(Authorization: *Bearer|X-Api-Key:)' \
 | sed -E 's/(Authorization: *Bearer) +[A-Za-z0-9._-]+/\1 *** /; s/(X-Api-Key:) +\S+/\1 *** /'
```
**Why:** `grep` narrows to sensitive lines; `sed` redacts in place.
**Automation:** pipe sanitized stream to S3 or SIEM.

### A2) Auto‑normalize timestamps before shipping
```bash
tail -F app.log \
 | grep -vE 'DEBUG|healthz' \
 | sed -E 's#([0-9]{4})/([0-9]{2})/([0-9]{2}) ([0-9:]{8})#\1-\2-\3T\4#'
```
**Why:** keep volume low and format uniform.
**Automation:** feed to `fluent-bit`/`vector` stdin.

### A3) CI: forbid TODO/FIXME unless annotated
```bash
grep -RInE --include='*.{go,py,ts,sh}' '\b(TODO|FIXME)\b(?!\s*\[ticket#[0-9]+\])' . \
 | sed 's/^/UNTRACKED NOTE: /' \
 && exit 1 || echo "OK: all TODOs referenced"
```
**Why:** `grep` finds violations; `sed` makes output reviewer‑friendly.
**Automation:** run in CI step, fail build on match.

### A4) Config drift snapshot
```bash
diff <(grep -vE '^#|^$' /etc/myapp/config.ini | sed -E 's/[ ]*=[ ]*/=/' | sort) \
     <(cat /var/backups/config.ini.baseline | grep -vE '^#|^$' | sed -E 's/[ ]*=[ ]*/=/' | sort)
```
**Why:** compare normalized, comment‑free views to detect drift.
**Automation:** cron daily; email diff if non‑zero.

---

## B) `grep + awk` — filter then compute/aggregate

### B1) SLO burn alert on HTTP 5xx rate
```bash
# Assumes combined log; path=$7 status=$9
rate=$(grep -E ' 5[0-9]{2} ' /var/log/nginx/access.log \
       | awk '{err[$7]++} END{t=0; for(k in err) t+=err[k]; print t+0}')
[ "${rate}" -gt 100 ] && echo "ALERT: 100+ 5xx in window" && exit 2 || exit 0
```
**Why:** `grep` extracts 5xx quickly; `awk` tallies.
**Automation:** run every minute with cron/systemd timer.

### B2) Top noisy IPs last 10 min
```bash
logslice=$(date -u "+%d/%b/%Y:%H:%M:")
grep "${logslice}" /var/log/nginx/access.log \
 | awk '{ip=$1; c[ip]++} END{for(i in c) printf "%7d %s\n", c[i], i}' \
 | sort -nr | head -20
```
**Why:** timestamp pre‑filter; `awk` counts.
**Automation:** push to on‑call Slack.

### B3) CI: enforce license headers
```bash
grep -RIL --exclude-dir=.git --include='*.{go,ts,py,sh}' 'Copyright .* UKG' . \
 | awk '{print "Missing license:", $0; fail=1} END{exit fail?1:0}'
```
**Why:** `grep -L` lists files without the header; `awk` formats & sets exit.
**Automation:** fail PR if any missing.

### B4) Error budget by endpoint
```bash
grep -E ' 5[0-9]{2} ' access.log \
 | awk '{e[$7]++} {t[$7]++} END{for(p in t){pct=(e[p]?100*e[p]/t[p]:0); printf("%6.2f%% %s\n", pct, p)}}' \
 | sort -nr | head
```
**Why:** `grep` narrows; `awk` computes % per path.
**Automation:** nightly job to markdown report.

---

## C) `awk + sed` — compute then rewrite/patch

### C1) Auto‑patch slow endpoints into a blocklist
```bash
# Build list of endpoints whose p95 > 2s, then comment them out in config
awk '{t[$7]+=$10; n[$7]++; if($10>p95[$7]) p95[$7]=$10} END{for(p in n) if(p95[p]>2) print p}' access.log \
 | sed -E 's#^#^location \##; s#$#\$#' > slow_paths.regex
# Use resulting patterns to modify nginx conf (example pattern)
sed -i -E -f <(awk '{print "s#(location " $0 ")#\1\n  # auto-throttled#"}' slow_paths.regex) /etc/nginx/nginx.conf
nginx -t && systemctl reload nginx
```
**Why:** `awk` decides the set; `sed` performs structural edits.
**Automation:** weekly hygiene job.

### C2) Promote latest artifact version across manifests
```bash
latest=$(ls -1 artifacts/myapp-*.jar | awk -F'[.-]' '{print $(NF-1)}' | sort -V | tail -1)
sed -i -E "s#(image: myrepo/myapp:)v?[0-9.]+#\1${latest}#" k8s/deployment.yaml
```
**Why:** `awk` extracts version; `sed` patches yaml.
**Automation:** run post‑build before `kubectl apply`.

### C3) Normalize flakey test output lines
```bash
# Remove variable durations so diffs are stable
awk '{gsub(/[0-9]+\.[0-9]{2}s/, "<dur>"); print}' junit.out \
 | sed -E 's#(/tmp|C:/Users/[^ ]+)#<path>#g' > junit.normalized
```
**Why:** `awk` scrubs numbers; `sed` scrubs paths.
**Automation:** compare normalized artifacts in CI.

---

## D) End‑to‑end automation examples

### D1) Pre‑deploy smoke gate
```bash
# Fail fast if error signatures appear in last N lines
journalctl -u api --since "-5 min" \
 | grep -E 'OutOfMemoryError|connection refused|panic:' \
 | sed -E 's/^/[BLOCKER] /' \
 | tee /tmp/predeploy.err \
 && exit 1 || echo "Predeploy checks passed"
```

### D2) Nightly config drift report
```bash
normalize(){ grep -vE '^#|^$' "$1" | sed -E 's/[ ]*=[ ]*/=/' | sort; }
diff <(normalize /etc/myapp/app.ini) <(normalize /srv/baselines/app.ini) \
  | sed 's/^/DRIFT: /' | tee /var/log/drift-$(date +%F).log
```

### D3) Secret hygiene in images (layer scan)
```bash
container-diff analyze daemon://myapp:latest -t file \
 | grep -E '/(id_rsa|\.pem|\.p12|config\.json)$' \
 | sed 's/^/[SECRET FILE] /' \
 && exit 2 || exit 0
```

### D4) SLA dashboard feeder (minute job)
```bash
# Emit CSV: minute,total,5xx,rate
nginx_log=/var/log/nginx/access.log
minute=$(date +"%d/%b/%Y:%H:%M")
{ total=$(grep "$minute" "$nginx_log" | wc -l); \
  five=$(grep "$minute" "$nginx_log" | grep -E ' 5[0-9]{2} ' | wc -l); \
  awk -v t="$total" -v f="$five" 'BEGIN{printf "%s,%d,%d,%.2f\n", ENVIRON["minute"], t, f, (t?100*f/t:0)}'; } \
>> /var/www/data/minute_error_rate.csv
```

---

## E) Patterns for robust automations
- Prefer **`grep -F`** for literals (faster/safer); **`-E`** for regex; **`-P`** only if available.
- Combine **`--include/--exclude`** to limit search space.
- Normalize inputs (strip comments/whitespace) before diffing configs.
- In CI, print **human‑readable** violations with `sed 's/^/[TAG] /'` rather than raw lines.
- For structured data, use the right tool (`jq`/`yq`) and use `grep/sed/awk` only to **pre‑filter**.
- Always test locally with small slices: `head -100 file | ...` and keep **idempotent** edits.

---

## F) Quick cheats (ready to paste)
```bash
# Fail if any TODO lacks a ticket id
grep -RInE '\bTODO\b(?!\s*\[ticket#[0-9]+\])' . && exit 1 || true

# Top 10 offenders by 5xx in last hour
grep "$(date -u +"%d/%b/%Y:%H:")" access.log | grep -E ' 5[0-9]{2} ' \
 | awk '{c[$7]++} END{for(p in c) printf "%6d %s\n", c[p], p}' | sort -nr | head

# Update deployment image tag to most recent semver
latest=$(git tag --list 'v*' | sort -V | tail -1 | tr -d v); \
sed -i -E "s#(image: myrepo/myapp:)v?[0-9.]+#\1$latest#" k8s/deployment.yaml
```

---

### How to extend
Start with `grep` to **narrow**, then choose `awk` to **calculate** or `sed` to **change**. Keep the contract simple: **0=OK, non‑zero=ALERT**.

