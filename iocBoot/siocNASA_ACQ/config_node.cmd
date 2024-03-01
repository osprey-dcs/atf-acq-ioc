# Configure a single acquisition node

nasaAcqConfigure("NASA_CMD$(NODE)", "$(NASA_ACQ_BASE_IP)$(NODE)", 0)
asynSetTraceMask("NASA_CMD$(NODE)_UDP", -1, 0x01)
asynSetTraceIOMask("NASA_CMD$(NODE)"_UDP, -1, 0x04)
dbLoadRecords("../../db/nasaAcqSup.db", "P=$(P),NODE=$(NODE),PORT=NASA_CMD")

createPSCUDPFast("NASA_ACQ$(NODE)", "$(NASA_ACQ_BASE_IP)$(NODE)", 54389, 0)
dbLoadRecords("../../db/pscudpfast.db", "P=$(P)$(NODE):,NAME=NASA_ACQ$(NODE)")

