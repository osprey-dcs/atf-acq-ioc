/*
 * MIT License
 *
 * Copyright (c) 2021 Osprey DCS
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/*
 * ASYN driver to communicate with NASA ACQ node
 */

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <inttypes.h>
#include <math.h>
#include <errno.h>
#include <cantProceed.h>
#include <errlog.h>
#include <epicsExit.h>
#include <epicsExport.h>
#include <epicsString.h>
#include <epicsThread.h>
#include <iocsh.h>
#include <drvAsynIPPort.h>
#include <asynStandardInterfaces.h>
#include <asynCommonSyncIO.h>
#include <asynOctetSyncIO.h>
#include "iocFPGAprotocol.h"
#include "nasaAcqProtocol.h"

/*
 * Application-specific values
 */
/*
 * Internal addresses (augment those in XXXprotocol.h)
 */
#define AHI_IO_STATISTICS   0xF000

/*
 * How often to retry a command
 */
#define COMMAND_RETRY_LIMIT 5

/*
 * Decode system monitor readback
 */
#define ALO_SYSMON_INT32        0x000
#define ALO_SYSMON_INT16_LO     0x100
#define ALO_SYSMON_INT16_HI     0x200
#define ALO_SYSMON_UINT16_LO    0x300
#define ALO_SYSMON_UINT16_HI    0x400

/*
 * Links to lower-level UDP I/O
 */
struct udpLink {
    const char  *portName;
    const char  *hostName;
    asynUser    *pasynUserCommon;
    asynUser    *pasynUserOctet;
    int          isConnected;
};

/*
 * Driver private storage
 */
typedef struct drvPvt {
    /*
     * Command/reply client
     */
    struct udpLink          cmdLink;
    struct fpgaIOCpacket    command;
    struct fpgaIOCpacket    reply;

    /*
     * The interfaces we provide
     */
    asynUser              *pasynUser;  /* For diagnostic messages */
    asynStandardInterfaces asynInterfaces;

    /*
     * Statistics
     */
    unsigned long   commandCount[COMMAND_RETRY_LIMIT+1];
    unsigned long   commandFailedCount;
    unsigned long   diagnosticPacketsLost;

} drvPvt;

/*
 * Report an invalid address
 */
static asynStatus
badAddress(asynUser *pasynUser)
{
    epicsSnprintf(pasynUser->errorMessage, pasynUser->errorMessageSize,
                                                                 "Bad address");
    return asynError;
}

/*
 * Push values into system monitor SCAN="I/O Intr" records
 */
static void
processMonitors(drvPvt *pdpvt, asynUser *pasynUser, int cmdAHi, int replyArgc)
{
    ELLLIST *pclientList;
    interruptNode *pnode;
    epicsTimeStamp ts;
    asynStatus status;

    epicsTimeGetCurrent(&ts);
    pasynManager->interruptStart(pdpvt->asynInterfaces.int32InterruptPvt,
                                                                  &pclientList);
    pnode = (interruptNode *)ellFirst(pclientList);
    while (pnode) {
        asynInt32Interrupt *int32Interrupt = pnode->drvPvt;
        int aHi = int32Interrupt->addr & FPGA_IOC_CMD_HI_MASK;
        int aLo = int32Interrupt->addr & FPGA_IOC_CMD_LO_MASK;
        int idx = int32Interrupt->addr & FPGA_IOC_CMD_IDX_MASK;
        epicsUInt32 value;
        pnode = (interruptNode *)ellNext(&pnode->node);
        if (aHi != cmdAHi) {
            continue;
        }
        if ((replyArgc >= 1) && (idx < replyArgc)) {
            value = pdpvt->reply.args[idx];
            status = asynSuccess;
        }
        else {
            value = 0;
            status = asynError;
        }
        switch (aLo) {
        case ALO_SYSMON_INT32:                                            break;
        case ALO_SYSMON_INT16_LO:  value = (epicsInt16)(value & 0xFFFF);  break;
        case ALO_SYSMON_INT16_HI:  value = (epicsInt16)(value >> 16);     break;
        case ALO_SYSMON_UINT16_LO: value = value & 0xFFFF;                break;
        case ALO_SYSMON_UINT16_HI: value = value >> 16;                   break;
        default: continue;
        }
        int32Interrupt->pasynUser->timestamp = ts;
        int32Interrupt->pasynUser->auxStatus = status;
        int32Interrupt->callback(int32Interrupt->userPvt,
                                 int32Interrupt->pasynUser, value);
    }
    pasynManager->interruptEnd(pdpvt->asynInterfaces.int32InterruptPvt);
}

/*
 * Send command and receive reply.
 * All communication with the FPGA passes through here.
 * Return number of reply arguments.
 */
static int
processCommand(drvPvt *pdpvt, asynUser *pasynUser, int cmdArgc)
{
    int retryCount = 0;
    double timeout = 0.2;
    size_t nwrite, nwritten, nread;
    int eomReason;
    asynStatus status;

    asynPrint(pasynUser, ASYN_TRACEIO_DRIVER, "Send 0x%"PRIX32"[%d]\n",
                                               pdpvt->command.command, cmdArgc);
    pdpvt->command.sequenceNumber++;
    for (;;) {
        if (!pdpvt->cmdLink.isConnected) {
            status = pasynCommonSyncIO->connectDevice(
                                                pdpvt->cmdLink.pasynUserCommon);
            if (status == asynSuccess) {
                pdpvt->cmdLink.isConnected = 1;
            }
            else {
                return -1;
            }
        }
        nwrite = FPGA_IOC_ARGC_TO_SIZE(cmdArgc);
        status = pasynOctetSyncIO->writeRead(pdpvt->cmdLink.pasynUserOctet,
                           (char *)&pdpvt->command, nwrite,
                           (char *)&pdpvt->reply, sizeof(pdpvt->reply),
                           timeout, &nwritten, &nread, &eomReason);
        if ((status == asynSuccess)
         && (nwritten == nwrite)
         && (nread >= FPGA_IOC_ARGC_TO_SIZE(0))
         && (nread <= FPGA_IOC_ARGC_TO_SIZE(FPGA_IOC_ARG_CAPACITY))
         && (pdpvt->reply.magic == NASA_ACQ_MAGIC)
         && (pdpvt->reply.command == pdpvt->command.command)
         && (pdpvt->reply.sequenceNumber == pdpvt->command.sequenceNumber)) {
            int replyArgc = FPGA_IOC_SIZE_TO_ARGC(nread);
            asynPrint(pasynUser, ASYN_TRACEIO_DRIVER, "Received %d\n",
                                               replyArgc);
            pdpvt->commandCount[retryCount]++;
            return replyArgc;
        }
        if (++retryCount > COMMAND_RETRY_LIMIT) {
            pdpvt->commandFailedCount++;
            if (status == asynSuccess) {
                epicsSnprintf(pasynUser->errorMessage,
                              pasynUser->errorMessageSize,
                                                  "Invalid response from FPGA");
            }
            else {
                epicsSnprintf(pasynUser->errorMessage,
                              pasynUser->errorMessageSize, "NASA I/O error:%s",
                                   pdpvt->cmdLink.pasynUserOctet->errorMessage);
            }
            return -1;
        }
        if (retryCount == COMMAND_RETRY_LIMIT) {
            pasynCommonSyncIO->disconnectDevice(pdpvt->cmdLink.pasynUserCommon);
            pdpvt->cmdLink.isConnected = 0;
        }
        timeout = 1.0;
    }
}

/*************************** asynCommon methods ***************************/
static void
showLinkStatus(FILE *fp, struct udpLink *lp)
{
    fprintf(fp, "%s: %s %s\n", lp->portName, lp->hostName,
                                lp->isConnected ? "Connected" : "Disconnected");
}

static void
asynCommonReport(void *pvt, FILE *fp, int details)
{
    drvPvt *pdpvt = (drvPvt *)pvt;
    showLinkStatus(fp, &pdpvt->cmdLink);
}

static asynStatus
asynCommonConnect(void *pvt, asynUser *pasynUser)
{
    pasynManager->exceptionConnect(pasynUser);
    return asynSuccess;
}

static asynStatus
asynCommonDisconnect(void *pvt, asynUser *pasynUser)
{
    pasynManager->exceptionDisconnect(pasynUser);
    return asynSuccess;
}
static asynCommon commonMethods = { asynCommonReport,
                                    asynCommonConnect,
                                    asynCommonDisconnect };

/*************************** asynInt32 methods ***************************/
static asynStatus
asynInt32Write(void *pvt, asynUser *pasynUser, epicsInt32 value)
{
    drvPvt *pdpvt = (drvPvt *)pvt;
    int address = 0;
    int cmdArgc, replyArgc;
    asynStatus status;

    if ((status = pasynManager->getAddr(pasynUser, &address)) != asynSuccess) {
        return status;
    }
    switch (address & (FPGA_IOC_CMD_HI_MASK | FPGA_IOC_CMD_LO_MASK)) {
    case FPGA_IOC_CMD_HI_LONGOUT|FPGA_IOC_LONGOUT_LO_NO_ARGS:
        cmdArgc = 0;
        break;
    case FPGA_IOC_CMD_HI_LONGOUT | FPGA_IOC_LONGOUT_LO_ONE_ARG:
    case FPGA_IOC_CMD_HI_LONGOUT | NASA_LONGOUT_LO_INPUT_ENABLE:
    case FPGA_IOC_CMD_HI_LONGOUT | NASA_LONGOUT_LO_INPUT_COUPLING:
    case FPGA_IOC_CMD_HI_LONGOUT | NASA_LONGOUT_LO_CALIB_OFFSET:
    case FPGA_IOC_CMD_HI_LONGOUT | NASA_LONGOUT_LO_CALIB_GAIN:
        cmdArgc = 1;
        pdpvt->command.args[0] = value;
        break;
    default: return badAddress(pasynUser);
    }
    pdpvt->command.command = address;
    replyArgc = processCommand(pdpvt, pasynUser, cmdArgc);
    if (replyArgc < 0) {
        return asynError;
    }
    return asynSuccess;
}

static asynStatus
asynInt32Read(void *pvt, asynUser *pasynUser, epicsInt32 *value)
{
    drvPvt *pdpvt = (drvPvt *)pvt;
    int address = 0, aHi, idx;
    int replyArgc;
    asynStatus status;

    if ((status = pasynManager->getAddr(pasynUser, &address)) != asynSuccess) {
        return status;
    }
    aHi = address & FPGA_IOC_CMD_HI_MASK;
    idx = address & FPGA_IOC_CMD_IDX_MASK;
    switch (aHi) {
    case FPGA_IOC_CMD_HI_LONGIN:
    case FPGA_IOC_CMD_HI_SYSMON:
        pdpvt->command.command = address;
        if ((replyArgc = processCommand(pdpvt, pasynUser, 0)) >= 1) {
            *value = pdpvt->reply.args[0];
        }
        if (aHi == FPGA_IOC_CMD_HI_SYSMON) {
            processMonitors(pdpvt, pasynUser, aHi, replyArgc);
        }
        return (replyArgc >= 1) ? asynSuccess : asynError;

    case AHI_IO_STATISTICS:
        switch (idx) {
        default:
            if (idx <= COMMAND_RETRY_LIMIT) {
                *value = pdpvt->commandCount[idx];
                return asynSuccess;
            }
            break;
        case COMMAND_RETRY_LIMIT + 1:
            *value = pdpvt->commandFailedCount;
            return asynSuccess;
        case COMMAND_RETRY_LIMIT + 2:
            *value = pdpvt->diagnosticPacketsLost;
            return asynSuccess;
        }
        break;
    }
    return badAddress(pasynUser);
}
static asynInt32 int32Methods = { .write=asynInt32Write, .read=asynInt32Read };

/*
 * asynOctet methods
 */
static asynStatus
octetRead(void *pvt, asynUser *pasynUser, char *data, size_t maxchars, size_t *nTransferred, int *eomReason)
{
    drvPvt *pdpvt = (drvPvt *)pvt;
    asynStatus status;
    int address, replyArgc;
    int len;
    time_t tBuf;

    if ((status = pasynManager->getAddr(pasynUser, &address)) != asynSuccess)
        return status;
    switch (address) {
    case FPGA_IOC_CMD_HI_LONGIN |
         FPGA_IOC_LONGIN_LO_BUILD_DATE |
         FPGA_IOC_LONGIN_BUILD_DATE_IDX_FIRMWARE: break;
    case FPGA_IOC_CMD_HI_LONGIN |
         FPGA_IOC_LONGIN_LO_BUILD_DATE |
         FPGA_IOC_LONGIN_BUILD_DATE_IDX_SOFTWARE: break;
    default:
        return badAddress(pasynUser);
    }
    pdpvt->command.command = address;
    replyArgc = processCommand(pdpvt, pasynUser, 0);
    if (replyArgc < 0) {
        return asynError;
    }
    if (replyArgc != 1) {
        epicsSnprintf(pasynUser->errorMessage, pasynUser->errorMessageSize,
                                                               "Bad read size");
        return asynError;
    }
    tBuf = pdpvt->reply.args[0];
    len = strftime(data, maxchars, "%F %T", localtime(&tBuf));
    if (len == 0) {
        epicsSnprintf(pasynUser->errorMessage, pasynUser->errorMessageSize,
                                            "Target string buffer too small");
        return asynError;
    }
    *nTransferred = len;
    if (eomReason) {
        *eomReason = ASYN_EOM_END;
        if (len == maxchars) *eomReason |= ASYN_EOM_CNT;
    }
    return asynSuccess;
}
static asynOctet octetMethods = { .read = octetRead };

/*************************** Configuration ***************************/

/*
 * Set up a UDP link
 */
static int
setupLink(struct udpLink *l,
          const char *portName, const char *ext,
          const char *hostName, unsigned int udpPortNumber, int priority)
{
    char *cp;

    cp = mallocMustSucceed(strlen(portName)+strlen(ext)+1, "NASA_ACQ");
    sprintf(cp, "%s%s", portName, ext);
    l->portName = cp;
    cp = mallocMustSucceed(strlen(hostName)+20, "NASA_ACQ");
    sprintf(cp, "%s:%u UDP", hostName, udpPortNumber);
    l->hostName = cp;
    /* No autoconnect, No process EOS */
    drvAsynIPPortConfigure(l->portName, l->hostName, priority, 1, 1);
    if (pasynCommonSyncIO->connect(l->portName, 0, &l->pasynUserCommon, NULL)
                                                               != asynSuccess) {
        errlogPrintf("Can't connect to %s common sync I/O\n", l->portName);
        return 1;
    }
    if (pasynOctetSyncIO->connect(l->portName, 0, &l->pasynUserOctet, NULL)
                                                               != asynSuccess) {
        errlogPrintf("Can't connect to %s octet sync I/O\n", l->portName);
        return 1;
    }
    return 0;
}

/*
 * Create and configure a new driver instance
 */
static void
nasaAcqConfigure(const char *portName, const char *hostName, int priority)
{
    drvPvt *pdpvt;
    asynStandardInterfaces *pInterfaces;
    asynStatus status;

    /*
     * Sanity checks
     */
    if ((portName == NULL)
     || (*portName == '\0')
     || (hostName == NULL)
     || (*hostName == '\0')) {
        errlogPrintf("Missing or empty port and/or host name.\n");
        return;
    }
    if (strchr(hostName, ':') || strchr(hostName, ' ')) {
        errlogPrintf("Bad host name \"%s\" "
               "-- must contain neither port number nor protocol.\n", hostName);
        return;
    }

    /*
     * Set up driver private storage
     */
    if (priority <= 0) {
        priority = epicsThreadPriorityMedium;
    }
    pdpvt = callocMustSucceed(sizeof(*pdpvt), 1, "nasaACQconfigure");
    pdpvt->command.magic = NASA_ACQ_MAGIC;

    /* 
     * Set up the ASYN ports that do the actual I/O
     */   
    setupLink(&pdpvt->cmdLink, portName, "_UDP", hostName, NASA_ACQ_UDP_PORT,
                                                                      priority);

    /*
     * Create our port
     */
    pdpvt->pasynUser = pasynManager->createAsynUser(NULL, NULL);
    status = pasynManager->registerPort(portName,
                                        ASYN_CANBLOCK|ASYN_MULTIDEVICE,
                                        1, 0, 0);
    if(status != asynSuccess) {
        errlogPrintf("registerPort failed\n");
        return;
    }

    /*
     * Declare the interfaces that we actually provide
     */
    pInterfaces = &pdpvt->asynInterfaces;
    pInterfaces->common.pinterface      = &commonMethods;
    pInterfaces->int32.pinterface       = &int32Methods;
    pInterfaces->int32CanInterrupt      = 1;
    pInterfaces->octet.pinterface       = &octetMethods;
    status = pasynStandardInterfacesBase->initialize(portName,
                                                     pInterfaces,
                                                     pdpvt->pasynUser, pdpvt);
    if(status != asynSuccess) {
        errlogPrintf("pasynStandardInterfacesBase->initialize failed\n");
        return;
    }
}

/*
 * IOC shell command registration
 */
static const iocshArg nsAcqConfigureArg0 = { "port",            iocshArgString};
static const iocshArg nsAcqConfigureArg1 = { "host",            iocshArgString};
static const iocshArg nsAcqConfigureArg2 = { "priority",        iocshArgInt};
static const iocshArg *nsAcqConfigureArgs[] = {
                                       &nsAcqConfigureArg0, &nsAcqConfigureArg1,
                                       &nsAcqConfigureArg2 };
static const iocshFuncDef nsAcqConfigureFuncDef =
                                    {"nasaAcqConfigure", 3, nsAcqConfigureArgs};
static void nsAcqConfigureCallFunc(const iocshArgBuf *args)
{
    nasaAcqConfigure(args[0].sval, args[1].sval, args[2].ival);
}

static void
nasaACQ_RegisterCommands(void)
{
    iocshRegister(&nsAcqConfigureFuncDef, nsAcqConfigureCallFunc);
}
epicsExportRegistrar(nasaACQ_RegisterCommands);

