#! /bin/bash

#### Data-Controller Helper -> Malformed STF sweep across n
START=$SECONDS
TOTAL_SAMPS_STF=161

if [[ "$#" -ne 4 ]]; then
echo "Usage $0 <START_DEC> <BASE_DIR>  <NAME_CAP_DIR> <DST_MAC>"
exit 1
fi

BASE_DIR=$2 ## DIR that has bitstreams and captures
START_DEC=$1 ## start of decremented bitstream 
NAME_CAP_DIR=$3 ## name of the directory where captures should be saved
DST_MAC=$4
NAME_HELP_CAP="help_cap.pcap"

if [ ! -d "$BASE_DIR/captures" ]; then
echo "captures directory does not exist"
exit 4
fi 


## make directory in capture
CAPTURE_SAVE_PATH="$BASE_DIR/captures/$NAME_CAP_DIR"

for (( i=$START_DEC;  i<$TOTAL_SAMPS_STF; i+=5 ))
do 
printf "############STARTING BITSTREAM $i ITERATION#################\n"

CAPTURE_DIR_INTERATION=$CAPTURE_SAVE_PATH/minus_${i}_stf
mkdir -p "$CAPTURE_DIR_INTERATION"

## run the capture experiment
ssh root@192.168.10.122 "echo $i > /sys/devices/soc0/fpga-axi@0/83c10000.openofdm_tx/num_minus_stf"
tshark -i wlx00c0cab1a754 -s 0 -B 4096 -n -w "$NAME_HELP_CAP" > /dev/null 2>&1 </dev/null &
printf "STARTING TRANSMISSION\n"
ssh root@192.168.10.122 "./mcs0_caprute.sh $DST_MAC"
scp root@192.168.10.122:'~/*.pcap' $CAPTURE_DIR_INTERATION >> /dev/null 
printf "############BITSTREAM $i ITERATION DONE#################\n"
pkill tshark
tshark -r $NAME_HELP_CAP -Y "wlan.fc.type_subtype == 0x1d && wlan.ra == 22:23:23:23:23:00" -w ack_MCS0_HELPER.pcap
mv *.pcap $CAPTURE_DIR_INTERATION

done

ELAPSED=$(( SECONDS - START ))
echo "Script ran for ${ELAPSED} seconds"
