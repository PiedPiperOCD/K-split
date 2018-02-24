#!/bin/bash


rc=$1
dest=$2
iterations=$3
stamp=$4
sizes=(50M)

echo
echo "Starting experiment at $stamp..."

source ./set-ports.sh

for size in ${sizes[@]}; do
        file=$size.file
        echo; echo "=== Downloading size $size ==="
                #timeout 1m ./myget.sh  "http://$dest/$file" >>  res_e2e_$size-$stamp.txt
                timeout 2m ./myget.sh  "http://${rc}:i${inports["pool"]}/$file" >> res_ksplit-aggConnpool_$size-$stamp.txt &
                timeout 2m ./myget.sh  "http://${rc}:80/$file" >>  res_rc2_$size-$stamp.txt 
                #timeout 1m ./myget.sh  "http://${rc}:50000/$file" >> res_sshsplit_$size-$stamp.txt
done
