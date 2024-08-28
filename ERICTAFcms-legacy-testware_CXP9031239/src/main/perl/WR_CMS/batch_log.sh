#!/bin/ksh

LOG_DIR="/opt/ericsson/atoss/tas/WR_CMS/results/"

N_LOG_DIR=$1 #Time

N_LOG_TYPE=$2 #Type of batch(proxy or master)

N_LOG_TYPE_2=$3 #Batch ID number

#N_LOG_DIR="`date +%Y%m%d%H%M`"

NEW_LOG_DIR="$LOG_DIR""$N_LOG_TYPE""$N_LOG_TYPE_2""_""$N_LOG_DIR"

if [ ! -d $NEW_LOG_DIR ]
then
	mkdir -p "$NEW_LOG_DIR" 
fi

cd "$LOG_DIR"

ls *.log > "$LOG_DIR"log_temp.temp

for name in  `cat "$LOG_DIR"log_temp.temp`
do
        newstr="$(echo "$name" | sed "s/[^0-9]//g")"
	if [ $newstr -ge $N_LOG_DIR ]
        then
		mv $name $NEW_LOG_DIR
	fi
done

rm "$LOG_DIR"log_temp.temp
