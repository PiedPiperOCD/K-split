#!/bin/bash

iface=$( ./get-default-dev.sh )
name=$1
sudo tcpdump -ni $iface -w $name.pcap -s 100 > $name.log 2>&1 & 
