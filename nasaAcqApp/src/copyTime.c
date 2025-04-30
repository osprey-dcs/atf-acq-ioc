/*************************************************************************\
* Copyright (c) 2024 Osprey Distributed Control Systems
* SPDX-License-Identifier: BSD
\*************************************************************************/
/* Copy VAL -> TIME eg. to be consumed by DTYP="Soft Timestamp" from Base
 */

#define USE_TYPED_DSET

#include <epicsMath.h>
#include <alarm.h>
#include <dbAccess.h>
#include <recGbl.h>
#include <aiRecord.h>
#include <epicsExport.h>

static
void val2time(aiRecord *prec)
{
    if(!isfinite(prec->val) || prec->val<0) {
        recGblSetSevrMsg(prec, READ_ALARM, INVALID_ALARM, "time out of bnd");

    } else if(prec->tse==epicsTimeEventDeviceTime) {
        double nsec = fmod(prec->val, 1.0) * 1e9;
        prec->time.secPastEpoch = prec->val - POSIX_TIME_AT_EPICS_EPOCH; // truncate
        prec->time.nsec = nsec + 0.5; // round to nearest
    }
}

static
long copyTimeInit(dbCommon *pcom)
{
    aiRecord *prec = (aiRecord*)pcom;
    if (recGblInitConstantLink(&prec->inp, DBF_DOUBLE, &prec->val))
        prec->udf = FALSE;
    val2time(prec);
    return 0;
}

static
long copyTimeRead(aiRecord *prec)
{
    long status = dbGetLink(&prec->inp, DBR_DOUBLE, &prec->val, 0, 0);
    if(!status)
        val2time(prec);
    return status ? status : 2;
}

static
const aidset copyTimeAI = {
    {
        6,
        NULL,
        NULL,
        copyTimeInit,
        NULL,
    },
    copyTimeRead,
    NULL,
};
epicsExportAddress(dset, copyTimeAI);
