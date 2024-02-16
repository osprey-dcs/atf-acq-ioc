#!../../bin/darwin-x86/nasaAcq

###############################################################################
# Set up environment
epicsEnvSet(NASA_ACQ_BASE_IP, "$(NASA_ACQ_BASE_IP=192.168.19.1)")
epicsEnvSet(P, "$(NASA_ACQ_P=NASA_ACQ:)")
epicsEnvSet(EVG, "$(P)01:")
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

# Configure a single acquisition node
createPSCUDP("NASA_CTRL_EVG", "192.168.79.4", 54398, 0)
createPSCUDPFast("NASA_CTRL_EVG_FS", "192.168.79.4", 54399, 0)
dbLoadRecords("../../db/nasaAcqSup.db", "P=$(P)01:,EVG=$(EVG),NODE=,PORT=NASA_CTRL_EVG")
dbLoadRecords("../../db/pscudpfast.db", "P=$(P)01:,NAME=NASA_CTRL_EVG_FS")
dbLoadRecords("../../db/quartzAcq.db", "P=$(P)01:,EVG=$(EVG),NAME=NASA_CTRL_EVG_FS, NELM=10000")

# Load record instances unique to event generator
dbLoadRecords("../../db/nasaEVG.db", "P=$(EVG),PORT=NASA_CTRL_EVG")


createPSCUDP("NASA_CTRL_ALT", "192.168.79.1", 54398, 0)
createPSCUDPFast("NASA_CTRL_ALT_FS", "192.168.79.1", 54399, 0)
dbLoadRecords("../../db/nasaAcqSup.db", "P=$(P)02:,EVG=$(EVG),NODE=,PORT=NASA_CTRL_ALT")
dbLoadRecords("../../db/pscudpfast.db", "P=$(P)02:,NAME=NASA_CTRL_ALT_FS")
dbLoadRecords("../../db/quartzAcq.db", "P=$(P)02:,EVG=$(EVG),NAME=NASA_CTRL_ALT_FS, NELM=10000")

iocInit

# FIXME -- this needs to go to some client
dbpf "$(P)01:FileDir-SP" "/tmp"
dbpf "$(P)01:FileBase-SP" "FOO-"
#dbpf "$(P)01:Record-Sel" 1
dbpf "$(P)02:FileDir-SP" "/tmp"
dbpf "$(P)02:FileBase-SP" "BAR-"
#dbpf "$(P)02:Record-Sel" 1

# FIXME -- should this be autosave/restore or some startup client?  And what about the calibration coefficients?
#iocshLoad "init_node.cmd" "NODE=01"
#iocshLoad "init_node.cmd" "NODE=02"


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

dbpf "$(P)02:ACQ:enable:01" 1
dbpf "$(P)02:ACQ:enable:02" 1
dbpf "$(P)02:ACQ:enable:03" 1
dbpf "$(P)02:ACQ:enable:04" 1
dbpf "$(P)02:ACQ:enable:05" 1
dbpf "$(P)02:ACQ:enable:06" 1
dbpf "$(P)02:ACQ:enable:07" 1
dbpf "$(P)02:ACQ:enable:08" 1
dbpf "$(P)02:ACQ:enable:09" 1
dbpf "$(P)02:ACQ:enable:10" 1
dbpf "$(P)02:ACQ:enable:11" 1
dbpf "$(P)02:ACQ:enable:12" 1
dbpf "$(P)02:ACQ:enable:13" 1
dbpf "$(P)02:ACQ:enable:14" 1
dbpf "$(P)02:ACQ:enable:15" 1
dbpf "$(P)02:ACQ:enable:16" 1
dbpf "$(P)02:ACQ:enable:17" 1
dbpf "$(P)02:ACQ:enable:18" 1
dbpf "$(P)02:ACQ:enable:19" 1
dbpf "$(P)02:ACQ:enable:20" 1
dbpf "$(P)02:ACQ:enable:21" 1
dbpf "$(P)02:ACQ:enable:22" 1
dbpf "$(P)02:ACQ:enable:23" 1
dbpf "$(P)02:ACQ:enable:24" 1
dbpf "$(P)02:ACQ:enable:25" 1
dbpf "$(P)02:ACQ:enable:26" 1
dbpf "$(P)02:ACQ:enable:27" 1
dbpf "$(P)02:ACQ:enable:28" 1
dbpf "$(P)02:ACQ:enable:29" 1
dbpf "$(P)02:ACQ:enable:30" 1
dbpf "$(P)02:ACQ:enable:31" 1
dbpf "$(P)02:ACQ:enable:32" 1

