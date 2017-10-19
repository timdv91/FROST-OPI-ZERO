Scripts are used to automate temperature loggin using an MAX31855 + thermocouple on the Orange Pi Zero board.
Usage:
- Place the scripts on the OPI board at the folowing path (as root): /home/FROST/scripts/*
- Add a new user admin, and add this user to the sudoers file. 
- Extract the configuration files as admin user on the following path: /home/FROST/*
- Use crontab (as root) to run the scripts automaticly, use @reboot on all scripts except the script called sendMail.sh. Don't forget to add '&' at the end of each line! This prevents hanging on bootup.
- Use crontab to lauch the sendMail.sh script at a wished interval. For example each 5 minutes.
- Reboot the system.

You can now use the FROST-configManager software to configurate all settings (using GUI) over the network.