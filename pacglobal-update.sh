#!/bin/bash

export LC_ALL=en_US.UTF-8
set -e

version_hash="035d4df02"
version_num="140004"
protocol="70218"

echo 
echo "################################################"
echo "#             PAC Global Update   	     #"
echo "################################################"
echo
echo "Updating to version: ${version_num}"
echo

echo "Stopping PAC Global Service"

systemctl stop pacg.service



echo "Downloading binaries and unpacking"

wget binary_url="https://github.com/PACGlobalOfficial/PAC/releases/download/v0.14.0.6/pacglobal-v0.14.0.6-lin64.tgz"

tar -xzf pacglobal-v0.14.0.6-lin64.tgz

mv pacglobal-v0.14.0.6-lin64/* PACGlobal

rm pacglobal-035d4df02-legacylin64.tgz 
rm -R pacglobal-035d4df02-legacylin64/


echo "Starting PAC Global Service"

systemctl start pacg.service

sleep 10

echo "################################################"
echo "#             Update Complete     	     #"
echo "################################################"

PACGlobal/pacglobal-cli getinfo
PACGlobal/pacglobal-cli mnsync status
PACGlobal/pacglobal-cli masternode status
