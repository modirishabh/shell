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

# SED (Stream Editor) sed command will r

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

# SED Command Cheat Sheet

---

## Syntax

The basic syntax for using the `sed` command in Linux:

```bash
sed [OPTIONS] 'COMMAND' [INPUTFILE...]
OPTIONS: Optional flags that modify the behavior of sed.

COMMAND: The command or sequence of commands to execute.

INPUTFILE: One or more files to be processed.

Commonly Used Options
Option	Description
-i	Edit the file in-place (overwrite).
-n	Suppress automatic printing of lines.
-e	Allows multiple commands.
-f	Reads sed commands from a file.
-r	Use extended regular expressions.

Practical Examples
Consider an input file (geekfile.txt):

pgsql
Copy code
unix is great os. unix is opensource. unix is free os.
learn operating system.
unix linux which one you choose.
unix is easy to learn.unix is a multiuser os.Learn unix .unix is a powerful.
1. Replace (Substitute) String
bash
Copy code
sed 's/unix/linux/' geekfile.txt
Output:

pgsql
Copy code
linux is great os. unix is opensource. unix is free os.
learn operating system.
linux linux which one you choose.
linux is easy to learn.unix is a multiuser os.Learn unix .unix is a powerful.
2. Replace nth Occurrence
bash
Copy code
sed 's/unix/linux/2' geekfile.txt
Replaces the second occurrence of unix per line.

3. Replace All Occurrences in a Line
bash
Copy code
sed 's/unix/linux/g' geekfile.txt
4. Replace From nth to All
bash
Copy code
sed 's/unix/linux/3g' geekfile.txt
Replaces unix from the 3rd occurrence onward.

5. Parenthesize First Character of Each Word
bash
Copy code
echo "Welcome To The Geek Stuff" | sed 's/\(\b[A-Z]\)/(\1)/g'
Output:

scss
Copy code
(W)elcome (T)o (T)he (G)eek (S)tuff
6. Replace on Specific Line
bash
Copy code
sed '3 s/unix/linux/' geekfile.txt
Replaces only on line 3.

7. Duplicate Replaced Lines (/p flag)
bash
Copy code
sed 's/unix/linux/p' geekfile.txt
8. Print Only Replaced Lines
bash
Copy code
sed -n 's/unix/linux/p' geekfile.txt
9. Replace on a Range of Lines
bash
Copy code
sed '1,3 s/unix/linux/' geekfile.txt
sed '2,$ s/unix/linux/' geekfile.txt
10. Delete Lines
Delete line n:

bash
Copy code
sed '5d' filename.txt
Delete last line:

bash
Copy code
sed '$d' filename.txt
Delete lines x to y:

bash
Copy code
sed '3,6d' filename.txt
Delete nth to last:

bash
Copy code
sed '12,$d' filename.txt
Delete lines matching a pattern:

bash
Copy code
sed '/abc/d' filename.txt
Advanced Examples
1. Regular Expressions
bash
Copy code
sed -r 's/\bu\w+/Linux/g' geekfile.txt
Matches words beginning with u and replaces with Linux.

2. Insert Text
bash
Copy code
sed '3i\new text' filename   # Insert before line 3
sed '3a\new text' filename   # Insert after line 3
Best Practices
Always back up files before using -i.

Test on a sample file first.

Be cautious with extended regex.

Conclusion
The sed command is a powerful, flexible stream editor for text processing in Linux/Unix. It’s essential for developers, sysadmins, and automation scripts, allowing fast edits, replacements, and transformations directly from the command line







# GREP

Example: Search for processes and extract the PID
ps -aux | grep ubuntu | awk '{print $2}'

# 📌 Notes

# AWK is best for structured/tabular data (CSV/TSV/logs with fields).

# SED is best for inline editing and transformations.

# GREP is best for searching/filtering text quickly.
