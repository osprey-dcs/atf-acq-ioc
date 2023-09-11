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
createPSCUDP("NASA_ACQ", "$(NASA_ACQ_FPGA_IP)", 54398, 1)

###############################################################################
# Load record instances
dbLoadRecords("db/nasaAcqSup.db", "P=$(P),R=$(R),PORT=NASA_ACQ")

###############################################################################
# Start IOC
cd "$(TOP)/iocBoot/$(IOC)"
iocInit
