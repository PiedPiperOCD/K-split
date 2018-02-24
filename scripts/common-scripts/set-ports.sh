#!/bin/bash

port_base=50000

unset inports
declare -A inports

inports["ssh"]=$(( port_base++ ))
inports["user"]=$(( port_base++ ))
inports["kernel"]=$(( port_base++ ))
inports["pool"]=$(( port_base++ ))
inports["nat"]=$(( port_base++ ))



