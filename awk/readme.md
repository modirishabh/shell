# Advanced `awk` Cheatsheet (DevOps & Log Analysis, Beginner-Friendly)

This version adds **step-by-step explanations** so beginners can learn how and why each command works.

---

## Quick Basics
- **Fields**: `$1`, `$2`, … are columns. `$0` is the whole line.
- **Special vars**: 
  - `NR` → record (line) number across all files.
  - `FNR` → record number within current file.
  - `NF` → number of fields in the line.
  - `FILENAME` → current file name.
- **Blocks**: 
  - `BEGIN{}` runs before reading any lines.
  - `{}` runs for each line.
  - `END{}` runs after all lines are processed.
- **Separators**:
  - `-F` or `FS` = input field separator (default: space).
  - `OFS` = output field separator.
  - `RS` = record separator (default: newline).
- **Variables**: Pass from shell with `-v`. Example: `awk -v limit=10 '$3>limit{print}' file`.

---

## 1) Setting separators, record modes, formatting
```bash
# Example: Extract columns 2 and 5 from CSV, output with | delimiter
awk -F, 'BEGIN{OFS="|"} {print $2,$5}' data.csv
```
➡️ `-F,` tells awk fields are split by commas. `OFS="|"` sets output delimiter to `|`.

```bash
# Paragraph mode: Treat blank lines as record separators
awk 'BEGIN{RS=""; ORS="\n\n"} NF>0 {print NR, $0}' paragraphs.txt
```
➡️ Useful when processing config files or docs where blocks are separated by blank lines.

---

## 2) Powerful matching & substitution
```bash
# Filter lines where 2nd column contains 'Linux' AND 3rd column > 1000
awk '$2 ~ /Linux/ && $3 > 1000 {print $1,$2,$3}' ps.txt
```
➡️ `$2 ~ /Linux/` means "if field 2 matches regex Linux".

```bash
# Replace all 'foo' with 'bar' in file (GNU awk, in-place)
awk -i inplace '{gsub(/foo/,"bar"); print}' file.txt
```
➡️ `gsub()` replaces all occurrences of a regex in the current line.

---

## 3) Group by / aggregate (SQL‑like)
```bash
# Sum bytes by host from access log
awk '{bytes[$1]+=$10} END{for(h in bytes) printf "%s %d\n", h, bytes[h]}' access.log
```
➡️ `$1` is host/IP, `$10` is bytes. We store in an associative array `bytes[]`.

```bash
# Count requests per status code, sorted by highest count
awk '{c[$9]++} END{for(k in c) print k, c[k]}' access.log | sort -k2 -nr
```
➡️ `$9` is status code (e.g. 200, 404). Each code increments its counter.

---

## 4) Multi‑file processing & joins
```bash
# Lines in file B not in file A
awk 'NR==FNR{seen[$0]; next} !($0 in seen)' A.txt B.txt
```
➡️ First file (A) loads all lines into `seen[]`. Second file (B) prints only lines not in `seen[]`.

```bash
# Join two files on ID (col1)
awk 'NR==FNR{map[$1]=$2; next} {print $0, map[$1]}' ref.tsv data.tsv
```
➡️ Loads `ref.tsv` into a map, then enriches rows of `data.tsv` with matching values.

---

## 5) Handling tricky CSV/TSV
```bash
# Properly parse quoted/unquoted fields (GNU awk FPAT)
awk 'BEGIN{FPAT="([^,]*)|\"([^\"]*)\""} {print $2}' data.csv
```
➡️ `FPAT` defines what counts as a "field". Here, fields can be plain text or quoted.

---

## 6) Time helpers
```bash
# Add timestamp before each log line
awk 'BEGIN{t=strftime("%Y-%m-%d %H:%M:%S")} {print t, $0}' app.log
```
➡️ `strftime()` gives formatted time. Useful for tagging logs.

---

## 7) Extracting from logs
```bash
# Top IP addresses in access log
awk '{print $1}' access.log | sort | uniq -c | sort -nr | head
```
➡️ `$1` is IP. `uniq -c` counts, `sort -nr` shows top IPs.

```bash
# Average response time per endpoint (path=$7, time=$10)
awk '{t[$7]+=$10; n[$7]++} END{for(p in t) printf "%8.2f  %s\n", t[p]/n[p], p}' access.log | sort -nr
```
➡️ For each endpoint, accumulate total time and count, then divide.

---

## 8) Control flow & functions
```bash
# Custom function to calculate % errors per endpoint
awk 'function pct(x,y){return y?100*x/y:0} $9>=500{err[$7]++} {tot[$7]++} END{for(p in tot) printf "%6.2f%% %s\n", pct(err[p],tot[p]), p}' access.log
```
➡️ Defines `pct()` function. Tracks total requests vs errors (5xx) per endpoint.

---

## 9) Interacting with shell & files
```bash
# Continuously monitor a log and print timestamped errors
tail -F app.log | awk '/ERROR/{print strftime("%F %T"), $0}'
```
➡️ Real-time monitoring with `tail -F` + `awk`.

---

## 10) Handy one‑liners
```bash
# Show numbered headers of CSV
awk -F, 'NR==1{for(i=1;i<=NF;i++) printf "%2d: %s\n", i,$i}' data.csv
```
➡️ Useful when you don’t know which column has what data.

```bash
# Filter rows by date range (ISO format in field 1)
awk '$1>="2025-09-01" && $1<="2025-09-29"' events.log
```
➡️ Straightforward date comparison since ISO dates are lexicographically ordered.

---

## Beginner Tips
- Always test with small input (`head -20 file`).
- Print debug info: `awk '{print NR, NF, $0}' file`.
- Use `-F` to correctly split fields (comma, tab, pipe).
- Combine with `sort`, `uniq`, and `grep` for powerful pipelines.

---

✅ With these explanations, you can understand **what each snippet does, why it works, and how to adapt it** to your data or logs.



---

## How `awk` Works — Visual Flow

```
                ┌───────────────┐
Input Stream →  │ Read a record │  (default: one line)
                └───────┬───────┘
                        │ sets built‑ins
                        │ NR (global line #)
                        │ FNR (file line #)
                        │ NF (# fields)
                        │ $0 (whole line)
                        │ $1..$NF (fields)
                        ▼
                ┌──────────────────────┐
                │  Pattern matched?   │  e.g., /ERROR/, $3>100, cond && cond
                └─────────┬───────────┘
            yes ─────────▶│{ Action } │→ print/aggregate/modify
                no  ──────┴───────────┘  (do nothing if no pattern match)
                        ▲
                        │
                Repeat for next record
```

### Where `BEGIN` and `END` fit
```
BEGIN { setup once }  → runs before reading any input
{ pattern { action } } → runs for each record (line)
END   { summarize }    → runs after all input is processed
```

### Micro‑Walkthrough
**Goal:** Average response time per endpoint from an access log.
```
BEGIN { FS=" " }           # split by spaces
{ t[$7] += $10; n[$7]++ }  # per line: add time, count hits
END {
  for (p in t) printf "%8.2f  %s
", t[p]/n[p], p
}
```
Flow:
1) Read line → split into fields `$1..$NF`.
2) Check (implicit true) pattern: no filter, so action runs on every line.
3) Update arrays `t[]` and `n[]` for key `$7` (the path).
4) After last line, `END` prints averages.

### Common Patterns at a Glance
```
/regex/ { ... }           # whole-line regex match
$2 ~ /foo/ { ... }        # field matches regex
$3 > 100 { ... }          # numeric filter
($9>=500)&&/api/ { ... }  # combine conditions
1                         # always-true (print by default)
```

### Execution Model (Mental Model)
```
Setup → Stream → Match → Act → Repeat → Summarize
```

> Tip: When debugging, sprinkle temporary prints:
> `{ print "DBG", NR, $1 > "/dev/stderr" }` then remove once correct.

