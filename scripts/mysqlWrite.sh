#!/bin/sh

#wait little longer at boot:
sleep 60 #wait a minute longer.

while [ 0 -eq 0 ]
do

	#Load the mysql configuration file, and split it into variables:
	mysqlConfig="$(cat /home/FROST/FROST_MySQL.conf)"
	sqlDisabled=$(echo $mysqlConfig | cut -d' ' -f1) #split at the ' ' char
	sqlIP=$(echo $mysqlConfig | cut -d' ' -f2) #split at the ' ' char
	sqlUsername=$(echo $mysqlConfig | cut -d' ' -f3) #split at the ' ' char
	sqlPassword=$(echo $mysqlConfig | cut -d' ' -f4) #split at the ' ' char
	sqlDBName=$(echo $mysqlConfig | cut -d' ' -f5) #split at the ' ' char
	sqlTableName=$(echo $mysqlConfig | cut -d' ' -f6) #split at the ' ' char

	#Only if mysql mode is enabled by user.
	if [ "$sqlDisabled" = "False" ]; then
		echo "Mysql is enabled by configfile."

		#create new table if table doesn't exist:
		fb=$(echo "SHOW TABLES LIKE '$sqlTableName' " | mysql -h$sqlIP -u$sqlUsername $sqlDBName -p$sqlPassword)
		returnLength=$(echo -n $fb | wc -c)
		if [ $returnLength -eq 0 ]; then
			echo "creating new table $sqlTableName"
			fb=$(echo "CREATE TABLE $sqlTableName (alarmState VARCHAR(3), tcTemp VARCHAR(10), inTemp VARCHAR(10), errorBit0 VARCHAR(2), errorBit1 VARCHAR(5), time  TIMESTAMP DEFAULT CURRENT_TIMESTAMP)" | mysql -h$sqlIP -u$sqlUsername $sqlDBName -p$sqlPassword)
		fi

		#load latest alarm and temp from tmp files:
		latestAlarmSocket="$(cat /home/FROST/latestAlarmSocket.tmp)"
		alarmSocketPercentage=$(echo $latestAlarmSocket | cut -d' ' -f1) #split at the ' ' char

		latestTemp="$(cat /home/FROST/latestTemp.tmp)"
		tcTemp=$(echo $latestTemp | cut -d' ' -f1) #split at the ' ' char
		errorBit0=$(echo $latestTemp | cut -d' ' -f2) #split at the ' ' char
		inTemp=$(echo $latestTemp | cut -d' ' -f3) #split at the ' ' char
		errorBit1=$(echo $latestTemp | cut -d' ' -f4) #split at the ' ' char

		#add data to database:
		fb=$(echo "INSERT INTO $sqlTableName (alarmState,tcTemp,inTemp,errorBit0,errorBit1) VALUES ('$alarmSocketPercentage','$tcTemp','$inTemp','$errorBit0','$errorBit1')" | mysql -h$sqlIP -u$sqlUsername $sqlDBName -p$sqlPassword)

		echo "insert to mysql db = done"
	
	else
		echo "Mysql is disabled in config."
	fi
	
	#wait before next run:
	sleep "$(cat /home/FROST/FROST_MeasureInterval.conf)"

done