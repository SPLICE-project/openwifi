#! /bin/bash
#### NICPrint DATA-Controller Main Sample Runner #####
if [[ "$#" -ne 5 ]]; then
echo "Usage $0 <BASE_DIR> <NAME_CAP_DIR> <DST_MAC> <START_RUN> <NUM_RUNS>"
exit 1
fi
BASE_DIR=$1
NAME_CAP_DIR=$2
DST_MAC=$3
STRT_RUN=$4
NUM_RUNS=$5

for (( i=$STRT_RUN;  i<$NUM_RUNS; i+=1 ))
do
## Run stock
./stock_capture.sh $BASE_DIR "${NAME_CAP_DIR}_$i" $DST_MAC

## Run dec capture
./dec_capture.sh 5 $BASE_DIR "${NAME_CAP_DIR}_$i" $DST_MAC
done
