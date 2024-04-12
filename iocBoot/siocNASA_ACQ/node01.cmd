#!../../bin/darwin-x86/nasaAcq

###############################################################################
# Set up environment
epicsEnvSet(NASA_ACQ_BASE_IP, "192.168.19.101")
epicsEnvSet(NODE, "01")
epicsEnvSet(P, "NASA_ACQ:$(NODE):")
epicsEnvSet(EVG, "NASA_ACQ:") # this is the EVG node

###############################################################################
# Register support components
dbLoadDatabase "../../dbd/nasaAcq.dbd"
nasaAcq_registerRecordDeviceDriver pdbbase

###############################################################################
# Set up connections
var PSCDebug 0
var PSCUDPMaxPacketSize 1500
var PSCUDPMaxLenMB 23000

# Configure a single acquisition node
createPSCUDPFast("NASA_CTRL_EVG_FS", "$(NASA_ACQ_BASE_IP)", 54399, 0)
dbLoadRecords("../../db/nasaAcqSup.db", "P=$(P),EVG=$(EVG),NODE=,PORT=$(P)APP,IPADDR=$(NASA_ACQ_BASE_IP)")
dbLoadRecords("../../db/pscudpfast.db", "P=$(P),NAME=NASA_CTRL_EVG_FS")
dbLoadRecords("../../db/quartzAcq.db", "P=$(P),EVG=$(EVG),NAME=NASA_CTRL_EVG_FS,IPADDR=$(NASA_ACQ_BASE_IP), NELM=10000")

# Load record instances unique to event generator
dbLoadRecords("../../db/nasaEVG.db", "P=$(EVG),PORT=$(P)APP")

system "install -d as"
system "install -d as/$(NODE)"

set_savefile_path("$(PWD)/as", "/$(NODE)")
set_requestfile_path("$(PWD)/as", "/$(NODE)")

set_pass0_restoreFile("atf_settings.sav")
set_pass0_restoreFile("atf_values.sav")
set_pass1_restoreFile("atf_values.sav")
set_pass1_restoreFile("atf_waveforms.sav")

iocInit

makeAutosaveFileFromDbInfo("$(PWD)/as/$(NODE)/atf_settings.req", "autosaveFields_pass0")
makeAutosaveFileFromDbInfo("$(PWD)/as/$(NODE)/atf_values.req", "autosaveFields")
makeAutosaveFileFromDbInfo("$(PWD)/as/$(NODE)/atf_waveforms.req", "autosaveFields_pass1")

create_monitor_set("atf_settings.req", 10 , "")
create_monitor_set("atf_values.req", 10 , "")
create_monitor_set("atf_waveforms.req", 30 , "")
