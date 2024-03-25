#!../../bin/linux-x86_64/nasaAcq

###############################################################################
# Set up environment
epicsEnvSet(NASA_ACQ_BASE_IP, "192.168.79.18")
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
dbLoadRecords("../../db/quartzAcq.db", "P=$(P),EVG=$(EVG),NAME=NASA_CTRL_EVG_FS,IPADDR=$(NASA_ACQ_BASE_IP), NELM=10000")

# Load record instances unique to event generator
dbLoadRecords("../../db/nasaEVG.db", "P=$(EVG),PORT=NASA_CTRL_EVG")

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

dbpf NASA_ACQ:01:SA:Ch01:ASLO 1.6185828757359167e-06
dbpf NASA_ACQ:01:SA:Ch02:ASLO 1.618724210580322e-06
dbpf NASA_ACQ:01:SA:Ch03:ASLO 1.618972725882369e-06
dbpf NASA_ACQ:01:SA:Ch04:ASLO 1.618427457074543e-06
dbpf NASA_ACQ:01:SA:Ch05:ASLO 1.6185291380378197e-06
dbpf NASA_ACQ:01:SA:Ch06:ASLO 1.6185043422672805e-06
dbpf NASA_ACQ:01:SA:Ch07:ASLO 1.6190309456096884e-06
dbpf NASA_ACQ:01:SA:Ch08:ASLO 1.6184775024429116e-06
dbpf NASA_ACQ:01:SA:Ch09:ASLO 1.6187312726554775e-06
dbpf NASA_ACQ:01:SA:Ch10:ASLO 1.6187105811522936e-06
dbpf NASA_ACQ:01:SA:Ch11:ASLO 1.6189994355774233e-06
dbpf NASA_ACQ:01:SA:Ch12:ASLO 1.6187857416834407e-06
dbpf NASA_ACQ:01:SA:Ch13:ASLO 1.6188240161637225e-06
dbpf NASA_ACQ:01:SA:Ch14:ASLO 1.6189017362076446e-06
dbpf NASA_ACQ:01:SA:Ch15:ASLO 1.6186350370788054e-06
dbpf NASA_ACQ:01:SA:Ch16:ASLO 1.6187068562203505e-06
dbpf NASA_ACQ:01:SA:Ch17:ASLO 1.6190756120220637e-06
dbpf NASA_ACQ:01:SA:Ch18:ASLO 1.6192652484586392e-06
dbpf NASA_ACQ:01:SA:Ch19:ASLO 1.6187871420046091e-06
dbpf NASA_ACQ:01:SA:Ch20:ASLO 1.6187199756763401e-06
dbpf NASA_ACQ:01:SA:Ch21:ASLO 1.6194381563042348e-06
dbpf NASA_ACQ:01:SA:Ch22:ASLO 1.6191014811218072e-06
dbpf NASA_ACQ:01:SA:Ch23:ASLO 1.618765929613831e-06
dbpf NASA_ACQ:01:SA:Ch24:ASLO 1.6189464607535724e-06
dbpf NASA_ACQ:01:SA:Ch25:ASLO 1.61941763279409e-06
dbpf NASA_ACQ:01:SA:Ch26:ASLO 1.6191122898150834e-06
dbpf NASA_ACQ:01:SA:Ch27:ASLO 1.6190251496160483e-06
dbpf NASA_ACQ:01:SA:Ch28:ASLO 1.6194614972018447e-06
dbpf NASA_ACQ:01:SA:Ch29:ASLO 1.6193750490479661e-06
dbpf NASA_ACQ:01:SA:Ch30:ASLO 1.6192459801390538e-06
dbpf NASA_ACQ:01:SA:Ch31:ASLO 1.6190570788797661e-06
dbpf NASA_ACQ:01:SA:Ch32:ASLO 1.618922333961534e-06

dbpf NASA_ACQ:01:SA:Ch01:ESLO 11834.3195266272
dbpf NASA_ACQ:01:SA:Ch02:ESLO 12437.8109452736
dbpf NASA_ACQ:01:SA:Ch03:ESLO 12500
dbpf NASA_ACQ:01:SA:Ch04:ESLO 11299.4350282486
dbpf NASA_ACQ:01:SA:Ch05:ESLO 10718.1136120043
dbpf NASA_ACQ:01:SA:Ch06:ESLO 13037.8096479791
dbpf NASA_ACQ:01:SA:Ch07:ESLO 10493.1794333683
dbpf NASA_ACQ:01:SA:Ch08:ESLO 12437.8109452736
dbpf NASA_ACQ:01:SA:Ch09:ESLO 13192.6121372032
dbpf NASA_ACQ:01:SA:Ch10:ESLO 10976.9484083425
dbpf NASA_ACQ:01:SA:Ch11:ESLO 12836.9704749679
dbpf NASA_ACQ:01:SA:Ch12:ESLO 12820.5128205128
dbpf NASA_ACQ:01:SA:Ch13:ESLO 12903.2258064516
