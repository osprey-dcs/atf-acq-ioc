TOP=../..

include $(TOP)/configure/CONFIG
#----------------------------------------
#  ADD MACRO DEFINITIONS AFTER THIS LINE
#=============================

#==================================================
# build a support library

LIBRARY_IOC += nasaAcqSup

# xxxRecord.h will be created from xxxRecord.dbd
#DBDINC += xxxRecord
# install nasaAcqSup.dbd into <top>/dbd
DBD += nasaAcqSup.dbd

# specify all source files to be compiled and added to the library
nasaAcqSup_SRCS += nasaAcq

nasaAcqSup_LIBS += $(EPICS_BASE_IOC_LIBS)

#===========================

include $(TOP)/configure/RULES
#----------------------------------------
#  ADD RULES AFTER THIS LINE

