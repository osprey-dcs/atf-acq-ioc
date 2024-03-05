# Configure a single acquisition node
createPSCUDP("NASA_CTRL$(NODE)", "$(NASA_ACQ_BASE_IP)$(NODE)", 54398, 0)
createPSCUDPFast("NASA_ACQ$(NODE)", "$(NASA_ACQ_BASE_IP)$(NODE)", 54399, 0)
dbLoadRecords("../../db/nasaAcqSup.db", "P=$(P),NODE=$(NODE),PORT=NASA_CTRL")
dbLoadRecords("../../db/pscudpfast.db", "P=$(P)$(NODE):,NAME=NASA_ACQ$(NODE)")
