# Configure a single acquisition node

nasaAcqConfigure("NASA_CMD$(NODE)", "$(NASA_ACQ_BASE_IP)$(NODE)", 0)
asynSetTraceMask("NASA_CMD$(NODE)_UDP", -1, 0x$(NODE))
asynSetTraceIOMask("NASA_CMD$(NODE)"_UDP, -1, 0x04)
dbLoadRecords("../../db/nasaAcqSup.db", "P=$(P),NODE=$(NODE),PORT=NASA_CMD")

#createPSCUDP("NASA_CTRL$(NODE)", "$(NASA_ACQ_BASE_IP)$(NODE)", 55000, 1)
createPSCUDPFast("NASA_ACQ$(NODE)", "$(NASA_ACQ_BASE_IP)$(NODE)", 54389, 0)
dbLoadRecords("../../db/pscudpfast.db", "P=$(P),NAME=NASA_ACQ$(NODE)")

