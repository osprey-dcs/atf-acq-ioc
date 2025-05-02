#!/usr/bin/env python

import argparse
import epics
import sys
import time

# FIXME -- should allow testing of MPS outputs other than first
parser = argparse.ArgumentParser(description='Test MPS', \
         formatter_class=argparse.ArgumentDefaultsHelpFormatter, \
         epilog="""It is assumed that the 'MPS:required records on EVG and EVG
                   nodes are correct.  If not you'll likely get warnings about
                   the hardware output being asserted or not asserted.  It is
                   also assumed that the analog channels are not faulted.""")
parser.add_argument('-n', '--node', default=1, help='Node number')
parser.add_argument('-o', '--output', default=1, choices=range(1,5), help='MPS output number')
parser.add_argument('-p', '--prefix', default='FDAS:', help='PV name prefix')
args = parser.parse_args()
nodeStr = '%02d:' % args.node
outputStr = '%02d' % args.output
outputBit = 1 << (args.output - 1)

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
def checkStatus(expectStatus, \
               expectFirstInputs=None, \
               expectFirstSeconds=None, \
               expectFirstTicks=None):
    time.sleep(0.2)
    failed = False
    trippedPV_PROC.put(1, wait=True)
    tripped = (trippedPV.get() & outputBit) != 0
    statusPV_PROC.put(1, wait=True)
    status = statusPV.get()
    expectTripped = (status & 0x1) != 0
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
    print(" -- %s" % ("FAIL" if failed else "PASS"), end='')
    if (tripped != expectTripped):
        print(" -- Warning: hardware output is%s asserted." % \
                                            ("" if tripped else "n ot"), end='')
    print("")
    if (failed): raise(Exception("MPS status"))
    
invertPV = openAndStash('MPS:invert')
goodStatePV = openAndStash('MPS:goodState:%s' % (outputStr))
chkInputsPV = openAndStash('MPS:chkInputs:%s' % (outputStr))

statusPV = openTest('MPS:status:%s' % (outputStr))
statusPV_PROC = openTest('MPS:status:%s.PROC' % (outputStr))
firstInputsPV = openTest('MPS:firstInputs:%s' % (outputStr))
firstInputsPV_PROC = openTest('MPS:firstInputs:%s.PROC' % (outputStr))
firstSecondsPV = openTest('MPS:firstSeconds:%s' % (outputStr))
firstSecondsPV_PROC = openTest('MPS:firstSeconds:%s.PROC' % (outputStr))
firstTicksPV = openTest('MPS:firstTicks:%s' % (outputStr))
firstTicksPV_PROC = openTest('MPS:firstTicks:%s.PROC' % (outputStr))

clearPV = epics.PV(args.prefix + 'MPS:clear')
trippedPV = openEVG('MPS:tripped')
trippedPV_PROC = openEVG('MPS:tripped.PROC')

try:
    for inputIndex in range(0,4):
        inputBit = 1 << inputIndex
        ########################################################################
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

        # Clear any leftover trips
        clearPV.put(1, wait=True)

        #######################################################################
        # Ensure that preliminary state is correct
        checkStatus(0)

        ########################################################################
        # Ensure that an important input going bad causes a trip
        invertPV.put(inverted ^ inputBit, wait=True)
        checkStatus((inputBit << 16) | 0x3, inputBit)

        ########################################################################
        # Ensure that important input going good removes fault but not the trip
        invertPV.put(inverted, wait=True)
        checkStatus(0x00001, inputBit)

        ########################################################################
        # Ensure that an input going bad causes fault but leaves 
        # first trip values unchanged
        firstTripInputs = firstInputsPV.get()
        firstTripSeconds = firstSecondsPV.get()
        firstTripTicks = firstTicksPV.get()
        for i in range(0,4):
            b = 1 << i
            invertPV.put(inverted ^ b, wait=True)
            checkStatus((b << 16) | 0x3, firstTripInputs, firstTripSeconds, firstTripTicks)

            ####################################################################
            # Ensure that input going good removes fault but not the trip
            invertPV.put(inverted, wait=True)
            checkStatus(0x1, firstTripInputs, firstTripSeconds, firstTripTicks)

        ########################################################################
        # Ensure that trip clear has the desired effect
        clearPV.put(1, wait=True)
        checkStatus(0)

finally:
    for l in  restoreList:
        l[0].put(l[1])
