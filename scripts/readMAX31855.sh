#!/bin/sh

#gpio read gives wrong results when ecexuted to short after bootup:
sleep 60 #wait a minute longer.

while [ 0 -eq 0 ]
do
	#Set SPI clock frequency here:
	SPIfrequency=5000

	# some public vars:
	bit=0
	byte=""
	printData=""
	a=0
	tcTempIsNegative=0 #False
	
	# set input output mode of gpio pins:
	gpio mode 9 out #3.3V vcc output
	gpio mode 0 in # DO / MISO
	gpio mode 2 out # CS
	gpio mode 3 out # CLK

	#power on the MAX31855:
	gpio write 9 1

	# set CS high for 100ms (just to be sure!) before setting it low:
	gpio write 2 1
	sleep 0.1
	gpio write 2 0

	# Recalc frequency to seconds:
	SPIdelay=`echo "scale = 20 ; 1 / $SPIfrequency / 2" | bc`
	#echo $SPIdelay

	# loop 31 times (MAX31855 has 31 bits)
	while [ $a -lt 32 ]
	do
	   gpio write 3 1	#set clk high.
	   
	   sleep $SPIdelay		#wait a little to give the MAX31855 some time.
	   bit=$(gpio read 0)	#read the value on MISO pin.
	   sleep $SPIdelay	#wait a little to give the OPIzero some time.
	  
	   #Measure negative temperatures on thermocouple:
	   #===========================================================================	   
	   #Detect sign bit (first bit to be read):
	   if [ $a -eq 0 ] && [ $bit -eq 1 ]; then
			tcTempIsNegative=1 #set negative flag true
	   fi

	   # do a bitflip on the TC bits:
	   if [ $tcTempIsNegative -eq 1 ] && [ $a -lt `expr 31 - 20` ]; then	   
			if [ $bit -eq 0 ]; then
				bit=1
			else	
				bit=0
			fi
	   fi	   
	   #===========================================================================
	   
	   # store data:
	   byte=$byte$bit	#add the newly read value to the byte var.
	   gpio write 3 0	#set clk low.
	   
	   
	   #Byte var is not realy a byta, it contains multiple values. Split some values where usefull with ':'
	   if [ $a -eq `expr 31 - 4` ] || [ $a -eq `expr 31 - 8` ]|| [ $a -eq `expr 31 - 16` ] || [ $a -eq `expr 31 - 18` ] || [ $a -eq `expr 31 - 20` ]; then
		 byte="$byte:"   
	   fi
	   
	   #increase the counter with 1:
	   a=`expr $a + 1`
	done

	#set the CS back high.
	gpio write 0 1

	#power off the MAX31855:
	gpio write 9 0

	#split the bits on ':' to recalculate to temps:
	i=0
	dataArr=$(echo $byte | tr ":" "\n")
	for bitSplited in $dataArr
	do
		if  [ $i -eq 0 ] && [ $tcTempIsNegative -eq 1 ]; then #add a - sign in front of negative tc values, also fix 20% offset on negative values:
			tcValueOffsetFix="$printData $(echo "ibase=2;obase=A;$bitSplited"|bc)" # convert binary data to decimal.
			buffer=`echo "$tcValueOffsetFix/5" | bc` # get the 20% offset on negative values by deviding temperature by 5.
			tcValueOffsetFix=`expr $tcValueOffsetFix + $buffer` # add the offset value to the measured value to compensate.
			printData="-$tcValueOffsetFix" # add a '-' sign in front of the data.
		elif [ $i -eq 1 ]; then #Digits after comma for thermocouple temp:
			controlVar=$(echo "ibase=2;obase=A;$bitSplited"|bc)		
			controlVar=`echo "$controlVar * 0.25" | bc`		
			if [ $bitSplited -ne "00" ]; then
				printData=$printData$controlVar
			fi		
		elif [ $i -eq 4 ]; then #Digits after comma for interal temp:
			controlVar=$(echo "ibase=2;obase=A;$bitSplited"|bc)
			controlVar=`echo "$controlVar * 0.0625" | bc`	
			if [ $bitSplited -ne "0000" ]; then
				printData=$printData$controlVar
			fi	
		else
			printData="$printData $(echo "ibase=2;obase=A;$bitSplited"|bc)"
		fi
		#increase the counter with 1:
	   i=`expr $i + 1`
	done	
	
	#echo $printData #outputs the temps
	dateTimeNOW=$(date +"%T %d-%m-%Y")
	echo "$printData $dateTimeNOW" >> /home/FROST/tempLog.log
	echo "$printData $dateTimeNOW" > /home/FROST/latestTemp.tmp
	
	#debug prints:
	#echo $printData
	#echo $byte

	#wait before next run:
	sleep "$(cat /home/FROST/FROST_MeasureInterval.conf)"
done
