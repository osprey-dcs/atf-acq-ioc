#!/usr/bin/env python

#
# MIT License
#
# Copyright (c) 2021 Osprey DCS
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

#
# Very simple access to FPGA console
#

from __future__ import print_function
import argparse
import socket
import sys
import termios
import threading
import tty

address = None
if (len(sys.argv) == 2) and (sys.argv[1][0] != '-'):
    address = sys.argv[1]
else:
    parser = argparse.ArgumentParser(description='Communicate with FPGA console.', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-a', '--address', default=None, help='Target IP name or address')
    args = parser.parse_args()
    if args.address: address = args.address
if not address:
    parser.print_help(sys.stderr)
    sys.exit(1)

UDP_PORT = 55002
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.sendto(bytearray(b'\x01'), (address, UDP_PORT))
saveTTY = None

def readFromFPGA():
    while True:
        haveTimeout = False
        try:
            msg = sock.recv(2048).decode('ascii')
            sys.stdout.write(msg)
            if (haveTimeout == False):
                sock.settimeout(0.5)
                haveTimeout = True
        except socket.timeout:
            sys.stdout.flush()
            sock.settimeout(None)
            haveTimeout = False

try:
    if sys.stdin.isatty():
        saveTTY = termios.tcgetattr(sys.stdin.fileno())
        tty.setraw(sys.stdin.fileno())
    readbackThread = threading.Thread(target=readFromFPGA)
    readbackThread.daemon = True
    readbackThread.start()
    while True:
        c = sys.stdin.read(1)
        if c == '\003':
            break;
        sock.sendto(bytes(c,'ascii'), (address, UDP_PORT))
finally:
    if (saveTTY):
        termios.tcsetattr(sys.stdin.fileno(), termios.TCSADRAIN, saveTTY)
