# AWK, SED, and GREP Commands Reference

---

## AWK

> AWK works best with **formatted data** like CSV (comma-separated values) or TSV files.

### 1. Print a specific column (e.g., column number 2)
```bash
awk '{print $2}' file_name
```
### 2. Apply filter on a column with a specific value (e.g., cmd)
```
awk '/cmd/ {print $2}' file_name
```

## 3. Count lines containing a pattern
awk '/cmd/ {count++} END {print count}' file_name

## 4. Conditional filter (between two time ranges, print column 7)
awk '$3 >= "03:11:54" && $3 <= "04:00:43" {print $7}' file_name

## 5. Print only lines 2 to 10
awk 'NR >= 2 && NR <= 10 {print}' file_name

### 6. Frequency analysis of a column

sort – sorts the extracted column values alphabetically/numerically

uniq -c – collapses duplicate values and counts them

sort -nr – sorts by frequency, highest first

head -n 5 – shows the top 5 results

awk '{print $4}' dummy_log.csv | sort | uniq -c | sort -nr | head -n 5

# SED (Stream Editor)

Useful for working on unformatted text data, with expressions defined inside "//".

## Case 1: Printing lines

Step 1:

sed '//' file_name


Step 2: Print all lines containing cmd

sed '/cmd/p' file_name


Step 3: Print only lines containing cmd

sed -n '/cmd/p' file_name

## Case 2: Replacing values

Step 1:

sed '' file_name


Step 2: Replace cmd with ram (first occurrence in each line)

sed '/cmd/ram/' file_name


Step 3: Replace cmd with ram globally (all occurrences in each line)

sed 's/cmd/ram/g' file_name

## Case 3: Print line numbers

## Print line numbers where Cleanup occurs

sed -n -e '/Cleanup/=' app.log


## Print both line numbers and matching lines

sed -n -e '/Cleanup/=' -e app.log


## Replace only within first 10 lines

sed '1,10 s/Cleanup/starting/' app.log

# GREP

Example: Search for processes and extract the PID
ps -aux | grep ubuntu | awk '{print $2}'

# 📌 Notes

# AWK is best for structured/tabular data (CSV/TSV/logs with fields).

# SED is best for inline editing and transformations.

# GREP is best for searching/filtering text quickly.
