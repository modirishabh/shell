# DevOps Automations Playbook — `find` (Beginner‑Friendly, Real Scenarios)

Real, copy‑pasteable `find` recipes for CI/CD, cron, and incident response. Each shows: **Goal → Command → Why it works → Automation hook.**

> Golden rules: 1) **Test with `-print` first.** 2) Prefer **`-exec … {} +`** (batch) over `\;` (per‑file). 3) Use **null‑safety**: `-print0` ↔ `xargs -0`.

---

## Quick Basics
- Structure: `find <start-dir> [tests/actions]`
- Common tests: `-type f|d|l`, `-name/-iname`, `-path/-ipath`, `-size`, `-mtime/-mmin`, `-newer/-newermt`, `-perm`, `-user/-group`, `-empty`
- Control: `-maxdepth N`, `-mindepth N`, `-prune` (skip), `-not`/`!` (negate), `-o` (OR), parentheses `\( ... \)`
- Output/actions: `-print`, `-printf` (GNU), `-delete`, `-exec cmd {} +`, `-execdir`, `-ok` (interactive)

---

## A) Hygiene & housekeeping

### A1) Delete log files older than 14 days (safe & space‑efficient)
```bash
find /var/log/myapp -type f -name '*.log' -mtime +14 -print -delete
```
**Why:** `-mtime +14` = strictly older than 14 *days since last modification*. `-print` shows what will be removed.
**Automation:** cron daily. Add `-maxdepth 1` if you don’t want recursion.

### A2) Compress old logs, keep recent ones
```bash
find /var/log/myapp -type f -name '*.log' -mtime +2 -not -name '*.gz' -exec gzip -9 {} +
```
**Why:** avoids double‑compressing; batches files for fewer `gzip` invocations.
**Automation:** nightly cron.

### A3) Purge empty files & 0‑byte artifacts
```bash
find /srv/builds -type f -empty -print -delete
```
**Why:** cleans partial uploads or failed artifacts.
**Automation:** hourly cron with logging to a cleanup channel.

### A4) Remove leftover temp dirs but keep cache dirs
```bash
find /tmp -maxdepth 2 -type d -name 'myapp-*' -mtime +1 -prune -o -name 'cache' -prune -o -type d -name 'myapp-*' -mtime +1 -print -exec rm -rf {} +
```
**Why:** `-prune` skips certain paths. The final clause targets old `myapp-*` directories.

---

## B) Security & compliance

### B1) Find world‑writable files outside allowed paths
```bash
find / -xdev \( -path '/proc' -o -path '/sys' -o -path '/run' \) -prune -o \
  -type f -perm -0002 -printf '%m %u %g %p\n'
```
**Why:** `-perm -0002` matches any file with the others‑write bit. `-xdev` stays on this filesystem.
**Automation:** export to CSV, alert if non‑empty.

### B2) Detect private keys or certs leaked in images or repos
```bash
find . -type f -regex '.*\.(pem|key|p12|pfx)$' -printf '[SECRET] %p\n'
```
**Why:** fast sweep by extension; combine with `grep` for content patterns if needed.

### B3) Check ownership/permissions drift
```bash
find /etc/myapp -type f -not -user myapp -o -not -group myapp -printf '%u:%g %p\n'
```
**Why:** surfaces files not owned by the expected service account.

---

## C) Release engineering & artifacts

### C1) Keep only the latest 5 artifacts per service
```bash
find /srv/artifacts -type f -name 'myapp-*.jar' -printf '%T@ %p\n' | sort -nr | awk 'NR>5{print $2}' | xargs -r rm -f
```
**Why:** `-printf %T@` gives epoch mtime for stable sorting; remove older ones.
**Automation:** post‑release cleanup.

### C2) Promote latest semver into deployment manifests
```bash
ver=$(find artifacts -type f -name 'myapp-*.jar' -printf '%f\n' | sed -E 's/.*-([0-9.]+)\.jar/\1/' | sort -V | tail -1)
sed -i -E "s#(image: myrepo/myapp:)v?[0-9.]+#\1${ver}#" k8s/deployment.yaml
```
**Why:** `find` enumerates artifacts regardless of subdirs; `sort -V` = natural version sort.

### C3) Validate changelog for today’s date across many modules
```bash
find . -maxdepth 2 -type f -name CHANGELOG.md -exec grep -Hq "^## $(date +%F)" {} \; -print
```
**Why:** prints modules missing today’s entry (because `grep -q` returns non‑zero and triggers `-print`).

---

## D) Logs & observability

### D1) Slice today’s logs quickly and feed to processors
```bash
find /var/log/nginx -type f -name 'access.log*' -newermt '00:00' -exec zcat -f {} + | grep -E ' 5[0-9]{2} '
```
**Why:** `-newermt '00:00'` matches files modified since midnight (GNU). `zcat -f` handles gz and plain.

### D2) Ship only rotated logs from last hour
```bash
find /var/log/myapp -type f -name '*.log.gz' -mmin -60 -exec aws s3 cp {} s3://bucket/logs/ \;
```
**Why:** scoped time window keeps transfers small.

### D3) Generate a lightweight inventory of logs (CSV)
```bash
find /var/log -type f -name '*.log*' -printf '%p,%s,%TY-%Tm-%Td %TH:%TM:%TS\n' > /tmp/log_inventory.csv
```
**Why:** capture path, size, and modtime for audits.

---

## E) Kubernetes & containers

### E1) Find YAMLs that define Deployments/StatefulSets
```bash
find manifests -type f -name '*.yaml' -exec grep -HnE '^kind: *(Deployment|StatefulSet)' {} +
```
**Why:** combine `find` breadth with `grep` precision.

### E2) Bulk edit image repos (dry‑run first)
```bash
find k8s -type f -name '*.yaml' -print -exec sed -nE 's#(image: )myrepo/#\1registry.example.com/myrepo/#p' {} +
# If output looks good, apply for real:
find k8s -type f -name '*.yaml' -exec sed -i -E 's#(image: )myrepo/#\1registry.example.com/myrepo/#' {} +
```
**Why:** first pass prints prospective changes, then in‑place edit.

### E3) Extract container images referenced anywhere
```bash
find . -type f -name '*.yaml' -exec grep -HoE 'image: *[^ ]+' {} + | awk '{print $2}' | sort -u
```
**Why:** inventory images for allow‑list checks.

---

## F) CI/CD guards & pre‑commit hooks

### F1) Block secrets before commit
```bash
find . -type f -not -path './.git/*' -exec grep -HnE '(AKIA[0-9A-Z]{16}|secret[_-]?key|Bearer [A-Za-z0-9._-]{20,})' {} + && { echo 'Secrets found!'; exit 1; } || true
```
**Why:** `find` respects exclude; one command works on macOS/Linux.

### F2) Lint only changed files in last commit
```bash
find . -type f -newermt "$(git show -s --format=%cI HEAD~0)" -name '*.sh' -exec shellcheck -x {} +
```
**Why:** `-newermt` with a Git timestamp focuses work.

### F3) Ensure license header exists
```bash
find . -type f -name '*.go' -exec grep -L 'Copyright .* UKG' {} + | sed 's/^/Missing license: /' && exit 1 || true
```
**Why:** `grep -L` returns files without the header; fail build if any.

---

## G) Backups & integrity

### G1) Verify backup newer than reference marker
```bash
touch -d 'yesterday' /tmp/mark
find /backups -type f -name 'myapp-*.tar.gz' -newer /tmp/mark -print -quit | grep -q . || { echo 'No fresh backup!'; exit 2; }
```
**Why:** `-newer` against a marker file is portable.

### G2) Compare current vs baseline file lists
```bash
find /etc/myapp -type f -printf '%P\n' | sort > /tmp/current.lst
cat /srv/baselines/app.lst | sort > /tmp/base.lst
diff -u /tmp/base.lst /tmp/current.lst || echo 'Drift detected'
```
**Why:** `%P` prints path relative to start dir; makes clean diffs.

---

## H) Performance & safety patterns
- Use `-prune` to skip heavy trees: `-path '*/node_modules/*' -prune -o ...`
- Prefer batching with `-exec ... {} +` for fewer processes.
- For filenames with spaces/newlines: `find . -print0 | xargs -0 -r <cmd>`
- Combine name filters: `\( -name '*.log' -o -name '*.out' \)`
- Be careful with `-delete` ordering; keep tests *before* `-delete`.
- `-execdir` runs the command in the found file’s directory—safer for relative paths.

---

## I) Handy one‑liners (ready to paste)
```bash
# Largest 20 files under /var (human sizes)
find /var -type f -printf '%s %p\n' | sort -nr | head -20 | awk '{printf "%.1f MB  %s\n", $1/1024/1024, substr($0,index($0,$2))}'

# Touch only JS files changed today
find src -type f -name '*.js' -newermt '00:00' -exec touch {} +

# Remove pyc caches safely
find . -type d -name '__pycache__' -prune -exec rm -rf {} +

# List broken symlinks
find . -xtype l -printf 'broken -> %p\n'

# Files modified in last 10 minutes, with ISO time
find . -type f -mmin -10 -printf '%TY-%Tm-%TdT%TH:%TM:%TS %p\n'
```

---

## J) Visual: find in automations
```
      ┌────────┐      ┌────────┐      ┌────────┐
repo →│  find  │─→→→→ │  grep  │─→→→→ │  awk   │ → sort/uniq/xargs → action
      └────────┘      └────────┘      └────────┘
 scope & select       narrow more        compute
```

---

## K) How to extend
1) Start with `find` to **select the right files**.
2) Pipe to `grep` for **content filters** or to `xargs`/`-exec` for actions.
3) In CI, treat **non‑empty output as failure** (or success for presence checks).
4) In cron, **log before you delete**, and prefer dry‑run with `-print` first.

