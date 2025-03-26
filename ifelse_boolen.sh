#!/bin/bash

a=10
b=20

if [ $a -gt 5 -a $b -lt 15 ] 
then
    echo  "a is $a and b is $b : returns ture"
else [ $a -lt 5 -a $b -gt 15 ]
    echo "a is less then 5 and b is greate then 15 : return false"
    fi