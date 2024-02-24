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
createPSCUDP("NASA_CTRL01", "$(NASA_ACQ_BASE_IP)01", 54398, 1)
# And repeat 32 times, one for each node
createPSCUDPFast("NASA_ACQ01", "$(NASA_ACQ_BASE_IP)01", 54399, 0)
# And repeat 32 times, one for each node

###############################################################################
# Load record instances
# Global
dbLoadRecords("db/nasaEVG.db", "P=$(P),PORT=NASA_CTRL")
# Per FPGA
dbLoadRecords("db/nasaAcqSup.db", "P=$(P),NODE=01,PORT=NASA_CTRL")
# FIXME: This has to be redone to handle multiple acquisition nodes -- force use of the first node for now.
dbLoadRecords("db/pscudpfast.db", "P=$(P),NAME=NASA_ACQ01")

###############################################################################
# Start IOC
cd "$(TOP)/iocBoot/$(IOC)"
iocInit
dbpf "$(P)FileDir-SP" "/tmp"
dbpf "$(P)FileBase-SP" "FOO-"
dbpf "$(P)Record-Sel" 1
dbpf "$(P)01:ACQ:coupling:00" 1
dbpf "$(P)01:ACQ:coupling:01" 1
dbpf "$(P)01:ACQ:coupling:02" 1
dbpf "$(P)01:ACQ:coupling:03" 1
dbpf "$(P)01:ACQ:coupling:04" 1
dbpf "$(P)01:ACQ:coupling:05" 1
dbpf "$(P)01:ACQ:coupling:06" 1
dbpf "$(P)01:ACQ:coupling:07" 1
dbpf "$(P)01:ACQ:coupling:08" 1
dbpf "$(P)01:ACQ:coupling:09" 1
dbpf "$(P)01:ACQ:coupling:10" 1
dbpf "$(P)01:ACQ:coupling:11" 1
dbpf "$(P)01:ACQ:coupling:12" 1
dbpf "$(P)01:ACQ:coupling:13" 1
dbpf "$(P)01:ACQ:coupling:14" 1
dbpf "$(P)01:ACQ:coupling:15" 1
dbpf "$(P)01:ACQ:coupling:16" 1
dbpf "$(P)01:ACQ:coupling:17" 1
dbpf "$(P)01:ACQ:coupling:18" 1
dbpf "$(P)01:ACQ:coupling:19" 1
dbpf "$(P)01:ACQ:coupling:20" 1
dbpf "$(P)01:ACQ:coupling:21" 1
dbpf "$(P)01:ACQ:coupling:22" 1
dbpf "$(P)01:ACQ:coupling:23" 1
dbpf "$(P)01:ACQ:coupling:24" 1
dbpf "$(P)01:ACQ:coupling:25" 1
dbpf "$(P)01:ACQ:coupling:26" 1
dbpf "$(P)01:ACQ:coupling:27" 1
dbpf "$(P)01:ACQ:coupling:28" 1
dbpf "$(P)01:ACQ:coupling:29" 1
dbpf "$(P)01:ACQ:coupling:30" 1
dbpf "$(P)01:ACQ:coupling:31" 1
dbpf "$(P)01:ACQ:setActive" -1
