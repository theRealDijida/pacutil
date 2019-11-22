#!/bin/bash

export LC_ALL=en_US.UTF-8
set -e
version="035d4df02"

echo 
echo "################################################"
echo "#                   Welcome   	             #"
echo "################################################"
echo 
echo "This script will update PAC Global to the latest version (${version})."
echo

find_pacglobal_data_dir()
{
    echo '*** Finding PAC Global data-dir'
	DATA_DIR="$HOME/.PACGlobal"
	if [ -e ./pacglobal.conf ] && [ -e ./peers.dat ] && [ -d chainstate ] && [ -d blocks ] && [ -d database ]; then
	    DATA_DIR='.';
	elif [ -e $HOME/.PACGlobal/pacglobal.conf ] ; then
	    DATA_DIR="$HOME/.paccoin" ;
	elif [ -e $HOME/.PACGlobal/pacglobal.conf ] ; then
	    DATA_DIR="$HOME/.PACGlobal" ;
	fi

    if [ -e $DATA_DIR ] ; then
    	cd $DATA_DIR
    	rm -f banlist.dat budget.dat debug.log peers.dat
    	cd
    fi

    CONF_PATH="$DATA_DIR/pacglobal.conf"
}

stop_pacglobal() {
	echo '*** Stopping any PAC Global daemon running'
    INSTALL_DIR=''
    is_pacg_enabled=0

    # Check if running with systemd
    if [ $(systemctl is-active pacg.service) == "active" ] ; then
    	is_pacg_enabled=1
    	sudo systemctl stop pacg.service
    # pacglobal-cli in PATH
    elif [ ! -z $(which pacglobal-cli 2>/dev/null) ] ; then
        INSTALL_DIR=$(readlink -f `which pacglobal-cli`)
        INSTALL_DIR=${INSTALL_DIR%%/pacglobal-cli*};
	# Check current directory
    elif [ -e ./pacglobal-cli ] ; then
        INSTALL_DIR='.' ;
	# check ~/PACGlobal directory
    elif [ -e $HOME/PACGlobal/pacglobal-cli ] ; then
        INSTALL_DIR="$HOME/PACGlobal" ;
    fi

    is_pac_running=`ps ax | grep -v grep | grep pacglobald | wc -l`
	if [ $is_pac_running -eq 1 ]; then
	    if [ ! -e $INSTALL_DIR/pacglobal-cli ]; then
	        killall -9 pacglobald 2>/dev/null
	    else
	    	$INSTALL_DIR/pacglobal-cli stop 2>&1 >/dev/null
	    fi
	fi

    INSTALL_DIR="$HOME/PACGlobal"
}

check_crete_swap()
{
	echo "*** Checking if a swapfile exist"
	is_swap_on_system=`swapon -s | wc -l`
	if [ $is_swap_on_system -lt 2 ]; then
		swap_size=1024
		echo "*** Swapfile not found, creating a ${swap_size}M swapfile."
		sudo dd if=/dev/zero of=/var/swapfile bs=1M count=$swap_size
		sudo chmod 600 /var/swapfile
		sudo mkswap /var/swapfile
		sudo sed -i.bak -e '/\/var\/swapfile/d' /etc/fstab
		echo /var/swapfile none swap defaults 0 0 | sudo tee -a /etc/fstab
		sudo swapon -a
		free -h
	fi
}

download_binaries()
{
	binary_url="https://github.com/PACGlobalOfficial/PAC/releases/download/${version}/pacglobal-${version}-legacylin64.tgz"
	
	tarball_name="pacglobal-${version}-legacylin64.tgz"
	
	
	mkdir -p $INSTALL_DIR
	cd $INSTALL_DIR

	if test -e "${tarball_name}"; then
		rm -r $tarball_name
	fi
	
	echo "*** Downloading $tarball_name"
	echo
	wget --no-check-certificate --show-progress -q $binary_url
	if test -e "${tarball_name}"; then
		echo '*** Unpacking PAC Global distribution'
		tar -xzf $tarball_name 2>/dev/null
		chmod +x pacglobald
		chmod +x pacglobal-cli
		echo "*** Binaries were saved to: $INSTALL_DIR"
		rm -r $tarball_name

		echo "*** Adding $INSTALL_DIR PATH to ~/.bash_aliases"
	    if [ ! -f ~/.bash_aliases ]; then touch ~/.bash_aliases ; fi
	    sed -i.bak -e '/pacglobal_env/d' ~/.bash_aliases
	    echo "export PATH=$INSTALL_DIR:\$PATH ; # pacglobal_env" >> ~/.bash_aliases
	    source ~/.bash_aliases
	else
		echo "There was a problem downloading the binaries, please try running again the script."
		exit -1
	fi

	if [ -e $HOME/pacglobald ]; then
		rm $HOME/pacglobald
		ln -s $INSTALL_DIR/pacglobald $HOME/pacglobald
	fi

	if [ -e $HOME/pacglobal-cli ]; then
		rm $HOME/pacglobal-cli
		ln -s $INSTALL_DIR/pacglobal-cli $HOME/pacglobal-cli
	fi

	if [ -e $HOME/pacglobal-qt ]; then
		rm $HOME/pacglobal-qt
		ln -s $INSTALL_DIR/pacglobal-qt $HOME/pacglobal-qt
	fi
}



backup_wallet()
{
	is_pac_running=`ps ax | grep -v grep | grep pacglobald | wc -l`
	if [ $is_pac_running -gt 0 ]; then
		echo "PAC Global process is still running, it's not safe to continue with the update, exiting."
		echo "Please stop the daemon with: './pacglobal-cli stop' or, if running through systemd: 'sudo systemctl stop pacg.service' , then run the script again."
		exit -1
	else
		currpath=$( pwd )
		echo "*** Backing up wallet.dat"
		backupsdir="pac_wallet_backups"
		mkdir -p $backupsdir
		backupfilename=wallet.dat.$(date +%F_%T)
		cp ~/.PACGlobal/wallet.dat "$currpath/$backupsdir/$backupfilename"
		echo "*** wallet.dat was saved to : $currpath/$backupsdir/$backupfilename"
	fi
}

run_systemd_service()
{
	echo "*** Starting the PAC Global service"

	#start the service
	systemctl start pacg.service
	echo "pacg service started"
	
	sleep 5
	echo
	echo "*** The PAC service succefully started!"
	echo
	systemctl status -n 0 --no-pager pacg.service
	echo
	pacglobal-cli getinfo
	
	echo 
	echo "==> PAC Updated!"
	echo "==> Remember to go to your cold wallet and start the masternode, cold wallet must also be on the latest version (${version})."
}

stop_paccoin
find_paccoin_data_dir
download_binaries
check_crete_swap
backup_wallet
run_systemd_service
