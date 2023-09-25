#!../../bin/darwin-x86/nasaAcq

###############################################################################
# Set up environment
epicsEnvSet(NASA_ACQ_FPGA_IP, "$(NASA_ACQ_FPGA_IP=192.168.19.7)")
epicsEnvSet(P, "$(NASA_ACQ_P=NASAACQ:)")
epicsEnvSet(R, "$(NASA_ACQ_R=0:)")
< envPaths
cd "$(TOP)"

###############################################################################
# Register support components
dbLoadDatabase "dbd/nasaAcq.dbd"
nasaAcq_registerRecordDeviceDriver pdbbase

###############################################################################
# Set up connections
createPSCUDP("NASA_CTRL", "$(NASA_ACQ_FPGA_IP)", 54398, 1)
createPSCUDPFast("NASA_ACQ", "$(NASA_ACQ_FPGA_IP)", 54399, 0)
var PSCDebug 0
var PSCUDPDSyncSizeMB 20

###############################################################################
# Load record instances
dbLoadRecords("db/nasaAcqSup.db", "P=$(P),R=$(R),PORT=NASA_CTRL")
dbLoadRecords("db/pscudpfast.db", "P=$(P)$(R),NAME=NASA_ACQ")

###############################################################################
# Start IOC
cd "$(TOP)/iocBoot/$(IOC)"
iocInit
dbpf "$(P)$(R)FileDir-SP" "."
dbpf "$(P)$(R)FileBase-SP" "FOO"
