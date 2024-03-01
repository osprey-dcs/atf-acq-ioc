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
iocshLoad "config_node.cmd" "NODE=02"

###############################################################################
cd "$(TOP)"
# Load record instances unique to event generator
dbLoadRecords("db/nasaEVG.db", "P=$(P),PORT=NASA_CMD01")

###############################################################################
# Start IOC
cd "$(TOP)/iocBoot/$(IOC)"
iocInit


# FIXME -- this needs to go to a per-node 'iocshLoad' file
dbpf "$(P)01:FileDir-SP" "/tmp"
dbpf "$(P)01:FileBase-SP" "FOO-"
dbpf "$(P)01:Record-Sel" 1
dbpf "$(P)02:FileDir-SP" "/tmp"
dbpf "$(P)02:FileBase-SP" "BAR-"
dbpf "$(P)02:Record-Sel" 1

# FIXME -- should this bebe autosave/restore or some startup client?
iocshLoad "init_node.cmd" "NODE=01"
iocshLoad "init_node.cmd" "NODE=02"
