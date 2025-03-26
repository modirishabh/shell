#!/bin/bash


a=0
b=0

while [ $a -lt 5 ]
do
    b=1
    char="*"
    while [ $b -le $a ]
    do
        char="* $char"
        b=`expr $b + 1`
    done
    echo "$char"
    a=`expr $a + 1`
done
echo "----------"

until [ $a -lt 0 ]
do
    c=1
    char="*"
    while [ $c -lt $a ]
    do 
        char="* $char"
        c=`expr $c + 1`
    done
    
    echo "$char"
    a=`expr $a - 1`
done