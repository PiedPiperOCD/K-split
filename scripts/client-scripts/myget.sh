#!/bin/bash
curl -o /dev/null -w '%{time_total}\t%{size_download}\t%{time_starttransfer}\t%{time_connect}\n' $@

