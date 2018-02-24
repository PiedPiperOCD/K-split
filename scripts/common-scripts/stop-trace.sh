#!/bin/bash

sudo pkill tcpdump
sleep 1
gzip *.pcap
