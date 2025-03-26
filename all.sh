#!/bin/bash
operation=$1

if [ $# -ne 1 ]; then
    echo "kindly provide augument add | sub | mul"
    exit 1
fi        
echo "Enter the first value:"
read a

if [ -z $a ]; then 
    echo "enter a valid first number"
    exit 1
fi

echo "Enter the second Number"
read b

if [ -z $b ]; then
    echo "enter the second valid number":
    exit 1
fi

 
case $operation in 
 "add") 
 echo "Adding numbers" 
 value=`expr $a + $b`  
 echo "$value"
 ;;
 "sub") 
 echo "Subtracting numbers" 
 value=`expr $a - $b`
 echo $value ;;
 "mul") 
 echo "multiply numbers" 
 value=`expr $a \* $b` 
 echo $value ;;
 *) echo "kindly provide augume nt" ;;
esac  