# Bash Commands for Automation Scripts

This guide lists commonly used **bash commands** that are frequently leveraged in automation scripts, DevOps workflows, and system administration tasks.

---

## 1. File and Directory Management
```bash
ls -l              # List files in long format
pwd                # Print working directory
cd /path/to/dir    # Change directory
mkdir -p logs      # Create directory (recursively)
rm -rf /tmp/test   # Remove files/directories forcefully
cp -r src/ dest/   # Copy directory recursively
mv file1 file2     # Move or rename a file

## 2. Text Processing
cat file.txt                   # Show file contents
grep "pattern" file.txt        # Search text in a file
awk '{print $1, $2}' file.txt  # Print specific columns
sed -i 's/old/new/g' file.txt  # Replace text inline
sort file.txt | uniq -c        # Sort and count unique lines

## 3. System and Process Control
ps -ef | grep service    # Check running processes
kill -9 <pid>            # Kill a process
systemctl restart nginx  # Restart a service
df -h                    # Show disk usage
free -m                  # Show memory usage
uptime                   # Show system load and uptime

## 4. Loops and Conditionals
# For loop over files
for f in *.log; do
  echo "Processing $f"
done

# If-Else conditional
if [[ -z "$VAR" ]]; then
  echo "VAR is empty"
else
  echo "VAR is set"
fi

## 5. Variables and Substitution
NAME="Rishabh"
echo "Hello $NAME"

DATE=$(date +%F)
echo "Today is $DATE"

## 6. Networking
curl -s http://example.com    # Fetch data from URL
wget http://example.com/file  # Download a file
ping -c 4 google.com          # Check connectivity
nc -zv host 22                # Check if port 22 is open

8. Git Commands for Automation

git clone https://github.com/org/repo.git   # Clone repo
git pull origin main                        # Update code
git checkout feature-branch                 # Switch branch
git log -1 --pretty=format:"%h - %s"        # Show last commit

## 10. Exporting Environment Variables

set -e   # exit immediately if a command fails
set -u   # treat unset variables as an error
set -o pipefail  # catch errors in pipelines

trap 'echo "Error at line $LINENO"' ERR

set -euo pipefail   # Fail fast on errors and undefined vars
trap 'echo "Error at line $LINENO"' ERR

## 10. Exporting Environment Variables
export PATH=$PATH:/opt/custom/bin
source ~/.bashrc

## Example Automation Script

#!/bin/bash
set -euo pipefail

LOGFILE="/tmp/deploy.log"
echo "Starting deployment at $(date)" | tee -a $LOGFILE

apt-get update && apt-get upgrade -y     # Update packages
git clone https://github.com/example/app.git /opt/app  # Pull code
systemctl restart app.service            # Restart service

echo "Deployment completed at $(date)" | tee -a $LOGFILE

