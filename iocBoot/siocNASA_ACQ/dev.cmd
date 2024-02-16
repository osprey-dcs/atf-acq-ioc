#!../../bin/linux-arm/nasaAcq

###############################################################################
# Set up environment
epicsEnvSet(NASA_ACQ_BASE_IP, "192.168.79.0") # TODO: change me
epicsEnvSet(NODE, "02")
epicsEnvSet(P, "NASA_ACQ:$(NODE):")
epicsEnvSet(EVG, "NASA_ACQ:01:")

###############################################################################
# Register support components
dbLoadDatabase "../../dbd/nasaAcq.dbd"
nasaAcq_registerRecordDeviceDriver pdbbase

###############################################################################
# Set up connections
var PSCDebug 0
var PSCUDPMaxPacketSize 1500

# Configure a single acquisition node
createPSCUDP("NASA_CTRL_EVG", "$(NASA_ACQ_BASE_IP)", 54398, 0)
createPSCUDPFast("NASA_CTRL_EVG_FS", "$(NASA_ACQ_BASE_IP)", 54399, 0)
dbLoadRecords("../../db/nasaAcqSup.db", "P=$(P),EVG=$(EVG),NODE=,PORT=NASA_CTRL_EVG")
dbLoadRecords("../../db/pscudpfast.db", "P=$(P),NAME=NASA_CTRL_EVG_FS")
dbLoadRecords("../../db/quartzAcq.db", "P=$(P),EVG=$(EVG),NAME=NASA_CTRL_EVG_FS, NELM=10000")

iocInit

# FIXME -- this needs to go to some client
dbpf "$(P)FileDir-SP" "/tmp"
dbpf "$(P)FileBase-SP" "EVG-"
#dbpf "$(P)Record-Sel" 1


dbpf "$(P)ACQ:enable:01" 1
# crutch pending rate limit
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:02" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:03" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:04" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:05" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:06" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:07" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:08" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:09" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:10" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:11" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:12" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:13" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:14" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:15" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:16" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:17" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:18" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:19" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:20" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:21" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:22" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:23" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:24" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:25" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:26" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:27" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:28" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:29" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:30" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:31" 1
epicsThreadSleep 0.1
dbpf "$(P)ACQ:enable:32" 1
