#!/bin/bash
# Task:
#	- read remote server's HW parameters using SSH password auth
#
# Params:
#   - $1: servername or IP address (mandatory)
#   - $2: SSH connection timeout (optional)
#
# Required non-standard Debian packages:
#   -  sshpass, lshw, smartmontools
#  
# Created by:	Kálmán Hadarics
# E-mail:	hadarics.kalman@gmail.com
# Version:	1.1
# Last mod.:	2021-06-12
#
# ----------------------------------------

if [ $# -lt 1 -o $# -gt 2 ]; then
    echo usage: $0 server [sshtimeout]
    exit
fi

server=$1

# Remote SSH connection parameters
SSHUSER="remoteuser"

# read ssh password from .sshpass file
export SSHPASS="$(cat .sshpass)"

# SSH connection timeout
SSHTIMEOUT=20

if [ $# -eq 2 ]; then
    SSHTIMEOUT=$2
fi

# Command separator
sc='echo ";"'

# CPU Procs
command1='lscpu | grep "^Socket.s.:" | tr -d " " | cut -d: -f2'

# CPU Model
command2='lscpu | grep "^Model name:" | tr -s " " " " | cut -d: -f2'

# Cores
command3='lscpu | grep "^Core.s. per socket:" | tr -d " " | cut -d: -f2'

# Threads
command4='lscpu | grep "^CPU.s.:" | tr -d " " | cut -d: -f2'

# Memory
command5='lshw -class memory 2>/dev/null| grep size: | tr -d " "A-z | cut -d: -f2'

# Disk number (DNum)
command6='lsblk | grep -c disk'

# Disk model
command7='lsblk -no model | grep "[[:alnum:]]" | head -n1'    

# Disk mixed
command8='lsblk -o model -nd | sort -u | wc -l'    

# RAID detection (need passwordless sudo)
command9="echo -n $(echo $SSHPASS) | "'sudo -p "" -S smartctl -i -d megaraid,0 /dev/sda | grep -c "Device Model:"'    

# SSH command to execute
command="${command1};${sc};${command2};${sc};${command3};${sc};${command4};${sc};${command5};${sc};${command6};${sc};${command7};${sc};${command8};${sc};${command9}"

# Get results
result=$(sshpass -e ssh -o 'StrictHostKeyChecking=no' -o 'ConnectTimeout='${SSHTIMEOUT} ${SSHUSER}@${server} ${command})

# Process results
res=$(echo ${result} | sed 's/ ; /;/g')

pinfo=$(echo $res | cut -d\; -f1)
model=$(echo $res | cut -d\; -f2)

model=${model/Intel(R) Xeon(R)/Xeon}
model=${model/CPU /}

cores=$(echo $res | cut -d\; -f3)
cores=$((cores*pinfo))
if [ $cores -eq 0 ]; then
    cores=""
fi
threads=$(echo $res | cut -d\; -f4)
mem=$(echo $res | cut -d\; -f5)
dnum=$(echo $res | cut -d\; -f6)
dmodel=$(echo $res | cut -d\; -f7)
dmixed=$(echo $res | cut -d\; -f8)
raid=$(echo $res | cut -d\; -f9)

if [ -z "$dmixed" ]; then
    dmixed=0
elif [ "$dmixed" -eq 1 ]; then
    dmixed=0
else
    dmixed=1
fi

if [ -z "$raid" ]; then
    raid=0
fi

# Dump results
echo "${server};${pinfo};${model};${cores};${threads};${mem};${dnum};${dmodel};${dmixed};${raid}"
