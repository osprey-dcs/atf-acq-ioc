#!/usr/bin/env python3

import logging
import json
import struct
from collections import defaultdict
from pathlib import Path

import numpy as np

_log = logging.getLogger(__name__)


_psc_head = struct.Struct('>HHIII')
# body prefix length
_quartz_prefix_length = np.dtype([
        ('sts', '>u4'),
        ('chmask', '>u4'),
        ('seq', '>u8'),
        ('sec', '>u4'),
        ('ns', '>u4'),
        ('hihi', '>u4'),
        ('hi', '>u4'),
        ('lo', '>u4'),
        ('lolo', '>u4'),
]).itemsize

def getargs():
    from argparse import ArgumentParser
    P = ArgumentParser()
    P.add_argument('input', type=Path,
                   help='acquisition header file')
    P.add_argument('outdir', type=Path,
                   help='Directory for UFF58b files')
    P.add_argument('-v', '--verbose', dest='level', default=logging.INFO,
                   action='store_const', const=logging.DEBUG)
    return P

def read_dat(fname: Path, next_seq=None) -> (np.ndarray, float, int) # samples [#,32], time0, next_seq
    # peak at first header
    with fname.open('r') as F:
        ps, msgid, msglen, _rsec, _rns = _psc_head.unpack(F.read(_psc_head.size))
    assert ps==0x5053, ps
    assert msgid==0x4e42, msgid
    assert msglen>=_quartz_prefix_length, msglen

    samp_per_packet = (msglen - _quartz_prefix_length)//3

    _T = numpy.dtype([
        ('ps', '>u2'),
        ('msgid', '>u2'),
        ('blen', '>u4'),
        ('rsec', '>u4'),
        ('rns', '>u4'),
        ('sts', '>u4'),
        ('chmask', '>u4'),
        ('seq', '>u8'),
        ('sec', '>u4'),
        ('ns', '>u4'),
        ('hihi', '>u4'),
        ('hi', '>u4'),
        ('lo', '>u4'),
        ('lolo', '>u4'),
        ('samp', 'u1', (samp_per_packet*3,)), # packed I24
    ])

    pkts = np.frombuffer(fname.read_bytes(), dtype=_T)
    assert numpy.all(pkts['ps']==0x5053)
    assert numpy.all(pkts['msgid']==0x4e42)
    assert numpy.all(pkts['chmask']==0xffffffff) # assume all channels enabled
    if next_seq is not None:
        assert  pkts['seq'][0]==next_seq, (pkts['seq'][0], next_seq)
    next_seq = pkts['seq'][-1]+1

    pktT0 = pkts['sec'][0] + pkts['ns'][0]*1e-9

    S24 = pkts['samp']
    S24 = S24.reshape((S24.shape[0], -1, 3)) # #samp, #pkt, 3
    assert samp_per_packet==S24.shape[1], (samp_per_packet, S24.shape)

    S32 = numpy.zeros(S24.shape[:2]+(4,), dtype=S24.dtype) # #samp, #pkt, 4
    S32[...,1:] = S24
    S32[...,0 ] = numpy.bitwise_and(S24[...,0], 0x80)/128*255 # sign extend
    del S24

    S32 = S32.view('>i4').flatten() # concat packets
    S32 = S32.reshape((-1,32)) # #samp, 32

    # apply scaling
    return S32.astype('f4'), pktT0, next_seq



def main(args):
    with args.input.open('r') as F:
        Info = json.load(F)

    for Chas in Info['Chassis']:
        chasN = int(Chas['Chassis'])
        _log.info('Process chassis %d', chasN)

        Sigs = []
        for S in Info['Signals']:
            idx = int(S['Address']['Channel'])-1 # zero index
            O = args.outdir / f'{chasN}-{idx+1}.uff'
            with O.open('x'):
                pass # just create

            S['_outfile'] = O
            Sigs.append(S)

        assert len(Sigs)>0, Sigs

        for datF in Chas['Dat']:
            sampI = read_dat(args.input.with_name(datF))



if __name__=="__main__":
    args = getargs().parse_args()
    logging.basicConfig(level=args.level)
    main(args)
