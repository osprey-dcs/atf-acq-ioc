#!/bin/sh

P="FDAS:"
case "$#" in
    0)  ;;
    *)  P="$1" ;;
esac

showStatus() {
    caput -t "${P}01:MPS:status:01.PROC" 1
    caput -t "${P}01:MPS:tripped.PROC" 1
    echo "Expect $1."
    caget -0x "${P}01:MPS:status:01" \
              "${P}01:MPS:firstInputs:01" \
              "${P}01:MPS:tripped"
    caget "${P}01:MPS:firstSeconds:01"
}

caput -t "${P}01:MPS:chkInputs:01" 0
caput -t "${P}01:MPS:required" 2
caput -t "${P}01:MPS:goodState:01" 0
caput -t "${P}01:MPS:invert" 0
caput -t "${P}01:MPS:chkInputs:01" 15
sleep 4
showStatus "no fault, no trip"

caput -t "${P}01:MPS:invert" 1
sleep 4
showStatus "fault, trip"

caput -t "${P}01:MPS:invert" 0
sleep 4
showStatus "no fault, trip"

caput -t "${P}01:MPS:invert" 2
sleep 4
showStatus "fault, trip, but first inputs and seconds should not have changed"

caput -t "${P}01:MPS:invert" 0
sleep 4
showStatus "no fault, trip"

caput -t "${P}MPS:clear" 1
sleep 4
showStatus "no fault, no trip"
