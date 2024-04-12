# Console Commands

The processor in the FPGA provides a simple command interpreter.  The console interpreter can be accessed through port C of the USB/Serial adapter (serial settings 115200-8N1) or through a UDP port and the console.py script.  Typing a character to the USB/Serial port disables the UDP connection.

Only enough of a command name to make it unique needs to be entered.  Since the first character of all commands is different this means that only a single character need be entered.  The only editing available is the backspace or delete key which erases the character to the left of the cursor.  Typing a carriage return or newline character executes the command.

The commands and their arguments are:

**boot [-a]**  
The FPGA prompts for confirmation and then restarts as if powered up.  The optional argument specifies that the alternate bootable image is to be tried first.

**calib**  
The FPGA prompts for confirmation and then rereads and applies the calibration settings in Calibraion.csv.

**debug [-s] [n]**  
    The debugging flags are set to the specified value, if one is given.  If no value is given the current value of the debugging flags is printed.  The bits are:

    Bit 0    — Enable messages related to the EPICS UDP port.
    Bit 1    — Enable messages related to the TFTP UDP port.
    Bit 2    — Enable messages related to the multi-gigabit transceiver (event receiver and event fanout).
    Bit 3    — Enable messages related to the event generator.
    Bit 4    — Enable messages showing the operation of the clock synchronization PLL.
    Bit 5    — Show some high-speed acquisition statistics.
    Bit 6    — Show input coupling relay operations.
    Bit 7    — Don't exercise input coupling (AC/DC) relays on startup.
    Bit 8    — Show ADC calibration operations.
    Bit 9    — Show some status information about the bootstrap flash memory.
    Bit 10   — Scan the Marble I2C buses and show the devices attached to each.
    Bit 12   – Show all AD7768 register writes as they occur.
    Bit 13   — Dump the register contents (there are a lot) of the AD7768 ADC chips.
    Bit 15   — Provide fake AD7768 data.  Effective only at startup.
    Bit 17   — Show the MGT clock multiplexer registers.
    Bit 18   — Start an AD7768 alignment operation.
    Bit 19   – Add severe jitter to the secondary PPS reference (PMOD-GPS).

If the optional -s argument is present the value of the debugging flags set at FPGA startup will be set or shown. 


**fmon**  
Show the value of the frequency counters monitoring various FPGA clocks.  Values shown with only 3 fractional digits indicate that the FPGA is not receiving a 'pulse per second' marker directly or indirectly from the facility timing system and that the accuracy of the measurement is somewhat suspect. 

**gw [vvv.www.xxx.yyy[/nn]]**  
    Specify the IPv4 address of the gateway machine (vvv.www.xxx.yyy) and optionally the number of bits in the network address (default 24, a class C network).
    Issuing the **gw** command with no arguments displays the current settings.

**help or ?**  
    Show a table of commands.

**log**  
    Replay the console startup messages.

**ntp [vvv.www.xxx.yyy]**  
**ntp 0**  
The FPGA firmware includes an MRF-compatible event generator which obtains its initial time from an NTP server and then maintains it using a hardware pulse-per-second signal. To enable the event generator use this command with the IPv4 address of the NTP server (**vvv.www.xxx.yyy**) as an argument.  To disable the event generator, set the address of the NTP server to 0.

Issuing the **ntp** command with no arguments displays the current settings. 

**pps**  
Show lots of PPS-related information including for the event generator node the latency between the hardware PPS marker and the event receiver PPS event arrival.

**reg [r] [n]**  
Show the contents of **n** (default 1) general-purpose I/O registers starting at register **r** (default 0).


# TFTP Server

Files can be uploaded to, or downloaded from, the Marble bootstrap flash memory using the TFTP server in the FPGA application.

File transfers must be performed in 'octet' (binary) mode.  The TFTP server is limited to a single active transfer at a time.  Don't attempt simultaneous transfers from multiple clients.

The FPGA firmware and executable image are contained in a single file.  By default the FPGA will attempt to load everything from the default image named BOOT.bin in the flash memory.   See the boot command documentation for instructions on how to boot the alternate image.  To ensure that an update does not result in an unresponsive ('bricked') system the following procedure should be followed:

1. Transfer the new image from the host machine to the alternate file (BOOT_A.bin).
1. Issue the console command to boot the alternate image (**boot -a**).    
1. If the boot fails, power cycle the FPGA to revert to the default image (BOOT.bin).
1. If the boot succeeds, transfer the new image again, but this time to the standard location (BOOT.bin).
1. Issue the console command to boot the default image (**boot**).

If things go wrong and you end up with a bricked system the only recourse is to use the Vivado Hardware Manager to download the image through the USB/JTAG adapter.

If the Marble is configured with a LBNL 'Golden Image' at the beginning of write-protected flash memory then only the alternate file can be written.  In this case the update procedure is much simpler -- simply write the new bootable image to BOOT_A.bin and restart the FPGA.

In addition to the primary and secondary bootstrap images the TFTP server provides access to other 'files'.  The complete list of these is:

| Name 	|   Description   |
|---|---|
| BOOT.bin  |	Primary bootstrap image. |
| BOOT_A.bin 	| Secondary (alternate) bootstrap image.
| SYSPARAM.dat |	System parameter values (Startup debug flags, NTP server settings). |
| Calibration.csv | Comma-separated-values file of ADC calibration values. |
| FullFlash.bin| 	Complete flash memory contents (16 MiB). |
| QSFP1_EEPROM.bin |	First QSFP module values (SFF-8636, read only). |
| QSFP2_EEPROM.bin| 	Second QSFP module values (SFF-8636, read only). |
| FMC1_EEPROM.bin |	IPMI EEPROM of first FMC mezzanine card. |
| FMC2_EEPROM.bin |	IPMI EEPROM of second FMC mezzanine card. |

The Calibration.csv file must contain 33 lines.  The first column of the first line must contain with the time at which the calibration values were measured specified as the number of seconds since January 1, 1970 (POSIX seconds).  The remaining lines must contain two comma-separated numbers specifying the ADC calibration values for each of the 32 channels.  The first value on each line is the offset, in units of ADC counts, to be subtracted from each ADC reading.  The second value on each line is the gain adustment, in units of parts-per-million, to be applied to the ADC reading.  The offset is subtracted before the gain is adjusted.  The offset is limited to ±1000000 counts and the gain adjustment is limited to ±50000 parts per million.  Values outside these ranges are clipped to the appropriate range.  Values in columns after the first on the first line and second on all other lines are ignored.

# Network Configuration

The Ethernet MAC address and IPv4 network address are set using the microcontroller USB/serial port (115200-8N1).  The microcontroller serial port is connected to the fourth port (port D) of the USB/serial adapter.  After connecting, type a '?' followed by a carriage return to obtain the menu of commands.

# ADC Operation
The AD7768 has signal processing to low pass filter the incoming data to less than the Nyquist frequency.

| Fsamp (kHz) | MCLK (MHz) | Fmod (MHz) | Fchop (kHz) |
|:----:|:----:|:----:|:----:|
| 250 | 32 | 8 | 250 |
| 50 | 25.6 | 6.4 | 200 |
| 10 | 20.48 | 5.12 | 160 |
| 5 | 20.48 | 5.12 | 160 |
| 1 | 16.384 | 0.512 | 16 |

* Filter pass band (less than 0.005 dB ripple) is DC to 0.4*Fsamp.
* Filter stop band (attenuation greater than 105 dB) begins at 0.5*Fsamp.
* There is reduced anti-aliasing (attenuation between 90 and 60 dB) at bands centered on N\*2*Fchop.
* The first unattenuated aliasing band is centered on 2*Fmod.
* Fchop is Fmod/32.
* Decimation factor is Fmod/Fsamp.





