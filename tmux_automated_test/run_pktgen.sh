#!/bin/bash

export DPDK_BASE_DIR=/root
export PKTGEN=pktgen-dpdk-pktgen-3.0.17

memory="--socket-mem 2048"
lcores="-l 0-4"
whitelist="-w 0000:00:04.0 -w 0000:00:05.0 -w 0000:00:06.0 -w 0000:00:07.0"
mapping="-m 1.0 -m 2.1 -m 3.2 -m 4.3"

cd $DPDK_BASE_DIR/$PKTGEN
/root/dpdk-pktgen $lcores --proc-type auto $memory -n 4 --log-level=7 $whitelist --file-prefix=dpdk0_ -- $mapping -N -T -P
