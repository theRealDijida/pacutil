#!/bin/bash

set -e

export LC_ALL="en_US.UTF-8"

binary_url="https://github.com/PACGlobalOfficial/PAC/releases/download/v0.15-db9dd1c55/pacglobal-v0.15-db9dd1c55-lin64.tgz"
file_name="pacglobal-v0.15-db9dd1c55-lin64"
extension=".tgz"



echo ""
echo "Stopping the pacg service"
systemctl stop pacg.service
echo "The pacg service stopped"
sleep 3

echo ""
echo "###############################"
echo "#      removing files and copying config      #"
echo "###############################"
echo ""
mv .PACGlobal/wallet.dat .
mv .PACGlobal/pacglobal.conf .
rm *.sh*
rm pacg*.t*
rm -R PACGlobal/
rm -R .PACGlobal/*
mv wallet.dat .PACGlobal/
mv pacglobal.conf .PACGlobal/


echo ""
echo "###############################"
echo "#      Get/Setup binaries     #"
echo "###############################"
echo ""
sleep 3
wget $binary_url
if test -e "$file_name$extension"; then
echo ""
echo "Unpacking PACGlobal distribution"
sleep 3
	tar -xzvf $file_name$extension
	rm -r $file_name$extension
	rm -r -f PACGlobal
	mv -v $file_name PACGlobal
	cd PACGlobal
	chmod +x pacglobald
	chmod +x pacglobal-cli
	echo "Binaries were saved to: /root/PACGlobal"
else
	echo "There was a problem downloading the binaries, please try running the script again."
	exit -1
fi
echo ""
echo "Starting the pacg service"
systemctl start pacg.service
echo "The pacg service started"

echo ""
echo "###############################"
echo "#      Running the wallet     #"
echo "###############################"
echo ""
echo "Please wait for 10 seconds!"
cd ~/PACGlobal
sleep 10

is_pac_running=`ps ax | grep -v grep | grep pacglobald | wc -l`
if [ $is_pac_running -eq 0 ]; then
	echo "The daemon is not running or there is an issue, please restart the daemon!"
	exit
fi

cd ~/PACGlobal
./pacglobald -version
./pacglobal-cli getinfo

echo ""
echo "Your masternode / hot wallet has been updated!"
