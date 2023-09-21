TOP=../..

include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE
#=============================

#=============================
# Build the IOC application

PROD_IOC = nasaAcq
# nasaAcq.dbd will be created and installed
DBD += nasaAcq.dbd

# nasaAcq.dbd will be made up from these files:
nasaAcq_DBD += base.dbd

# Include dbd files from all support applications:
#nasaAcq_DBD += pscSig.dbd
nasaAcq_DBD += pscUDPFast.dbd
nasaAcq_DBD += pscCore.dbd

# Add all the support libraries needed by this IOC
nasaAcq_LIBS += pscSig
nasaAcq_LIBS += pscUDPFast
nasaAcq_LIBS += pscCore
myioc_SYS_LIBS += event_core event_extra
myioc_SYS_LIBS_DEFAULT = event_pthreads

# nasaAcq_registerRecordDeviceDriver.cpp derives from nasaAcq.dbd
nasaAcq_SRCS += nasaAcq_registerRecordDeviceDriver.cpp

# Build the main IOC entry point on workstation OSs.
nasaAcq_SRCS_DEFAULT += nasaAcqMain.cpp
nasaAcq_SRCS_vxWorks += -nil-

# Add support from base/src/vxWorks if needed
#nasaAcq_OBJS_vxWorks += $(EPICS_BASE_BIN)/vxComLibrary

# Finally link to the EPICS Base libraries
nasaAcq_LIBS += $(EPICS_BASE_IOC_LIBS)

# Link QSRV (pvAccess Server) if available
ifdef EPICS_QSRV_MAJOR_VERSION
nasaAcq_LIBS += qsrv
nasaAcq_LIBS += $(EPICS_BASE_PVA_CORE_LIBS)
nasaAcq_DBD += PVAServerRegister.dbd
nasaAcq_DBD += qsrv.dbd
endif

#===========================

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE

