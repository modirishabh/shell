########### AWk Command requies formatted data like csv(comma saparedted values) tsv files ###############
#1 Print specific column, say column number 2
awk '{print $2}' file_name

#2 Apply filter on column sepcific value 'cmd'
awk '/cmd/ {print $2}' file_name

#3 Count letters
awk '/cmd/ {count++} END {print count}' file_name

#4 condition
awk '$3 >= "03:11:54" && $3 <= "04:00:43" {print $7}' file_name 

#5 print only 2 to 10 lines only
awk 'NR >= 2 && NR <= 10 {print}' file_name

########### SED(stream editor) for unformatted data, sed works on expression "//"
############## case 1 ##############################
#step1:
sed '//' file_name

#step2: print
sed '/cmd/p' file_name # here we want to print "cmd" here it is print all file

#step3:
sed -n '/cmd/p' file_name # here we -n delimit the value and p is to print only cmd contained  values.

######### case 2 Replace the values ###############

#step1:
sed '' file_name

#step2: 
sed '/cmd/ram/' file_name # here we want to replace cmd with ram

#step3:
sed 's/cmd/ram/g' file_name # g sands for global changes and s "sub change" as we taking small value from file


######### case 3 print the line number where cmd occurs ###############
sed -n -e '/Cleanup/=' app.log # n delimit the value and "=" show the line number

######### case 3 print the line number where cmd occurs and also print the raw ###############
sed -n -e '/Cleanup/=' -e app.log


######### case 2 Replace the values only for 10 lines ###############
sed '1,10 s/Cleanup/starting' app.log




######### grep ###########
ps -aux | grep ubuntu | awk {print $2}


