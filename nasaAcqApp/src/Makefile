TOP=../..

include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE
#=============================

USR_CPPFLAGS += -DUSE_TYPED_RSET

LIBRARY += nasaSup
nasaSup_SRCS += goldenBoot.c
nasaSup_SRCS += copyTime.c
nasaSup_LIBS += $(EPICS_BASE_IOC_LIBS)
DBD += nasaSup.dbd

#=============================
# Build the IOC application

PROD_IOC = nasaAcq
# nasaAcq.dbd will be created and installed
DBD += nasaAcq.dbd

# nasaAcq.dbd will be made up from these files:
nasaAcq_DBD += base.dbd
nasaAcq_DBD += system.dbd

# Include dbd files from all support applications:
nasaAcq_DBD += asSupport.dbd
nasaAcq_DBD += pscUDPFast.dbd
nasaAcq_DBD += pscSig.dbd
nasaAcq_DBD += pscCore.dbd
nasaAcq_DBD += feed.dbd
nasaAcq_DBD += nasaSup.dbd

# Add all the support libraries needed by this IOC
nasaAcq_LIBS += autosave
nasaAcq_LIBS += pscSig
nasaAcq_LIBS += pscUDPFast
nasaAcq_LIBS += pscCore
nasaAcq_LIBS += feed
nasaAcq_LIBS += nasaSup

# nasaAcq_registerRecordDeviceDriver.cpp derives from nasaAcq.dbd
nasaAcq_SRCS += nasaAcq_registerRecordDeviceDriver.cpp

# Build the main IOC entry point on workstation OSs.
nasaAcq_SRCS_DEFAULT += nasaAcqMain.cpp
nasaAcq_SRCS_vxWorks += -nil-

ifneq (,$(CAPUTLOG))
nasaAcq_DBD += caPutLog.dbd
nasaAcq_LIBS += caPutLog
endif

ifneq (,$(RECSYNC))
nasaAcq_DBD += reccaster.dbd
nasaAcq_LIBS += reccaster
endif

ifdef LINSTAT_0_0_0
nasaAcq_DBD += linStat.dbd
nasaAcq_LIBS += linStat
endif

# Link QSRV
ifdef PVXS_MAJOR_VERSION # prefer v2
nasaAcq_DBD += pvxsIoc.dbd
nasaAcq_LIBS += pvxsIoc pvxs
else
ifdef EPICS_QSRV_MAJOR_VERSION # fallback to v1
nasaAcq_LIBS += qsrv
nasaAcq_LIBS += $(EPICS_BASE_PVA_CORE_LIBS)
nasaAcq_DBD += PVAServerRegister.dbd
nasaAcq_DBD += qsrv.dbd
endif
endif

# Finally link to the EPICS Base libraries
nasaAcq_LIBS += $(EPICS_BASE_IOC_LIBS)

#===========================

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE

