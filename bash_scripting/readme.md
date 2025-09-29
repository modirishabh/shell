# Bash Scripting for DevOps Automations (Basics → Advanced, CI/CD‑Ready)

A practical, copy‑pasteable cheatsheet from fundamentals to production‑grade patterns. Focused on CI/CD, cron, and incident automation.

> **Assumptions**: GNU Bash ≥ 4, Linux environment. Many snippets work on macOS; install GNU tools if needed.

---

## 0) Script template (production‑grade)
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s lastpipe

# --- configurable defaults ---
LOG_LEVEL=${LOG_LEVEL:-info}
WORKDIR=${WORKDIR:-$(pwd)}

# --- utilities ---
log()   { printf '%s [%s] %s\n' "$(date -Is)" "$1" "${*:2}"; }
die()   { log ERROR "$*"; exit 1; }
req()   { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }

# Retry with exponential backoff: retry 5 curl attempts (base 1s)
retry() { local n=0 max=${1:-5} delay=${2:-1}; shift 2; while :; do "$@" && return 0; n=$((n+1));
          [[ $n -ge $max ]] && return 1; sleep $((delay<<n)); done }

# Robust tempdir with cleanup
TMPDIR=$(mktemp -d) ; trap 'rm -rf "$TMPDIR"' EXIT

# Safer IFS for read loops
IFS=$'\n\t'
```

---

## 1) Shell basics you actually use
```bash
# Variables & parameter expansion
name="rishabh"; echo "Hello ${name^}"      # capitalize first letter
msg=${1:-default}                             # default value
req_env=${REQUIRED?must set REQUIRED var}     # fail if missing

# Arrays
arr=(alpha beta gamma); echo "${arr[1]}"; echo "${arr[@]}"; echo "${#arr[@]}"

# Arithmetic & test
x=5; (( x > 3 )) && echo ok
if [[ $msg =~ ^ok|pass$ ]]; then echo "passed"; fi

# Loops
for f in *.log; do echo "$f"; done
while read -r line; do echo "$line"; done < file.txt

# Case
case $LOG_LEVEL in info|warn|error) ;; *) die "bad LOG_LEVEL";; esac

# Functions return via exit code or stdout
foo(){ local out=$(( RANDOM % 10 )); echo "$out"; return 0; }
```

---

## 2) Strict mode, traps, and safety
```bash
set -Eeuo pipefail     # fail fast; pipeline fails on any stage
trap 's=$?; log ERROR "on line $LINENO (exit $s)"; exit $s' ERR
trap 'log INFO "received SIGINT"; exit 130' INT
shopt -s nullglob dotglob                     # predictable globs
```

**Why it matters**: CI should fail on the first real error; traps give actionable logs.

---

## 3) Input & output patterns
```bash
# Read CSV safely (no IFS=, global pollution)
while IFS=',' read -r id name role note value; do
  printf '%s -> %s (%s)\n' "$id" "$name" "$role"
done < data.csv

# Here-doc for config
cat > "$TMPDIR"/my.conf <<'CONF'
key=value
feature=true
CONF

# Command substitution (avoid subshell surprises with lastpipe)
mapfile -t paths < <(find . -name '*.yaml')
```

---

## 4) Filesystem & processes (with `find`, `grep`, `awk`, `sed`)
```bash
# Delete logs older than 14 days (dry-run -> live)
find /var/log/myapp -type f -name '*.log' -mtime +14 -print
find /var/log/myapp -type f -name '*.log' -mtime +14 -delete

# Top endpoints by 5xx (access.log from lab)
rate=$(grep -E ' 5[0-9]{2} ' access.log | awk '{e[$7]++} END{t=0; for(k in e) t+=e[k]; print t+0}')

# Redact tokens on the fly
grep -E '(Authorization: *Bearer|X-Api-Key:)' app.log \
 | sed -E 's/(Authorization: *Bearer) +[A-Za-z0-9._-]+/\1 *** /; s/(X-Api-Key:) +\S+/\1 *** /'
```

---

## 5) Argument parsing (portable)
```bash
usage(){ cat <<EOF
Usage: $0 -e ENV -r REGION [-d]
  -e  environment (dev|stg|prd)
  -r  region
  -d  dry-run
EOF
}
DRY=0; ENV=""; REGION=""
while getopts ':e:r:dh' opt; do
  case $opt in
    e) ENV=$OPTARG;; r) REGION=$OPTARG;; d) DRY=1;; h) usage; exit 0;;
    :) die "-$OPTARG requires value";; \?) die "unknown option -$OPTARG";;
  esac
done
[[ -z $ENV || -z $REGION ]] && { usage; exit 2; }
```

---

## 6) HTTP, JSON/YAML, and APIs
```bash
req curl jq
# GET with timeout & retry
retry 5 1 curl -fsS --max-time 5 'https://httpbin.org/status/200' >/dev/null

# POST to Slack webhook (message only; set SLACK_WEBHOOK)
[[ -n ${SLACK_WEBHOOK:-} ]] && curl -fsS -X POST -H 'Content-Type: application/json' \
  -d '{"text":"Deploy passed :rocket:"}' "$SLACK_WEBHOOK"

# Parse JSON value
resp='{"status":200,"items":[{"id":1},{"id":2}]}'
echo "$resp" | jq -r '.items[].id'
```

---

## 7) Parallelism & timeouts
```bash
# Run tasks in parallel (xargs)
printf '%s\n' service-a service-b service-c | \
  xargs -n1 -P3 -I{} bash -c 'systemctl is-active {} >/dev/null && echo "{} OK" || echo "{} FAIL"'

# Timeout a flaky command
timeout 10s kubectl rollout status deploy/myapp || die "rollout timeout"
```

---

## 8) CI/CD gates & checks (drop-in)
```bash
# Gate: fail if ERROR appears in logs
tail -n 1000 app.log | { ! grep -q 'ERROR'; } || die 'errors in app.log'

# Gate: changelog must contain today
DATE=$(date +%F); grep -q "^## $DATE" CHANGELOG.md || die "changelog missing for $DATE"

# Gate: secret scan quick check
{ grep -RInE '(AKIA[0-9A-Z]{16}|secret[_-]?key|Bearer [A-Za-z0-9._-]{20,})' . && die 'secrets found'; } || true

# Artifact promotion: pick latest jar and bump image tag in k8s manifest
latest=$(find artifacts -name 'myapp-*.jar' -printf '%f\n' | sed -E 's/.*-([0-9.]+)\.jar/\1/' | sort -V | tail -1)
sed -i -E "s#(image: myrepo/myapp:)v?[0-9.]+#\1${latest}#" k8s/deployment.yaml
```

---

## 9) Logging, metrics, and reports
```bash
# Emit CSV metrics row: minute,total,5xx,rate
minute=$(date -u +"%d/%b/%Y:%H:%M")
T=$(grep "$minute" access.log | wc -l)
F=$(grep "$minute" access.log | grep -E ' 5[0-9]{2} ' | wc -l)
printf '%s,%d,%d,%.2f\n' "$minute" "$T" "$F" "$(awk -v t=$T -v f=$F 'BEGIN{print t?100*f/t:0}')" >> minute_error_rate.csv
```

---

## 10) Packaging & distribution
```bash
# Create a tarball of scripts (exclude VCS/build)
tar --exclude-vcs --exclude='*.tmp' -czf release.tar.gz scripts/

# Self‑contained single file with embedded config
cat <<'SCRIPT' > run.sh
#!/usr/bin/env bash
set -Eeuo pipefail
CONFIG='{"feature":true,"url":"https://example"}'
echo "$CONFIG" | jq .
SCRIPT
chmod +x run.sh
```

---

## 11) Testing & linting bash
```bash
# Lint
shellcheck -x script.sh
# Unit-ish tests with bats (if available)
bats tests/
```

---

## 12) Patterns you’ll reuse
```bash
# With‑statement for directory push/pop
pushd "$WORKDIR" >/dev/null; trap 'popd >/dev/null || true' RETURN

# Require env vars
: "${AWS_REGION:?set AWS_REGION}" "${ENV:?set ENV}"

# Progress dots
spin(){ while kill -0 "$1" 2>/dev/null; do printf '.'; sleep 0.5; done; }

# JSON pretty print fallback
jpp(){ command -v jq >/dev/null && jq . || python -m json.tool; }
```

---

## 13) Real scenarios (end‑to‑end)

### A) Pre‑deploy smoke gate
```bash
set -Eeuo pipefail
journalctl -u api --since '-5 min' \
 | grep -E 'OutOfMemoryError|connection refused|panic:' \
 | sed 's/^/[BLOCKER] /' \
 | tee /tmp/predeploy.err \
 && die 'predeploy blockers detected' || log INFO 'predeploy checks passed'
```

### B) Canary rollout with auto‑rollback
```bash
set -Eeuo pipefail
kubectl -n prod set image deploy/myapp myapp=myrepo/myapp:${TAG:?}
sleep 5
if ! timeout 60s kubectl -n prod rollout status deploy/myapp; then
  log ERROR 'rollout stuck; rolling back'
  kubectl -n prod rollout undo deploy/myapp || true
  exit 2
fi
```

### C) Nightly drift report vs baseline
```bash
normalize(){ grep -vE '^#|^$' /etc/myapp/app.ini | sed -E 's/[ ]*=[ ]*/=/' | sort; }
if ! diff -u <(normalize) <(grep -vE '^#|^$' srv/baselines/app.ini | sed -E 's/[ ]*=[ ]*/=/' | sort) > drift.diff; then
  log WARN 'drift detected'; cat drift.diff
fi
```

---

## 14) CI integration snippets
```bash
# GitHub Actions step (bash as shell)
- name: Pre-deploy gate
  run: |
    set -Eeuo pipefail
    journalctl -u api --since '-5 min' | grep -q 'ERROR' && exit 1 || true

# GitLab CI
predeploy:
  stage: test
  script:
    - set -Eeuo pipefail
    - "{ ! grep -RIn 'SECRET_KEY=' .; }"
```

---

## 15) Debugging tricky failures
```bash
set -x                                  # trace
PS4='+ ${BASH_SOURCE}:${LINENO}:${FUNCNAME[0]}: '

# Trace a single function
trap 'echo "ERR at ${BASH_SOURCE}:${LINENO}"' ERR
```

---

### Reference mindset
- **Fail fast** (`set -Eeuo pipefail`), **clean up** (trap), **log clearly**.
- **Small, testable functions**; prefer pure text I/O.
- Use `grep` to **filter**, `awk` to **compute**, `sed` to **edit**, `find` to **select files**.
- In CI, decisions are **exit codes**; print human‑friendly context.

> Use with the lab bundle you downloaded earlier (`devops-cli-lab.zip`) so most examples run as‑is.

