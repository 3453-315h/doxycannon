#!/bin/bash
#
# Name: reset.sh
# Auth: Frank Cass
# Date: 20190710
# Desc: Quickly change Proton OpenVPN configuration profiles and reset the docker containers.
# 	Useful when performing an external assessment and your IP is blacklisted.
#	The number of profiles you specify should not exceed the maximum number of connections allowed by your VPN provider.
#	Put all of your OVPN files in configs/ and the script will move the active ones to VPN/
#
#	Troubleshooting: May have to run inside a virutalenv.
#	Try:
#		pip install virtualenv
#		virtualenv env
#		source env/bin/activate
#
###

clear

echo "[*] $0: Doxycannon Profile Switcher"

# Check that configs exists and contains OVPN files
profiles=(`find configs/ -maxdepth 1 -name "*.ovpn"`)
if [ ${#profiles[@]} -gt 0 ]
then
        : # Do nothing if the file(s) actually exist.
else
         echo "[!] EXIT: No OpenVPN (.ovpn) files found in configs."
         exit 1
fi

# Check if Docker is running
if [ "$(systemctl is-active docker)" = "active" ]; then
	echo "[*] Docker appears to be running."
else
	echo "[!] EXIT: Docker is not running!"
	echo "[*] Try: service docker start"
	exit 1
fi

# Request user input
read -p "[*] Enter the number of profiles you want to use: " n
read -p "[*] Enter Country Code (e.g. US): " c

# Arm the cannon
echo "[*] Bringing down the cannon..."; ./doxycannon.py --down
echo "[*] Removing current VPN profiles."; rm -r VPN/*.ovpn > /dev/null 2>&1
echo "[*] Copying new profiles."; for i in $(ls configs/ | sort -R | grep "$c" | tail -n $n); do echo "[*] Copying random profile: $i"; cp configs/$i VPN/$i; done; echo "[*] Profiles replaced."
echo "[*] Building new configuration..."; ./doxycannon.py --build
echo "[*] Ready, Aim, Fire!"; ./doxycannon.py --up
./doxycannon.py --single
