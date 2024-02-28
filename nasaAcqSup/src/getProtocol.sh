#!/bin/sh

APPSRC="../../../Workspace/NASA_ACQ/src"

set -ex
for f in iocFPGAprotocol.h nasaAcqProtocol.h
do
    cp "$APPSRC/$f" .
done
