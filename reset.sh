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

echo "[*] Doxycannon Profile Switcher"

# Check that configs exists and contains OVPN files
profiles=(`find configs/ -maxdepth 1 -name "*.ovpn"`)
if [ ${#profiles[@]} -gt 0 ]
then
	# Modify OVPN configs per https://github.com/audibleblink/doxycannon/issues/14
	echo "[*] OpenVPN Configuration Files Found."
	# Perform check for auth.txt in VPN folder
		if [ ! -f "VPN/auth.txt" ]; then
			echo "[!] EXIT: No auth.txt file found for VPN authentication!"
			echo "[*] Create auth.txt in the VPN folder with two lines, containing your username and password."
			exit 1
		else
			: # Do nothing
		fi
	sed -i 's/up \/etc\/openvpn\/update-resolv-conf/up \/etc\/openvpn\/up.sh/g' configs/*.ovpn
        sed -i 's/down \/etc\/openvpn\/update-resolv-conf/down \/etc\/openvpn\/down.sh/g' configs/*.ovpn
	sed -i '/.*auth-user-pass*/c\auth-user-pass auth.txt' configs/*.ovpn
        : # Do nothing else if the file(s) actually exist and have been successfully modified.
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

python=$(which python3)
if [ $python = "" ]; then
	echo "[!] EXIT: Python3 installation not found! Set the path to the executable directly in this script."
	exit 1
else
	:
fi

# Request user input
read -p "[*] Enter the number of profiles you want to use: " n
read -p "[*] Enter Country Code (e.g. US): " c

# Arm the cannon
echo "[*] Bringing down the cannon..."; $python ./doxycannon.py --down
echo "[*] Removing current VPN profiles."; rm -r VPN/*.ovpn > /dev/null 2>&1
echo "[*] Copying new profiles."; for i in $(ls configs/ | sort -R | grep "$c" | tail -n $n); do echo "[*] Copying random profile: $i"; cp configs/$i VPN/$i; done; echo "[*] Profiles replaced."
echo "[*] Building new configuration..."; $python ./doxycannon.py --build
echo "[*] Ready, Aim, Fire!"; $python ./doxycannon.py --up
$python ./doxycannon.py --single
