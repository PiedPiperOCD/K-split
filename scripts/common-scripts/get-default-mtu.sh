#!/bin/bash
dev=$1
cat /sys/class/net/${dev}/mtu
