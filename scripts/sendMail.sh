#!/bin/sh

#load config vars from config files:
#alarm socket:
alarmSocketData="$(cat /home/FROST/latestAlarmSocket.tmp)"
alarmSocketMinPercentage=75 #percentage that determense when signal is valid. Unchangable for enduser.

#temperature monitoring:
#==============================================================================================================
#prepare and load preset values in configuration: 
tempConfigFile="$(cat /home/FROST/FROST_TempRanges.conf)"
tcMinTemp=$(echo $tempConfigFile | cut -d':' -f1) #split at the ':' char
tcMaxTemp=$(echo $tempConfigFile | cut -d':' -f2)
interalTempMax=45 #Max allowd internal temperature inside the FROST system case. Unchangable for enduser.
#prepare and load latest measurement values from file:
dataLineTemps="$(cat /home/FROST/latestTemp.tmp)"
tcTemp=$(echo $dataLineTemps | cut -d' ' -f1)
errorBit0=$(echo $dataLineTemps | cut -d' ' -f2)
internalTemp=$(echo $dataLineTemps | cut -d' ' -f3)
errorBit1=$(echo $dataLineTemps | cut -d' ' -f4)
timeOfMeasurement=$(echo $dataLineTemps | cut -d' ' -f5)
dateOfMeasurement=$(echo $dataLineTemps | cut -d' ' -f6)

#mail variables:
deviceName="$(cat /home/FROST/FROST_DeviceName.conf)"
mailList="$(cat /home/FROST/FROST_mailList.conf)"

#line to test all vars:
#echo "$tcTemp | $errorBit0 | $internalTemp | $errorBit1 | $timeOfMeasurement | $dateOfMeasurement"

#Alarm socket monitoring below:
#==============================================================================================================
alarmSocketData=$(echo $alarmSocketData | cut -d' ' -f1)
if [ $alarmSocketData -lt $alarmSocketMinPercentage ]; then
	echo "send mail freezer in alarm! Perc: $alarmSocketData"
	mailContent="From: $deviceName"
	mailContent="$mailContent\nFrom: $deviceName"
	mailContent="$mailContent\nSubject: Freezer in alarm: $deviceName"
	mailContent="$mailContent\nThis freezer is in alarm. The temperature at this moment is: $tcTemp. The preset temperature values (min/max) are: ($tcMinTemp / $tcMaxTemp). As this warning is send early on. There is stil plenty of time to fix the issue."
	{
		echo $mailContent
	} | ssmtp $mailList
fi

#Temperature monitoring below:
#==============================================================================================================
#if tempsensor 'read error' has happend:
if [ $errorBit0 -ne 0 ] || [ $errorBit1 -ne 0 ]; then
	echo "MAX 31855 read error "
	mailContent="From: $deviceName"
	mailContent="$mailContent\nFrom: $deviceName"
	mailContent="$mailContent\nSubject: MAX31855 read error: $deviceName"
	mailContent="$mailContent\nMAX31855 read error. This error can be ignored if it doesn't happen to often. Could be bad thermocouple hardware. ERROR_CODE: $errorBit0-$errorBit1."
	{
		echo $mailContent
	} | ssmtp $mailList
	exit #no use checking temps as these are prety much corrupted.
fi

#if tc temp gets out of range:
tcTemp=${tcTemp%.*} #shell doesn't support floats or doubles, so remove the part behind comma.
if [ $tcTemp -lt $tcMinTemp ] || [ $tcTemp -gt $tcMaxTemp ]; then
	echo "Send mail, tc temp out of range $tcTemp"
	mailContent="From: $deviceName"
	mailContent="$mailContent\nFrom: $deviceName"
	mailContent="$mailContent\nSubject: Freezer temperature warning: $deviceName"
	mailContent="$mailContent\nThe freezer $deviceName temperature is out of range. This problem is urgent! The measured temperature is $tcTemp, the allowd temperatur range (min/max) is between ($tcMinTemp / $tcMaxTemp)"
	{
		echo $mailContent
	} | ssmtp $mailList
fi

#if internal temps gets to high:
internalTemp=${internalTemp%.*} #shell doesn't support floats or doubles, so remove the part behind comma.
if [ $internalTemp -gt $interalTempMax ]; then
	echo "internal case temp to high: $internalTemp"
	mailContent="From: $deviceName"
	mailContent="$mailContent\nFrom: $deviceName"
	mailContent="$mailContent\nSubject: Monitoring system CPU temperature warning: $deviceName"
	mailContent="$mailContent\nThis mail is not about the Freezer temperatures! The monitoring system on freezer $deviceName is running above recomended temperatures. The temperature inside the FROST case is now $internalTemp. The recomended maximum is $interalTempMax . Ignoring this warning often could shorten the lifespan of the FROST monitoring hardware."
	{ 
		echo $mailContent
	} | ssmtp $mailList
fi
