#!/bin/sh

export JAVA_HOME="/Applications/CSS_Phoebus.app/jdk"
PATH="$JAVA_HOME/Contents/Home/bin:$PATH"

export P="NASAACQ:"
export R="0:"

export arch="$EPICS_HOST_ARCH"
/Applications/CSS_Phoebus.app/phoebus-4.6.10-SNAPSHOT/phoebus.sh -resource "file://$PWD/nasaACQ_sysmon.bob?app=display_runtime"
