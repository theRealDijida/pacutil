#!/bin/bash

set -e

export LC_ALL="en_US.UTF-8"


systemctl stop pacg.service

sudo swapoff -a
rm /swapfile


test -e .PACGlobal/wallet.dat && mv .PACGlobal/wallet.dat .
mv .PACGlobal/pacglobal.conf .

rm -R PACGlobal/*
rm -R .PACGlobal/*

wget http://51.15.51.146/PACGlobal.tar.gz
wget http://51.15.51.146/pacglobal_bootstrap_current-2020_03_14__01_22_30.tar.gz


tar xvzf PACGlobal.tar.gz 
tar xvzf pacglobal_bootstrap_current-2020_03_14__01_22_30.tar.gz 

rm pacglobal_bootstrap_current-2020_03_14__01_22_30.tar.gz
rm PACGlobal.tar.gz

mv pacglobal.conf .PACGlobal/
test -e wallet.dat && mv wallet.dat .PACGlobal/





sudo fallocate -l 4G /swapfile

sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

systemctl start pacg.service

sleep 5

PACGlobal/pacglobal-cli getinfo
PACGlobal/pacglobal-cli masternode status
PACGlobal/pacglobal-cli mnsync status
