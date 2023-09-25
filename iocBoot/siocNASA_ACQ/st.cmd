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
createPSCUDP("NASA_CTRL00", "$(NASA_ACQ_FPGA_IP)00", 54398, 1)
# And repeat 32 times, one for each node
createPSCUDPFast("NASA_ACQ00", "$(NASA_ACQ_FPGA_IP)00", 54399, 0)
# And repeat 32 times, one for each node
var PSCDebug 0
var PSCUDPDSyncSizeMB 20

###############################################################################
# Load record instances
dbLoadRecords("db/nasaAcqSup.db", "P=$(P),PORT=NASA_CTRL")
# FIXME: This has to be redone to handle multiple acquisition nodes -- force use of the first node for now.
dbLoadRecords("db/pscudpfast.db", "P=$(P),NAME=NASA_ACQ00")

###############################################################################
# Start IOC
cd "$(TOP)/iocBoot/$(IOC)"
iocInit
dbpf "$(P)FileDir-SP" "."
dbpf "$(P)FileBase-SP" "FOO"
dbpf "$(P)Record-Sel" 1
