#!/bin/bash 

a=0
while [ $a -lt 10 ]
do
    echo "a=$a"
    if [ $a -eq 5 ]; then
        echo "coming out of loop"
        break
    fi    
    a=`expr $a + 1`
done
echo "----EOS-----"     