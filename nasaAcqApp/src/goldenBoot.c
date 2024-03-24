/*************************************************************************\
* Copyright (c) 2024 Osprey Distributed Control Systems
* SPDX-License-Identifier: BSD
\*************************************************************************/
/* Sends "magic" FPGA reboot UDP message as understood by
 * LBNL Bedrock firmware for XC7 series FPGA.
 *
 * https://github.com/BerkeleyLab/Bedrock/blob/master/badger/spi_flash_engine.v
 */

#include <osiSock.h>

#include <stdlib.h>
#include <string.h>

#include <alarm.h>
#include <recGbl.h>
#include <cantProceed.h>
#include <epicsStdio.h>
#include <dbDefs.h>
#include <longoutRecord.h>
#include <errlog.h>

#include <epicsExport.h>

static
const unsigned char reboot_to_app[] = {
    // Bedrock Flash/Config access protocol...
    // Initiate write request
    "\x52\x01"
    // First (and only) transaction header
    // 0x80 - Configuration access
    // 0x08 - 256 byte (padded) payload
    "\x88"
    // XC7 configuration bitstream follows...
    // dummy words
    "\xff\xff\xff\xff"
    "\xff\xff\xff\xff"
    // sync word
    "\xaa\x99\x55\x66"
    // no-op
    "\x20\x00\x00\x00"
    // write 1 word to WBSTAR (warm-boot start address) register
    "\x30\x02\x00\x01"
    // boot address in flash with application image
    "\x00\x80\x00\x00"
    // Write 1 word to CMD register
    "\x30\x00\x80\x01"
    // IPROG command
    "\x00\x00\x00\x0F"
    // pad out with no-op
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
    "\x20\x00\x00\x00"
};
STATIC_ASSERT(sizeof(reboot_to_app)==3+256+1);

typedef struct {
    SOCKET sender;
    osiSockAddr dest;
    int lastError;
} goldenBootPvt;

static
long goldenBootInit(longoutRecord *prec)
{
    goldenBootPvt *pvt;
    if(prec->out.type!=INST_IO)
        return -2;

    char name[40] = "";
    osiSockAddr addr;
    int ret = sscanf(prec->out.value.instio.string, "%39s", name);
    name[39] = '\0';
    if(ret<1
        || aToIPAddr(name, 804, &addr.ia)
        || addr.ia.sin_port==0)
    {
        printf("%s.OUT - Invalid \"%s\"\n", prec->name, prec->out.value.instio.string);
        return -2;
    }

    pvt = callocMustSucceed(1, sizeof(*pvt), __func__);
    memcpy(&pvt->dest, &addr, sizeof(pvt->dest));

    pvt->sender = epicsSocketCreate(AF_INET, SOCK_DGRAM, 0);
    if(pvt->sender == INVALID_SOCKET) {
        free(pvt);
        return -2;

    } else {
        prec->dpvt = pvt;
        return 0;
    }
}

static
long goldenBootProc(longoutRecord *prec)
{
    goldenBootPvt *pvt = prec->dpvt;

    if(!pvt) {
        recGblSetSevrMsg(prec, COMM_ALARM, INVALID_ALARM, "init fail");
        return -2;
    }

    const size_t mlen = sizeof(reboot_to_app)-1;
    int ret = sendto(pvt->sender,
                     reboot_to_app, mlen,
                     0,
                     &pvt->dest.sa, sizeof(pvt->dest));

    if(ret==mlen) {
        // success

    } else if(ret==-1) {
        int err = errno;
        if(err!=pvt->lastError) {
            errlogPrintf("%s : send error (%d) %s\n",
                         prec->name, err, strerror(err));
            pvt->lastError = err;
        }
        recGblSetSevrMsg(prec, COMM_ALARM, INVALID_ALARM, "sendto fails");

    } else {
        recGblSetSevrMsg(prec, COMM_ALARM, INVALID_ALARM, "sendto trunc %d", ret);
    }

    return 0;
}

static
const longoutdset goldenBootLO = {
    {
        5,
        NULL,
        NULL,
        &goldenBootInit,
        NULL,
    },
    &goldenBootProc,
};
epicsExportAddress(dset, goldenBootLO);
