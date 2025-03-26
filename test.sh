#!/bin/bash

#export keyword=naughty

#echo "rishabh is $keyword"

#echo "what is \$keyword : $keyword"


#echo "$keyword $keyword $keyword"

#a=40
#b=10
#c=15
#echo "c=$a d=$b \n"

#add=`expr $a + $b`
#echo "a + b : $add"

#sub=`expr $a - $b`
#echo "a-b : $sub"

#mul=`expr $a \* $b`
#echo "a * b : $mul"

#div=`expr $a / $b`
#echo "a/b : $div"

#mod=`expr $a % $b`
#echo "a%b : $mod"

#addi=`expr $a + $b + $c`

#avg=`expr $addi / 3`
#echo "avg a,b,c : $avg"

#if [ $a -eq $b ]; then
#  echo "a is equal to b"
#else
#  echo "else a and b are not equal"
#fi
#
#if [ $a -ne $b ]; then
#  echo "a and b are not equal"
#else
#  echo "else a and b are equal"
#fi
#
#echo "ye sab kya dekhna pad raha hai"
#
#if [ $a -gt $c ]; then
#  echo "a bda hai c se"
#else
#  echo	"else c bda hai a se"
#fi
#
#if [ $a -lt $c ]; then
#  echo "a chota hai c se"
#else
#  echo  "else c chota hai a se"
#fi
#
#if [ $a -ge $c ]; then
#  echo "a ya toh bda hai c se ya brabr hai"
#else
#  echo  "else c bda hai a se"
#fi

a="rishu"
b="rishabh"

if [  $a = $b ]; then
 echo "$a and $b are different"
else
  echo "$a and $b are same"
fi   

if [ -z $a ]; then
 echo "$a : a has some lengh"
else
  echo " $a : has no value"
fi     

if [ -n $a ]; then
 echo "$a : a has some value"
else
  echo " $a : a is null"
fi  
  

if [ $a ]; then
 echo "$a : a has some not empty"
else
  echo " $a : a is empty"
fi  
  
