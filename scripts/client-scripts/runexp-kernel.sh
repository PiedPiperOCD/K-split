#!/bin/bash


rc=$1
dest=$2
iterations=$3
stamp=$4
port=$5
out=$6
sizes=(10K 100K 1M 10M 50M)
#sizes=(10K)

echo
echo "Starting experiment at $stamp..."

for size in ${sizes[@]}; do
        file=$size.file
        echo; echo "=== Downloading size $size ==="
        for iter in `seq 1 $iterations`; do
                echo "*********************** Interation $iter of $iterations ***********************"
                timeout 1m ./myget.sh  "http://${rc}:$port/$file" >>  res_ksplit_${out}_$size-$stamp.txt
        done
done
