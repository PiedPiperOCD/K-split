#!/bin/bash

ip -o -4 route show to default | head -1 | awk '{print $5}'
#ip route show | awk '/^default/ {print $NF}'
