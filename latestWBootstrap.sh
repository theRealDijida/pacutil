#!/bin/bash
set -e
export LC_ALL="en_US.UTF-8"
binary_url="https://github.com/PACGlobalOfficial/PAC/releases/download/v0.15.2/pacglobal-v0.15.2-lin64.tgz"
file_name="pacglobal-v0.15.2-lin64"
extension=".tgz"
#Are the the needed paramters provided?
if [ "$binary_url" = "" ] || [ "$file_name" = "" ]; then
	echo ""
	echo "In order to run this script, you need to add two parameters: first one is the full file name of the wallet on the PAC Global Github, the second one is the full binary url leading to the file on the Github."
	echo "Please check PAC FAQ on the PAC Global website for further information or help!"
	echo ""
	exit
fi
#Is the daemon already running?
is_pac_running=`ps ax | grep -v grep | grep pacglobald | wc -l`
if [ $is_pac_running -eq 1 ]; then
	echo ""
	echo "A PACGlobal daemon is already running - this script is not to be used for upgrading!"
	echo "Please check PAC FAQ on the PAC Global website for further information or help!"
	echo ""
	exit
fi
echo ""
echo "#################################################"
echo "#   Welcome to the PACGlobal Masternode Setup   #"
echo "#################################################"
echo ""
echo "Running this script as root on Ubuntu 18.04 LTS or newer is highly recommended."
echo "Please note that this script will try to configure 6 GB of swap - the combined value of memory and swap should be at least 7 GB. Use the command 'free -h' to check the values (under 'Total')." 
echo ""
sleep 10
ipaddr="$(dig +short myip.opendns.com @resolver1.opendns.com)"
while [[ $ipaddr = '' ]] || [[ $ipaddr = ' ' ]]; do
	read -p 'Unable to find an external IP, please provide one: ' ipaddr
	sleep 2
done
read -p 'Please provide masternodeblsprivkey: ' mnkey
while [[ $mnkey = '' ]] || [[ $mnkey = ' ' ]]; do
	read -p 'You did not provide a masternodeblsprivkey, please provide one: ' mnkey
	sleep 2
done
echo ""
echo "###############################################################"
echo "#  Installing dependencies / Updating the operating system    #"
echo "###############################################################"
echo ""
sleep 2
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install ufw pwgen
echo ""
echo "###############################"
echo "#   Setting up the firewall   #"
echo "###############################"
echo ""
sleep 2
sudo ufw status
sudo ufw disable
sudo ufw allow ssh/tcp
sudo ufw limit ssh/tcp
sudo ufw allow 7112/tcp
sudo ufw logging on
sudo ufw --force enable
sudo ufw status
sudo iptables -A INPUT -p tcp --dport 7112 -j ACCEPT
echo ""
echo "Proceed with the setup of the swap file [y/n]?"
echo "(Defaults to 'y' in 5 seconds)"
set +e
read -t 5 cont
set -e
if [ "$cont" = "" ]; then
        cont=Y
fi
if [ $cont = 'y' ] || [ $cont = 'yes' ] || [ $cont = 'Y' ] || [ $cont = 'Yes' ]; then
		echo ""
		echo "###########################"
		echo "#   Setting up swapfile   #"
		echo "###########################"
		echo ""
		sudo swapoff -a
		sudo fallocate -l 6G /swapfile
		sudo chmod 600 /swapfile
		sudo mkswap /swapfile
		sudo swapon /swapfile
		echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
		sleep 2
    else
        echo ""
		echo "Warning: Swap was not setup as desired. Use free -h command to check how much memory / swap is available."
		sleep 5
fi
echo ""
echo "###############################"
echo "#      Get/Setup binaries     #"
echo "###############################"
echo ""
sleep 3
cd ~
set +e
wget $binary_url
wget https://utils.pacglobal.io/Bootstrap.tar.gz
set -e
if test -e "$file_name$extension"; then
echo "Unpacking PACGlobal distribution"
systemctl stop pacg.service || true
	tar -xzvf $file_name$extension
	rm -r $file_name$extension
	rm -r -f PACGlobal
	mv -v $file_name PACGlobal
	cd PACGlobal
	chmod +x pacglobald
	chmod +x pacglobal-cli
	echo "Binaries were saved to: /root/PACGlobal"
	echo ""
else
	echo ""
	echo "There was a problem downloading the binaries, please try running the script again."
	echo "Most likely are the parameters used to run the script wrong."
	echo "Please check PAC FAQ on the PAC Global website for further information or help!"
	echo ""
	exit -1
fi
echo "#################################"
echo "#     Configuring the wallet    #"
echo "#################################"
echo ""
echo "A .PACGlobal folder will be created, unless it already exists."
sleep 3
if [ -d ~/.PACGlobal ]; then
	if [ -e ~/.PACGlobal/pacglobal.conf ]; then
	read -p "The file pacglobal.conf already exists and will be replaced. Do you agree [y/n]?" cont
		if [ $cont = 'y' ] || [ $cont = 'yes' ] || [ $cont = 'Y' ] || [ $cont = 'Yes' ]; then
			sudo rm ~/.PACGlobal/pacglobal.conf
			touch ~/.PACGlobal/pacglobal.conf
			cd ~/.PACGlobal
		fi
	fi
else
	echo "Creating .PACGlobal dir"
	mkdir -p ~/.PACGlobal
	cd ~/.PACGlobal
	touch pacglobal.conf
fi
#The four commands below should not be needed!
#set +e
#wget -q https://github.com/PACGlobalOfficial/mn-scripts/blob/master/peers.dat?raw=true
#mv peers.dat?raw=true peers.dat
#set -e

echo "Configuring the pacglobal.conf"
echo "#----" > pacglobal.conf
echo "rpcuser=$(pwgen -s 16 1)" >> pacglobal.conf
echo "rpcpassword=$(pwgen -s 64 1)" >> pacglobal.conf
echo "rpcallowip=127.0.0.1" >> pacglobal.conf
echo "rpcport=7111" >> pacglobal.conf
echo "#----" >> pacglobal.conf
echo "listen=1" >> pacglobal.conf
echo "server=1" >> pacglobal.conf
echo "daemon=1" >> pacglobal.conf
echo "maxconnections=64" >> pacglobal.conf
echo "#----" >> pacglobal.conf
echo "masternode=1" >> pacglobal.conf
echo "masternodeblsprivkey=$mnkey" >> pacglobal.conf
echo "externalip=$ipaddr" >> pacglobal.conf
echo "#----" >> pacglobal.conf
echo "addnode=seed0.pacglobal.io" >> pacglobal.conf
echo "addnode=seed1.pacglobal.io" >> pacglobal.conf
echo "addnode=seed2.pacglobal.io" >> pacglobal.conf
echo "addnode=seed3.pacglobal.io" >> pacglobal.conf
echo "addnode=seed0.pacnode.net" >> pacglobal.conf
echo "addnode=seed1.pacnode.net" >> pacglobal.conf

echo "#######################################"
echo "#     Unpacking Bootstrap             #"
echo "#######################################"

cd ~
tar -xzvf Bootstrap.tar.gz -C ~/.PACGlobal
rm Bootstrap.tar.gz

echo ""
echo "#######################################"
echo "#      Creating systemctl service     #"
echo "#######################################"
echo ""
cat <<EOF > /etc/systemd/system/pacg.service
[Unit]
Description=PAC Global daemon
After=network.target
[Service]
User=root
Group=root
Type=forking
PIDFile=/root/.PACGlobal/pacglobal.pid
ExecStart=/root/PACGlobal/pacglobald -daemon -pid=/root/.PACGlobal/pacglobal.pid \
          -conf=/root/.PACGlobal/pacglobal.conf -datadir=/root/.PACGlobal/
ExecStop=-/root/PACGlobal/pacglobal-cli -conf=/root/.PACGlobal/pacglobal.conf \
          -datadir=/root/.PACGlobal/ stop
Restart=always
RestartSec=20s
PrivateTmp=true
TimeoutStopSec=7200s
TimeoutStartSec=30s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
#enable the service
systemctl enable pacg.service
echo "pacg.service enabled"
#start the service
systemctl start pacg.service
echo "pacg.service started"
echo ""
echo "###############################"
echo "#      Running the wallet     #"
echo "###############################"
echo ""
echo "Please wait for 10 seconds!"
echo ""
sleep 10
is_pac_running=`ps ax | grep -v grep | grep pacglobald | wc -l`
if [ $is_pac_running -eq 0 ]; then
	echo "The daemon is not running or there is an issue, please restart the daemon!"
	echo "Please check PAC FAQ on the PAC Global website for further information or help!"
	echo ""
	exit
fi
~/PACGlobal/pacglobal-cli mnsync status
echo ""
echo "Your masternode wallet on the server has been setup and will be ready when the synchronization is done!"
echo ""
echo "Please execute following commands to check the status of your masternode:"
echo "~/PACGlobal/pacglobal-cli -version"
echo "~/PACGlobal/pacglobal-cli getblockcount"
echo "~/PACGlobal/pacglobal-cli masternode status"
echo "~/PACGlobal/pacglobal-cli mnsync status"
echo ""
© 20
