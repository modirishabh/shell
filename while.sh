#!/bin/bash

# run the loop until the condtion becomes false i.e. print only true statement till it become false
set -vx
a=1 
while [ $a -le 9 ]
do
    echo "a=$a"
    a=`expr $a + 1`
done
echo "---- EOS --------"    