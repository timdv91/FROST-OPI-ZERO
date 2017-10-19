Scripts are used to automate temperature loggin using an MAX31855 + thermocouple on the Orange Pi Zero board.
Usage:
- Place the scripts on the OPI board at the folowing path (as root): /home/FROST/scripts/*
- Add a new user admin, and add this user to the sudoers file. 
- Extract the configuration files as admin user on the following path: /home/FROST/*
- Use crontab (as root) to run the scripts automaticly, use @reboot on all scripts except the script called sendMail.sh. Don't forget to add '&' at the end of each line! This prevents hanging on bootup.
- Use crontab to lauch the sendMail.sh script at a wished interval. For example each 5 minutes.
- Reboot the system.

You can now use the FROST-configManager software to configurate all settings (using GUI) over the network.


MAX31855 hardware:
--> default pinout can be found in the readMAX31855.sh file:
	# set input output mode of gpio pins:
		gpio mode 9 out #3.3V vcc output
		gpio mode 0 in # DO / MISO
		gpio mode 2 out # CS
		gpio mode 3 out # CLK

AlarmSocket hardware:
--> default pinout for the alarmsocket kan be found in the readAlarmSocket.sh file:
	# set gpio pins:
		gpio mode 15 out
		gpio mode 24 in
	
--> wiringOP has to be installed before using gpio command!!!
--> wiringOP uses different PIN NUMMERS, use gpio readall to find them.