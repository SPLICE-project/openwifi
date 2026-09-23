#! /bin/bash

### Script that sends frames at MCS0 and captures ACKS
sudo tcpdump -i sdr0 -e -s 0 -n -w "acks_mcs_0.pcap" 'radio[radio[2]] = 0xd4 and radio[radio[2]+1] = 0x00 and radio[radio[2]+4] = 0x22 and radio[radio[2]+5] = 0x23 and radio[radio[2]+6] = 0x23 and radio[radio[2]+7] = 0x23 and radio[radio[2]+8] = 0x23' > /dev/null 2>&1 </dev/null &
    sleep 0.2
    
### send frames
./openwifi/inject_80211/rand_pkt 0 $1
    
## kill tcpdump
pkill -TERM tcpdump

