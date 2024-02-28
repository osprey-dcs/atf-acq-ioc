/*
 * MIT License
 *
 * Copyright (c) 2024 Osprey DCS
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
 * FPGA/IOC communication
 */

#ifndef _FPGA_IOC_PROTOCOL_H_
#define _FPGA_IOC_PROTOCOL_H_

#include <stdint.h>

#define FPGA_IOC_ARG_CAPACITY 360

#define FPGA_IOC_SIZE_TO_ARGC(s) (((s)/sizeof(uint32_t))-3) 
#define FPGA_IOC_ARGC_TO_SIZE(a) (((a)+3)*sizeof(uint32_t)) 

struct fpgaIOCpacket {
    uint32_t    magic;
    uint32_t    sequenceNumber;
    uint32_t    command;
    uint32_t    args[FPGA_IOC_ARG_CAPACITY];
};

#define FPGA_IOC_CMD_HI_MASK    0xF000
#define FPGA_IOC_CMD_LO_MASK    0x0F00
#define FPGA_IOC_CMD_LO_SHIFT   8
#define FPGA_IOC_CMD_IDX_MASK   0x00FF

/*
 * Commands common to all FPGAs
 */
#define FPGA_IOC_CMD_HI_LONGIN      0x0000
# define FPGA_IOC_LONGIN_LO_GENERIC     0x000
# define FPGA_IOC_LONGIN_LO_BUILD_DATE  0x100
#  define FPGA_IOC_LONGIN_BUILD_DATE_IDX_FIRMWARE       0x00
#  define FPGA_IOC_LONGIN_BUILD_DATE_IDX_SOFTWARE       0x01

#define FPGA_IOC_CMD_HI_LONGOUT     0x1000
# define FPGA_IOC_LONGOUT_LO_NO_ARGS    0x000
#  define FPGA_IOC_LONGOUT_NO_ARGS_IDX_CLEAR_POWERUP    0x00
# define FPGA_IOC_LONGOUT_LO_ONE_ARG    0x100
#  define FPGA_IOC_LONGOUT_ONE_ARG_IDX_REBOOT_FPGA      0x00

#define FPGA_IOC_CMD_HI_SYSMON      0x2000

#endif /* _FPGA_IOC_PROTOCOL_H_ */
