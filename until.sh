#!/bin/bash
# run the loop until the condtion becomes true i.e. print only false statement till it become true
a=10

until [ $a -lt 2 ]
do 
    echo "a=$a"
    a=`expr $a - 1`
done

echo "iinamika diika"