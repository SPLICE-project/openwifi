#! /bin/bash
if [[ "$#" -ne 3 ]]; then
echo "Usage $0 <BASE_DIR> <NAME_CAP_DIR> <DST_MAC>"
exit 1
fi

BASE_DIR=$1 ## DIR that has bitstreams and captures
NAME_CAP_DIR=$2 ## name of the directory where captures should be saved
DST_MAC=$3
NAME_HELP_CAP="help_cap.pcap"

if [ ! -d "$BASE_DIR/captures" ]; then
echo "captures directory does not exist"
exit 4
fi 

## make directory in capture
CAPTURE_SAVE_PATH="$BASE_DIR/captures/$NAME_CAP_DIR"


CAPTURE_FINAL_DIR=$CAPTURE_SAVE_PATH/stock
mkdir -p "$CAPTURE_FINAL_DIR"
ssh root@192.168.10.122 "echo 0 > /sys/devices/soc0/fpga-axi@0/83c10000.openofdm_tx/num_minus_stf; echo \$?"
tshark -i wlx00c0cab1a754 -s 0 -B 4096 -n -w "$NAME_HELP_CAP" > /dev/null 2>&1 </dev/null &
printf "STARTING TRANSMISSION\n"
ssh root@192.168.10.122 "./mcs0_caprute.sh $DST_MAC"
scp root@192.168.10.122:'~/*.pcap' $CAPTURE_FINAL_DIR >> /dev/null 
pkill tshark
tshark -r $NAME_HELP_CAP -Y "wlan.fc.type_subtype == 0x1d && wlan.ra == 22:23:23:23:23:00" -w ack_MCS0_HELPER.pcap
mv *.pcap $CAPTURE_FINAL_DIR
ELAPSED=$(( SECONDS - START ))
echo "Script ran for ${ELAPSED} seconds"
