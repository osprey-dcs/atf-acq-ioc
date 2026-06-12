# Must set ENV:
#   NODE_IP - Device IP address
#   SYS     - System record name prefix
#   NODE    - Two digit node address.  EVG node is 01, others from 02 ...
#   AS_DIR  - Autosave directory (must be writable)

###############################################################################
# Set up environment
epicsEnvSet(P, "$(SYS)$(NODE):")
epicsEnvSet(EVG, "$(SYS)")

###############################################################################
# Register support components
dbLoadDatabase "../../dbd/nasaAcq.dbd"
nasaAcq_registerRecordDeviceDriver pdbbase

###############################################################################
# Set up connections
var PSCDebug 0

# target buffering period
var PSCUDPBufferPeriod 1.0

# OS socket buffer size.
#  sudo sysctl net.core.rmem_max=25000000
var(PSCUDPSetSockBuf, 25000000)

# ethernet MTU (excludes IP/UDP overhead, so larger than strictly necessary)
var PSCUDPMaxPacketSize 1500

# 250e3 samp per sec per channel / 14 samples per packet per channel = 17857
# round up...
var PSCUDPMaxPacketRate 18000

# max. .dat file size before rotating
var PSCUDPMaxLenMB 230000

# Configure a single acquisition node
createPSCUDPFast("NASA_CTRL_EVG_FS", "$(NODE_IP)", 54399, 0)
dbLoadRecords("../../db/nasaAcqSup.db", "P=$(P),EVG=$(EVG),NODE=,PORT=$(P)APP,IPADDR=$(NODE_IP)")
dbLoadRecords("../../db/pscudpfast.db", "P=$(P),NAME=NASA_CTRL_EVG_FS")
dbLoadRecords("../../db/quartzAcq.db", "P=$(P),EVG=$(EVG),PORT=$(P)APP,NAME=NASA_CTRL_EVG_FS,IPADDR=$(NODE_IP),NELM=10000")

dbLoadRecords("../../db/save_restoreStatus.db", "P=$(P)AS:")
save_restoreSet_status_prefix("$(P)AS:")

system "install -d $(AS_DIR)"

set_savefile_path("$(AS_DIR)", "")
set_requestfile_path("$(AS_DIR)", "")

set_pass0_restoreFile("atf_settings.sav")
set_pass0_restoreFile("atf_values.sav")
set_pass1_restoreFile("atf_values.sav")
set_pass1_restoreFile("atf_waveforms.sav")

iocInit

makeAutosaveFileFromDbInfo("$(AS_DIR)/atf_settings.req", "autosaveFields_pass0")
makeAutosaveFileFromDbInfo("$(AS_DIR)/atf_values.req", "autosaveFields")
makeAutosaveFileFromDbInfo("$(AS_DIR)/atf_waveforms.req", "autosaveFields_pass1")

create_monitor_set("atf_settings.req", 10 , "")
create_monitor_set("atf_values.req", 10 , "")
create_monitor_set("atf_waveforms.req", 30 , "")
