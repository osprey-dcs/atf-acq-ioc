#!../../bin/darwin-x86/nasaAcq

###############################################################################
# Set up environment
epicsEnvSet(NASA_ACQ_FPGA_IP, "$(NASA_ACQ_FPGA_IP=192.168.19.1)")
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
createPSCUDP("NASA_CTRL01", "$(NASA_ACQ_FPGA_IP)01", 54398, 1)
# And repeat 32 times, one for each node
createPSCUDPFast("NASA_ACQ01", "$(NASA_ACQ_FPGA_IP)01", 54399, 0)
# And repeat 32 times, one for each node

###############################################################################
# Load record instances
dbLoadRecords("db/nasaAcqSup.db", "P=$(P),PORT=NASA_CTRL")
# FIXME: This has to be redone to handle multiple acquisition nodes -- force use of the first node for now.
dbLoadRecords("db/pscudpfast.db", "P=$(P),NAME=NASA_ACQ01")

###############################################################################
# Start IOC
cd "$(TOP)/iocBoot/$(IOC)"
iocInit
dbpf "$(P)FileDir-SP" "/tmp"
dbpf "$(P)FileBase-SP" "FOO-"
dbpf "$(P)Record-Sel" 1
