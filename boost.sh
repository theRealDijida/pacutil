#!/bin/bash

set -e

export LC_ALL="en_US.UTF-8"

version="current"
today=`date '+%Y_%m_%d__%H_%M_%S'`;
file_name="pacglobal_bootstrap_$version-$today.tar.gz"

echo ""
echo "##############################################################"
echo "#   Welcome to the PACGlobal bootstrap preparation script    #"
echo "##############################################################"
echo ""
echo "This script is to be ONLY used if the pacglobal-mn.sh script was used to install the PAC masternode version 0.14.x or newer and the masternode is still installed!
"
echo ""
sleep 3
if [ -e /root/.PACGlobal/pacglobal.conf ]; then
            sleep 1
	else
	    read -p "No files in /root/.PACGlobal detected. Are you sure you want to continue [y/n]?" cont
	    if [ $cont = 'n' ] || [ $cont = 'no' ] || [ $cont = 'N' ] || [ $cont = 'No' ]; then
		exit
            fi
fi
echo ""
echo "Stopping the pacg service"
systemctl stop pacg.service
echo "The pacg service stopped"
sleep 3

echo ""
echo "#####################################"
echo "#      Preparing bootstrap file     #"
echo "#####################################"
echo ""
sleep 3
cd ~ 
tar -czvf $file_name --exclude='wallet.dat' --exclude='pacglobal.conf' --exclude="/.PACGlobal/backups/" --exclude="debug.log" .PACGlobal
echo ""
echo "File is ready! It's name is $file_name"
sleep 3
echo ""
echo "Starting the pacg service"
systemctl start pacg.service
echo "The pacg service started"
echo ""
echo "###############################"
echo "#      Running the wallet     #"
echo "###############################"
echo ""
cd ~/PACGlobal
sleep 60
is_pac_running=`ps ax | grep -v grep | grep pacglobald | wc -l`
if [ $is_pac_running -eq 0 ]; then
	echo "The daemon is not running or there is an issue, please restart the daemon!"
	exit
fi
cd ~/PACGlobal
./pacglobal-cli getinfo
echo ""
echo "Your masternode is running again!"
