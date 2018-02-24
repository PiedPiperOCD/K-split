#!/bin/bash


rc=$1
dest=$2
iterations=$3
stamp=$4
sizes=(50M)
#sizes=(10K)

echo
echo "Starting experiment at $stamp..."

source ./set-ports.sj

for size in ${sizes[@]}; do
        file=$size.file
        echo; echo "=== Downloading size $size ==="
                #timeout 1m ./myget.sh  "http://$dest/$file" >>  res_e2e_$size-$stamp.txt
                timeout 2m ./myget.sh  "http://${rc}:${inports["nat"]}/$file" >> res_nat_$size-$stamp.txt &
                timeout 2m ./myget.sh  "http://${rc}:80/$file" >>  res_rc1_$size-$stamp.txt 
                #timeout 1m ./myget.sh  "http://${rc}:${inports["ssh"]}/$file" >> res_sshsplit_$size-$stamp.txt
done
