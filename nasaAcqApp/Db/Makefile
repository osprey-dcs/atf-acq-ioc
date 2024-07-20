TOP=../..
include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE

#----------------------------------------------------
# Create and install (or just install) into <top>/db
# databases, templates, substitutions like this
DB += nasaEVG.db
DB += nasaAcqSup.db
DB_INSTALLS += $(PSCDRV)/db/pscudpfast.db
DB_INSTALLS += $(AUTOSAVE)/db/save_restoreStatus.db

DB += quartzAcq.db

ifdef LINSTAT_0_0_0
DB_INSTALLS += $(wildcard $(LINSTAT_TOP)/db/linStat*.db)
endif

#----------------------------------------------------
# If <anyname>.db template is not named <anyname>*.template add
# <anyname>_template = <templatename>

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE

