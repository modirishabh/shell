# Advanced `sed` Cheatsheet (DevOps & Text Processing, Beginner-Friendly)

This is a practical guide to using `sed` (Stream Editor) for one-liners and scripts, with explanations for beginners.

---

## Quick Basics
- `sed` processes **text streams** line by line.
- Default behavior: print each processed line.
- Structure: `sed 's/pattern/replacement/flags' file`
- Use regex (basic by default; `-E` for extended).
- Addressing lines:
  - `N` → line number.
  - `/regex/` → matching lines.
  - `start,end` → range.

---

## 1) Simple Substitution
```bash
# Replace first occurrence of foo with bar
sed 's/foo/bar/' file

# Replace all occurrences (global)
sed 's/foo/bar/g' file

# Replace only on line 3
sed '3s/foo/bar/g' file
```
➡️ `s` = substitute, `/g` = global (all matches per line).

---

## 2) Editing in Place
```bash
# Replace inplace (GNU sed)
sed -i 's/foo/bar/g' file

# With backup of original
sed -i.bak 's/foo/bar/g' file
```
➡️ `-i` applies changes directly to the file.

---

## 3) Line Selection and Deletion
```bash
# Print only line 5
sed -n '5p' file

# Print lines 10–20
sed -n '10,20p' file

# Delete first 2 lines
sed '1,2d' file

# Delete lines matching ERROR
sed '/ERROR/d' logfile
```
➡️ `-n` suppresses default printing; `p` prints explicitly.

---

## 4) Insert and Append
```bash
# Insert line before line 3
sed '3i\\
NEW LINE' file

# Append line after line 3
sed '3a\\
ADDED LINE' file

# Replace line 5 completely
sed '5c\\
This is the new line' file
```
➡️ `i` = insert before, `a` = append after, `c` = change whole line.

---

## 5) Multiple Commands
```bash
# Run multiple edits
sed -e 's/foo/bar/g' -e '/DEBUG/d' file

# Or use script file
sed -f edits.sed file
```
➡️ `-e` allows multiple commands inline.

---

## 6) Addressing by Regex
```bash
# Replace only on lines matching regex
sed '/^ERROR/ s/FAIL/PASS/' file

# Change tabs to commas on lines with keyword
sed '/KEY/ s/\t/,/g' data.txt
```
➡️ Combines regex matching with substitutions.

---

## 7) Working with Capture Groups
```bash
# Swap first two words on each line
sed -E 's/(\w+) (\w+)/\2 \1/' file

# Surround numbers with brackets
sed -E 's/([0-9]+)/[\1]/g' file
```
➡️ Parentheses capture, `\1`, `\2` reference groups.

---

## 8) Dealing with Multiple Lines
```bash
# Join two lines together
sed 'N; s/\n/ /' file

# Delete empty lines
sed '/^$/d' file

# Remove leading/trailing blank lines
sed '/./,$!d' file      # leading
sed ':a; /\n$/{$d;N;ba}' file   # trailing
```
➡️ `N` appends next line into pattern space.

---

## 9) Common Text Cleanup
```bash
# Remove leading spaces
sed 's/^ *//' file

# Remove trailing spaces
sed 's/ *$//' file

# Collapse multiple spaces → single
sed 's/  */ /g' file
```

---

## 10) Inserting File Content
```bash
# Insert content of another file before line 5
sed '5r other.txt' file

# Append content after a match
sed '/pattern/ r other.txt' file
```
➡️ `r` = read file content.

---

## 11) Debugging Tricks
```bash
# Show line numbers
sed = file | sed 'N; s/\n/ /'

# Highlight matched text
sed 's/pattern/[&]/g' file
```
➡️ `&` represents the matched text.

---

## 12) Advanced One-Liners
```bash
# Remove duplicate lines (keep first)
sed '$!N; /^(.*)\n\1$/!P; D' file

# Extract only email addresses
sed -n -E 's/.*([[:alnum:]_.-]+@[[:alnum:]_.-]+).*/\1/p' file

# Replace IPs with [IP]
sed -E 's/[0-9]{1,3}(\.[0-9]{1,3}){3}/[IP]/g' file
```

---

## Visual Flow of `sed`

```
Input Line → Pattern Space → Apply Command(s) → Output

BEGIN (optional setup)
  ↓
For each line:
  - Load line into pattern space
  - Match address (line # or regex)
  - Apply command (s///, d, a, i, etc.)
  - Print result (unless -n used)
END (cleanup)
```

---

## Beginner Tips
- Always test with `sed -n '1,10p'` to preview small portions.
- Use backups when editing files with `-i`.
- Remember: `sed` regex is slightly different from `grep` (escape groups unless `-E`).
- Combine with pipelines: `grep ERROR log | sed 's/.*ERROR: //'`.

---

✅ With these annotated examples, you can move from simple substitutions to multi-command scripts confidently.

