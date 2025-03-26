#!/bin/bash
set -vx
a="1 2 4 5 6 7"

for c in $a
do 
    b=`expr $c % 2`
    if [ $b -eq 0 ]
    then
        echo "Number is an even number $c"
        continue
    fi   
    echo "nuber is odd"
    echo "--EOL--"
done

echo "--EOS--"


