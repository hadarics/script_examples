#!/bin/bash
# Task:
#	- common variables
#	- common functions
#
#
# Created by:	Kálmán Hadarics
# E-mail:	hadarics.kalman@gmail.com
# Version:	1.2
# Last mod.:	2018-02-10
#
# ----------------------------------------

# CHECK -- need defined ID var or it uses 10 as default

# Global constants
INMAC_PREFIX="0A0000"
OUTMAC_PREFIX="0E0000"
INIP_PREFIX="192.168."
OUTIP_PREFIX="172.16.1."

function nid2id() {
	printf "%02d%04d" $1 $2
}

function id2nid() {
	echo ${1:0:2}
}

function nid2gwname() {
	echo $1-gateway
}

function str2mac() {
	echo $1 | sed -re 's/^(..)(..)(..)(..)(..)(..)$/\1:\2:\3:\4:\5:\6/'
}

function inmacs4id() {
	echo ${INMAC_PREFIX}$1
}

function outmacs4id() {
	echo ${OUTMAC_PREFIX}$1
}

function inip4id() {
	echo ${INIP_PREFIX}$(echo $1 | sed -re 's/^(..)0*(.*$)/\1.\2/')
}

function inipnet4id() {
	echo ${INIP_PREFIX}$(id2nid $1).
}

function outip4id() {
	echo ${OUTIP_PREFIX}$(echo $1 | sed -re 's/^(..).*$/\1/')
}

function ns4id() {
	echo net${1}
}

function exit_msg() {
	echo $1
	exit
}


# if $ID not defined
[ "$ID" = "" ] && ID=10


GWID=$(nid2id $ID 254)
#echo $GWID

GWNAME=$(nid2gwname $GWID)
#echo $GWNAME

GWINMACS=$(inmacs4id $GWID)
#echo $GWINMACS

GWINMAC=$(str2mac $GWINMACS)
#echo $GWINMAC

GWOUTMACS=$(outmacs4id $GWID)
#echo $GWOUTMACS

GWOUTMAC=$(str2mac $GWOUTMACS)
#echo $GWOUTMAC

GWINIP=$(inip4id $GWID)
#echo $GWINIP

GWINIPNET=$(inipnet4id $GWID)
#echo $GWINIPNET

GWOUTIP=$(outip4id $GWID)
#echo $GWOUTIP

GWOUTIPNET=$OUTIP_PREFIX

NSPREGW=$(ns4id $ID)
#echo $NSPREGW

NSSERIAL=$(date +%Y%m%d%H)

# Template variables
declare -A vars
vars=(
    [%ID%]=$ID
    [%GWID%]=$GWID
    [%GWNAME%]=$GWNAME
    [%GWINIP%]=$GWINIP
    [%GWINIPNET%]=$GWINIPNET
    [%GWOUTIP%]=$GWOUTIP
    [%GWOUTIPNET%]=$GWOUTIPNET
    [%NSPREGW%]=$NSPREGW
    [%NSSERIAL%]=$NSSERIAL
)

# Do template based replacement
processfile() {
    cp ${1}_t $1
    for i in "${!vars[@]}"; do
        search=$i
        replace=${vars[$i]}
        sed -i -e "s/${search}/${replace}/g" $1
    done
}

# Remove CSV header and load to array
hosts=($(cat hosts_${ID}.csv | sed '1d'))

# Create DHCP host entry
function cr_dhcp() {
	for i in ${hosts[*]}; do
		elements=(${i//,/ })

echo "host ${elements[1]}-${elements[2]} {
  hardware ethernet $(str2mac $(inmacs4id ${elements[1]}));
  fixed-address $(inip4id ${elements[1]});
  option host-name \"${elements[1]}-${elements[2]}\";
}
" 
		
	done
}

# Create NS entries
#100002-windows10-client	IN	A	192.168.10.2
function cr_ns() {
	for i in ${hosts[*]}; do
		elements=(${i//,/ })
		echo "${elements[1]}-${elements[2]}	IN	A	$(inip4id ${elements[1]})"
	done
}

# Create Reverse NS entries
#2      IN      PTR     100002-windows10-client.inc.testdomain.com.
function cr_rns() {
	for i in ${hosts[*]}; do
		elements=(${i//,/ })
		echo "$(inip4id ${elements[1]}|cut -d. -f4)	IN	PTR	${elements[1]}-${elements[2]}.${NSPREGW}.testdomain.com."
	done
}
