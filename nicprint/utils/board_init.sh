#!/bin/bash

### Script to set up OpenWifi board to monitor mode in specific channel
### Run this script to set up Frame Injector

if [[ "$#" -ne 1 ]]; then
echo "Usage $0 <CHANNEL>"
exit 1
fi

CHANNEL_CAP=$1
ssh root@192.168.10.122 "rm -f *.pcap && cd openwifi && ./wgd.sh && ./monitor_ch.sh sdr0 $CHANNEL_CAP"
