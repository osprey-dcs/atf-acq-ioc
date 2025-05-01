#!/usr/bin/env python

import argparse
import epics
import sys
import time

# FIXME -- should allow testing of MPS outputs other than first
parser = argparse.ArgumentParser(description='Test MPS', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-n', '--node', default=1, help='Node number')
parser.add_argument('-p', '--prefix', default='FDAS:', help='PV name prefix')
args = parser.parse_args()
nodeStr = '%02d:' % args.node

#
# Open connection to event generator (MPS central node)
#
def openEVG(name):
    pv = epics.PV(args.prefix + '01:' + name)
    return pv

#
# Open connection to node under test
#
def openTest(name):
    pv = epics.PV(args.prefix + nodeStr + name)
    return pv

#
# Open connection to test node and save value for later restoration
#
restoreList = [];
def openAndStash(name):
    pv = openTest(name)
    val = pv.get()
    restoreList.append([pv, val])
    return pv

# Check MPS status
def checkStatus(expectTripped, expectStatus, \
               expectFirstInputs=None, \
               expectFirstSeconds=None, \
               expectFirstTicks=None):
    failed = False
    trippedPV_PROC.put(1, wait=True)
    tripped = trippedPV.get()
    if (tripped != expectTripped):
        print("Tripped  " if tripped != 0 else "Untripped  ", end='')
        failed = True
    statusPV_PROC.put(1, wait=True)
    status = statusPV.get()
    print("Status:%06X" % (status), end='')
    if (status != expectStatus):
        print(" Expect:%06X" % (expectStatus), end='')
        failed = True
    if (expectFirstInputs != None):
        firstInputsPV_PROC.put(1, wait=True)
        firstSecondsPV_PROC.put(1, wait=True)
        firstTicksPV_PROC.put(1, wait=True)
        firstInputs = firstInputsPV.get()
        firstSeconds = firstSecondsPV.get()
        firstTicks = firstTicksPV.get()
        print("  First fault inputs:%X seconds:%d ticks:%d" % \
                                (firstInputs, firstSeconds, firstTicks), end='')
        if (firstInputs != expectFirstInputs):
          print("--Expect:%X" % (expectFirstInputs), end='')
          failed = True
        if (expectFirstSeconds != None):
            if (firstSeconds != expectFirstSeconds): failed = True
            if (firstTicks != expectFirstTicks): failed = True
    print(" -- %s" % ("FAIL" if failed else "PASS"))
    if (failed): raise(Exception("MPS status"))
    
invertPV = openAndStash('MPS:invert')
goodStatePV = openAndStash('MPS:goodState:01')
chkInputsPV = openAndStash('MPS:chkInputs:01')

statusPV = openTest('MPS:status:01')
statusPV_PROC = openTest('MPS:status:01.PROC')
firstInputsPV = openTest('MPS:firstInputs:01')
firstInputsPV_PROC = openTest('MPS:firstInputs:01.PROC')
firstSecondsPV = openTest('MPS:firstSeconds:01')
firstSecondsPV_PROC = openTest('MPS:firstSeconds:01.PROC')
firstTicksPV = openTest('MPS:firstTicks:01')
firstTicksPV_PROC = openTest('MPS:firstTicks:01.PROC')

clearPV = epics.PV(args.prefix + 'MPS:clear')
evgRequiredPV = openEVG('MPS:required')
trippedPV = openEVG('MPS:tripped')
trippedPV_PROC = openEVG('MPS:tripped.PROC')

try:
    ###########################################################################
    # Prepare for test
    # Make all inputs on the test node 'unimportant'
    chkInputsPV.put(0xF, wait=True)

    # Invert inputs to make all inputs look low
    inverted = invertPV.get()
    inputState = (statusPV.get() >> 16) & 0xF
    inverted ^= inputState

    # Make 0 the good state for all inputs
    goodStatePV.put(0, wait=True)

    # Make all inputs on the test node 'important'
    chkInputsPV.put(0xF, wait=True)

    # FIXME - need to make the test node important on its upstream fanout node

    # Make the test node branch important to the MPS central node
    # FIXME -- hardwire to the first MPS upstream fiber for now
    evgRequiredPV.put(2, wait=True)

    # Clear any leftover trips
    clearPV.put(1, wait=True)

    ###########################################################################
    # Ensure that preliminary state is correct
    checkStatus(0, 0)

    ###########################################################################
    # Ensure that an important input going bad causes a trip
    invertPV.put(inverted ^ 0x1, wait=True)
    checkStatus(1, 0x10003, 0x1)

    ###########################################################################
    # Ensure that important input going good removes fault but not the trip
    invertPV.put(inverted, wait=True)
    checkStatus(1, 0x00001, 0x1)

    ###########################################################################
    # Ensure that another important input going bad causes a fault but leaves first trip values unchanged
    firstTripSeconds = firstSecondsPV.get()
    firstTripTicks = firstTicksPV.get()
    invertPV.put(inverted ^ 0x2, wait=True)
    checkStatus(1, 0x20003, 0x1, firstTripSeconds, firstTripTicks)

    ###########################################################################
    # Ensure that important input going good removes fault but not the trip
    invertPV.put(inverted, wait=True)
    checkStatus(1, 0x00001, 0x1)

    ###########################################################################
    # Ensure that trip clear has the desired effect
    clearPV.put(1, wait=True)
    checkStatus(0, 0)

finally:
    for l in  restoreList:
        l[0].put(l[1])
