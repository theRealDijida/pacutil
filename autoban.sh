#!/bin/bash

#CONFIG
PAC_CLI="/root/paccoin/paccoin-cli -conf=/root/.paccoincore/paccoin.conf -datadir=/root/.paccoincore/" #paccoin-cli lcoation, paccoin.conf location, .paccoincore location
PAC_PEERS="/root/paccoin/peers" #Peer Logging Folder
BANNED="/Paccoin Core:0.12.5/" #Bad Peer Versions


#CREATE PEER LOGGING DIRECTORY IF NEEDED
if [ ! -d $PAC_PEERS ]; then
  mkdir -p $PAC_PEERS;
fi


#LOGGING
echo "Logging Good Peers"
$PAC_CLI getpeerinfo | grep 'addr\|subver' | grep -B 2 '12.5.1' | grep '\"addr\"' >> $PAC_PEERS/goodpeers.log
awk '!a[$0]++' $PAC_PEERS/goodpeers.log >/dev/null 2>&0

echo "Logging Bad Peers"
$PAC_CLI getpeerinfo | grep 'addr\|subver' | grep -B 2 '12.5/' | grep '\"addr\"' >> $PAC_PEERS/badpeers.log
awk '!a[$0]++' $PAC_PEERS/badpeers.log >/dev/null 2>&0
echo "Logging Peers Complete"


#AUTOBAN
$PAC_CLI getpeerinfo | mawk -F":" -v banned="$BANNED" -v paccli="$PAC_CLI" -- '
BEGIN {
    split(banned,BAN,",");
}
/\"id\"*/ {
    id=substr($2,2,length($2)-2);ID[id]=id;
}
/^....\"addr\"/ {
 if (substr($2,3,1)=="[") {
    sadr = substr($0,index($0,":"));
    start = index(sadr,"[");
    end = index(sadr,"]");
    IP[id]=substr(sadr,start,end-3);
  } else {
    IP[id]=substr($2,3);
  }
}
/\"subver\"*/ {
    s=length($1)+4;
    VER[id]=substr($0,s,(length($0)-s-1));
}
END {
    for (id in ID) {
    for (banned in BAN) {
            if(VER[id]==BAN[banned]) {
        system(paccli" setban "IP[id]" add 604800");

        }
    }
    }
}'
