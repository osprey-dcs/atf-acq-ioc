#!../../bin/linux-arm/nasaAcq

###############################################################################
# Set up environment
epicsEnvSet(NASA_ACQ_BASE_IP, "192.168.79.0") # TODO: change me
epicsEnvSet(NODE, "01")
epicsEnvSet(P, "NASA_ACQ:$(NODE):")
epicsEnvSet(EVG, "$(P)") # this is the EVG node

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

# Load record instances unique to event generator
dbLoadRecords("../../db/nasaEVG.db", "P=$(EVG),PORT=NASA_CTRL_EVG")

iocInit

# FIXME -- this needs to go to some client
dbpf "$(P)FileDir-SP" "/tmp"
dbpf "$(P)FileBase-SP" "EVG-"
#dbpf "$(P)Record-Sel" 1
