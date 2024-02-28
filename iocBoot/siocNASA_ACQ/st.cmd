#!../../bin/darwin-x86/nasaAcq

###############################################################################
# Set up environment
epicsEnvSet(NASA_ACQ_BASE_IP, "$(NASA_ACQ_BASE_IP=192.168.19.1)")
epicsEnvSet(P, "$(NASA_ACQ_P=NASA_ACQ:)")
< envPaths
cd "$(TOP)"

###############################################################################
# Register support components
dbLoadDatabase "dbd/nasaAcq.dbd"
nasaAcq_registerRecordDeviceDriver pdbbase

###############################################################################
# Set up connections
var PSCDebug 0
var PSCUDPMaxPacketSize 1500
cd "$(TOP)/iocBoot/$(IOC)"

# Repeat the following 32 times -- one for each node
iocshLoad "config_node.cmd" "NODE=01"

###############################################################################
cd "$(TOP)"
# Load record instances unique to event generator
dbLoadRecords("db/nasaEVG.db", "P=$(P),PORT=NASA_CMD01")

###############################################################################
# Start IOC
cd "$(TOP)/iocBoot/$(IOC)"
iocInit


dbpf "$(P)FileDir-SP" "/tmp"
dbpf "$(P)FileBase-SP" "FOO-"
dbpf "$(P)Record-Sel" 1

dbpf "$(P)01:ACQ:coupling:01" "DC"
dbpf "$(P)01:ACQ:coupling:02" "DC"
dbpf "$(P)01:ACQ:coupling:03" "DC"
dbpf "$(P)01:ACQ:coupling:04" "DC"
dbpf "$(P)01:ACQ:coupling:05" "DC"
dbpf "$(P)01:ACQ:coupling:06" "DC"
dbpf "$(P)01:ACQ:coupling:07" "DC"
dbpf "$(P)01:ACQ:coupling:08" "DC"
dbpf "$(P)01:ACQ:coupling:09" "DC"
dbpf "$(P)01:ACQ:coupling:10" "DC"
dbpf "$(P)01:ACQ:coupling:11" "DC"
dbpf "$(P)01:ACQ:coupling:12" "DC"
dbpf "$(P)01:ACQ:coupling:13" "DC"
dbpf "$(P)01:ACQ:coupling:14" "DC"
dbpf "$(P)01:ACQ:coupling:15" "DC"
dbpf "$(P)01:ACQ:coupling:16" "DC"
dbpf "$(P)01:ACQ:coupling:17" "DC"
dbpf "$(P)01:ACQ:coupling:18" "DC"
dbpf "$(P)01:ACQ:coupling:19" "DC"
dbpf "$(P)01:ACQ:coupling:20" "DC"
dbpf "$(P)01:ACQ:coupling:21" "DC"
dbpf "$(P)01:ACQ:coupling:22" "DC"
dbpf "$(P)01:ACQ:coupling:23" "DC"
dbpf "$(P)01:ACQ:coupling:24" "DC"
dbpf "$(P)01:ACQ:coupling:25" "DC"
dbpf "$(P)01:ACQ:coupling:26" "DC"
dbpf "$(P)01:ACQ:coupling:27" "DC"
dbpf "$(P)01:ACQ:coupling:28" "DC"
dbpf "$(P)01:ACQ:coupling:29" "DC"
dbpf "$(P)01:ACQ:coupling:30" "DC"
dbpf "$(P)01:ACQ:coupling:31" "DC"
dbpf "$(P)01:ACQ:coupling:32" "DC"

dbpf "$(P)01:ACQ:enable:01" 1
dbpf "$(P)01:ACQ:enable:02" 1
dbpf "$(P)01:ACQ:enable:03" 1
dbpf "$(P)01:ACQ:enable:04" 1
dbpf "$(P)01:ACQ:enable:05" 1
dbpf "$(P)01:ACQ:enable:06" 1
dbpf "$(P)01:ACQ:enable:07" 1
dbpf "$(P)01:ACQ:enable:08" 1
dbpf "$(P)01:ACQ:enable:09" 1
dbpf "$(P)01:ACQ:enable:10" 1
dbpf "$(P)01:ACQ:enable:11" 1
dbpf "$(P)01:ACQ:enable:12" 1
dbpf "$(P)01:ACQ:enable:13" 1
dbpf "$(P)01:ACQ:enable:14" 1
dbpf "$(P)01:ACQ:enable:15" 1
dbpf "$(P)01:ACQ:enable:16" 1
dbpf "$(P)01:ACQ:enable:17" 1
dbpf "$(P)01:ACQ:enable:18" 1
dbpf "$(P)01:ACQ:enable:19" 1
dbpf "$(P)01:ACQ:enable:20" 1
dbpf "$(P)01:ACQ:enable:21" 1
dbpf "$(P)01:ACQ:enable:22" 1
dbpf "$(P)01:ACQ:enable:23" 1
dbpf "$(P)01:ACQ:enable:24" 1
dbpf "$(P)01:ACQ:enable:25" 1
dbpf "$(P)01:ACQ:enable:26" 1
dbpf "$(P)01:ACQ:enable:27" 1
dbpf "$(P)01:ACQ:enable:28" 1
dbpf "$(P)01:ACQ:enable:29" 1
dbpf "$(P)01:ACQ:enable:30" 1
dbpf "$(P)01:ACQ:enable:31" 1
dbpf "$(P)01:ACQ:enable:32" 1

