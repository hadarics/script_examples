#!/bin/bash
# Task:
#	- create a new vm in Proxmox (client)
#
# Params:
#   - $1: vm need to be cloned (mandatory)
#   - $2: new vm id (mandatory)
#   - $3: new name suffix (mandatory)
#   - $4: disk copy type { 0: linked, 1: full } clone (mandatory)
#   - $5: NIC type -- 0:virtio, 1:e1000 (mandatory)
#
#
# Created by:	Kálmán Hadarics
# E-mail:	hadarics.kalman@gmail.com
# Version:	1.2
# Last mod.:	2018-02-10
#
# ----------------------------------------

if [ $# -ne 5 ]; then
        echo usage: $0 vm_clone_id vm_id vm_name_post full_or_linked virtio_or_e1000
else    

CID=$1
CLID=$2
VNP=$3
FL=$4
NT=$5


. common.sh

CLNAME=${CLID}-${VNP}
CLMAC=$(str2mac $(inmacs4id $CLID))
BRID=$(id2nid $CLID)

echo "Creating virtual machine -- " $CLNAME

qm clone $CID $CLID --full $FL --name $CLNAME
echo "qm clone $CID $CLID --full $FL --name $CLNAME"

if [ $NT -eq 1 ]; then

        qm set $CLID -net0 e1000=${CLMAC},bridge=vmbr${BRID},firewall=1
        echo "qm set $CLID -net0 e1000=${CLMAC},bridge=vmbr${BRID},firewall=1"

else
        qm set $CLID -net0 virtio=${CLMAC},bridge=vmbr${BRID},firewall=1
        echo "qm set $CLID -net0 virtio=${CLMAC},bridge=vmbr${BRID},firewall=1"

fi

echo "done."

fi
