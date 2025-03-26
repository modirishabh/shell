#!/bin/bash

file=/home/rishabh/shell/test.sh

if [ -r $file ]; then
echo "$file has read permission"
else
echo "$file does't have read permission"
fi

if [ -w $file ]; then
echo "$file has write permission"
else
echo "$file does't have write permission"
fi

if [ -x $file ]; then
echo "$file has execute permission"
else
echo "$file does't have execute permission"
fi

if [ -s $file ]; then
echo "$file has some size"
else
echo "$file does't have size"
fi

if [ -e $file ]; then
echo "$file exist"
else
echo "$file does't exist"
fi
