#!/usr/bin/env python3

import logging
import json
import glob
import time
import sys
from weakref import WeakSet
from pathlib import Path

#from p4p.nt.scalar import ntstr
from p4p.client.thread import Context

_log = logging.getLogger(__name__)

def getargs():
    from argparse import ArgumentParser
    P = ArgumentParser()
    P.add_argument('--pv-prefix', default='FDAS:')
    P.add_argument('--root', type=Path, default=Path('/data'))
    P.add_argument('--force-all', action='store_true',
                   help='Acquire with all chassis regardless of USE flags')
    P.add_argument('-v', '--verbose', dest='level', default=logging.INFO,
                   action='store_const', const=logging.DEBUG)
    return P

class PV:
    all_pvs = WeakSet()
    last_value = {}
    ctxt = None
    def __init__(self, name:str, index=False, signed=False):
        self.name = name
        self.__index, self.__signed = index, signed
        self.all_pvs.add(self)
    def read(self):
        o = self.last_value[self.name]
        # simplify augmented nt*
        if isinstance(o, str): # ntstr
            o = o[:]
        elif isinstance(o, float): # ntfloat
            o = float(o)
        elif hasattr(o, 'choice'): # ntenum
            o = int(o) if self.__index else str(o)
        elif isinstance(o, int):
            o = int(o)
            if self.__signed and (o&0x80000000): # int32 masquerading as uint32...
                o = -(o^0xffffffff)-1
        return o
    @classmethod
    def fetch_all(klass):
        # sorted, unique, list of PV names
        names = list(set([pv.name for pv in klass.all_pvs]))
        values = klass.ctxt.get(names)
        klass.last_value = dict(zip(names, values))

    def __repr__(self):
        V = self.last_value.get(self.name)
        return f'PV({self.name!r}, {V!r})'

class Putter:
    def __init__(self, ctxt):
        self.ctxt = ctxt
        self.reset()

    def reset(self):
        self.names, self.values = [], []

    def put(self, name, value):
        self.names.append(name)
        self.values.append(value)

    def exec_(self):
        try:
            self.ctxt.put(self.names, self.values)
        finally:
            self.reset()

class PVEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, PV):
            o = o.read()
        elif isinstance(o, Path):
            o = str(o)
        else:
            o = super().default(o)
        return o

def main(args):
    gmnow = time.gmtime()
    prefix = args.pv_prefix

    PV.ctxt = ctxt = Context()
    batch = Putter(ctxt)
    exit = 0

    _log.info('Gathering configuration')

    PVinuse = [
        f'{prefix}{node:02d}:SA:Ch{ch:02d}:USE'
        for node in range(1, 33)
        for ch in range(1, 33)
    ]
    inuse = ctxt.get(PVinuse)

    info = {
        'AcquisitionId': PV(f'{prefix}SA:DESC'),
        #'Role1Name': PV(f'{prefix}SA:OPER'),
        'CCCR': PV(f'{prefix}SA:FILE'),
        'CCCR_SHA256': PV(f'{prefix}SA:FILEHASH'),
        'SampleRate': PV(f'{prefix}ACQ:rate.RVAL'), # Hz
        'AcquisitionStartDate': time.strftime('%Y%m%d-%H%M%S', gmnow),
        # AcquisitionEndDate
        'Signals': [],
        'Chassis': [],
    }
    Iinuse = iter(inuse)
    nodeUsed = [args.force_all]*32
    for node in range(1, 33):
        for ch in range(1, 33):
            signum = (node-1)*32 + ch # 1-1024
            use = int(next(Iinuse))
            _log.debug('Use %d %d / %d %s', node, ch, signum, use)
            if use==0:
                continue
            elif use!=1:
                _log.warning('Use?? %d %d %s', node, ch, use)
            nodeUsed[node-1] = True
            S = {
                'Address': {'Chassis':node, 'Channel':ch},
                'Name': PV(f'{prefix}{node:02d}:SA:Ch{ch:02d}:NAME'),
                'Desc': PV(f'{prefix}{node:02d}:SA:Ch{ch:02d}:DESC'),
                'Egu': PV(f'{prefix}{node:02d}:SA:Ch{ch:02d}:EGU'),
                'Slope': PV(f'{prefix}{node:02d}:SA:Ch{ch:02d}:SLO'),
                'Intercept': PV(f'{prefix}{node:02d}:SA:Ch{ch:02d}:OFF'),
                'Coupling': PV(f'{prefix}{node:02d}:ACQ:coupling:{ch:02d}'),
                'ResponseNode': PV(f'{prefix}{node:02d}:SA:Ch{ch:02d}:RESPNODE'),
                'ResponseDirection': PV(f'{prefix}{node:02d}:SA:Ch{ch:02d}:RESPDIR.RVAL', signed=True),
                'Type': PV(f'{prefix}{node:02d}:SA:Ch{ch:02d}:SDTYP.RVAL'),
                'LastCal': PV(f'{prefix}{node:02d}:SA:Ch{ch:02d}:TCAL'), # posix time
                #TODO: from PV
                'SigNum': signum,
                'ReferenceNode':0,
                'ReferenceDirection':0,
            }
            info['Signals'].append(S)

    assert any(nodeUsed)

    PV.fetch_all()
    # can't allow duplicate Name among Use'd channels
    sig_names = sorted([S['Name'].read() for S in info['Signals']])
    assert not any([A==B for A,B in zip(sig_names[:1], sig_names[1:])]), sig_names

    _log.info('Setting up directory tree')

    desc = info['AcquisitionId'].read()[:]
    # /data/2024/05/20240517-125412-rec/
    outdir = args.root \
        / time.strftime('%Y', gmnow) \
        / time.strftime('%m', gmnow) \
        / f"{time.strftime('%Y%m%d-%H%M%S', gmnow)}-{desc}"
    file_prefix = f"{desc}-{time.strftime('%Y%m%d-%H%M%S', gmnow)}"

    _log.info('mkdir %s', outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    ctxt.put(f'{prefix}SA:LASTRUN', file_prefix)

    CHprefix = [None]*32

    for node,used in enumerate(nodeUsed, 1):
        CHprefix[node-1] = f'{file_prefix}-CH{node:02d}-'
        batch.put(f'{prefix}{node:02d}:FileDir-SP', str(outdir) if used else '')
        batch.put(f'{prefix}{node:02d}:FileBase-SP', CHprefix[node-1] if used else '')
        batch.put(f'{prefix}{node:02d}:Record-Sel', used)

    if ctxt.get(f'{prefix}ACQ:enable'):
        _log.error('Stop current acquisition')
        sys.exit(1)

    _log.info('Configure filenames')
    batch.exec_()

    fbefore = outdir / f'{file_prefix}.json.before'
    with fbefore.open('x') as F:
        json.dump(info, F, cls=PVEncoder, indent='  ')

    _log.info('Begin acquisition')
    ctxt.put(f'{prefix}ACQ:enable', True)

    try:
        T0 = ctxt.get(f'{prefix}ACQ:enable').timestamp

        _log.info('Recording...')
        _log.info('Ctrl+c to stop')
        time.sleep(60)
        _log.info('60 elapsed')
        while True:
            time.sleep(60)

    except KeyboardInterrupt:
        _log.info('Stopping in 60 seconds...')
        try:
            time.sleep(60)
            _log.info('60 elapsed')
        except KeyboardInterrupt:
            _log.info('...skip')
    except:
        _log.exception("Unexpected error") # log
        exit = 1 # exit with error
        # continue to hopefully recover
    finally:
        ctxt.put(f'{prefix}ACQ:enable', False)

        _log.info('Wait for acquisition to complete')
        time.sleep(5) # TODO: how to tell??
        Tf = ctxt.get(f'{prefix}ACQ:enable').timestamp

        for node,used in enumerate(nodeUsed, 1):
            batch.put(f'{prefix}{node:02d}:Record-Sel', False)
            batch.put(f'{prefix}{node:02d}:FileDir-SP', '')
            batch.put(f'{prefix}{node:02d}:FileBase-SP', '')

        batch.exec_()

    _log.info('List data file names')
    for node,used in enumerate(nodeUsed, 1):
        if not used:
            continue
        dats = []
        for datfile in outdir.glob(f'{glob.escape(CHprefix[node-1])}*.dat'):
            _log.debug('Found %r', datfile)
            dats.append(datfile.relative_to(outdir))
        info['Chassis'].append({
            'Chassis': node,
            'Dat': dats,
        })

    gmnow=time.gmtime()
    info['AcquisitionEndDate']= time.strftime('%Y%m%d-%H%M%S', gmnow)

    ffinal = outdir / f'{file_prefix}.json'
    with ffinal.open('w') as F:
        json.dump(info, F, cls=PVEncoder, indent='  ')
    fbefore.unlink()
    _log.info(f'Wrote: {ffinal.absolute()}')

    sys.exit(exit)

if __name__=="__main__":
    args = getargs().parse_args()
    logging.basicConfig(level=args.level)
    main(args)
