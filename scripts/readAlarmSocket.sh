#!/bin/sh

#gpio read gives wrong results when ecexuted to short after bootup:
sleep 60 #wait a minute longer.

while [ 0 -eq 0 ]
do
	#global vars:
	readInputCount=20
	GpioDelay=0.1
	readCounter=0

	# set gpio pins:
	gpio mode 15 out
	gpio mode 24 in

	# preset gpio output:
	gpio write 15 1
	sleep 0.5
	# read the gpio input:
	a=0
	while [ $a -lt $readInputCount ]
	do
		#delay between measurements:
		sleep $GpioDelay

		bit=$(gpio read 24)	#read the value on MISO pin.
		#echo $bit	
		
		#add value to readCounter:
		readCounter=`expr $bit + $readCounter`
		
		#increase the counter with 1:
	   a=`expr $a + 1`
	done

	# poweroff the gpio output:
	gpio write 15 0

	# check percentage of success:
	successPerc=`echo "$readCounter * 100" | bc`	
	successPerc=`echo "$successPerc / $readInputCount" | bc`

	#echo $successPerc
	dateTimeNOW=$(date +"%T %d-%m-%Y")
	echo "$successPerc $dateTimeNOW" >> /home/FROST/alarmSocketLog.log
	echo "$successPerc $dateTimeNOW" > /home/FROST/latestAlarmSocket.tmp
	
	#wait before next run:
	sleep "$(cat /home/FROST/FROST_MeasureInterval.conf)"
	
done
