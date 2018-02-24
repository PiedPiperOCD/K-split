#!/bin/bash


filename=$1
col=$2

#cut the relevant column and sort it
cut -f${col} $filename | sort -n | awk '{
	count[NR] = $1;
    	}
    	END {
        	if (NR % 2) {
			print count[(NR + 1) / 2];
		} else {
		       	print (count[(NR / 2)] + count[(NR / 2) + 1]) / 2.0
		}
	}'



