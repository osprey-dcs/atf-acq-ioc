# Quart FAST UDP protocol

## PSC wire protocol

Each UDP packet body begins with a [PSCDRV header](http://mdavidsaver.github.io/pscdrv/protocol.html)
containing a Message ID (msgid) and variable length body.

All fields in Most Significant Byte First (aka. Big Endian),
and are unsigned unless otherwise specified.

```
      0     1     2     3
   +-----+-----+-----+-----+
0  | 'P' | 'S' |    MSGID  |
   +-----+-----+-----+-----+
4  |      Body Length      |
   +-----------------------+
8  |      Body...          |
...
```

### PSC file format

When written to file, [pscdrv](http://mdavidsaver.github.io/pscdrv/udpfast.html#file-format)
extends this header with a system reception time.

```
      0     1     2     3
   +-----+-----+-----+-----+
00 | 'P' | 'S' |    MSGID  |
   +-----+-----+-----+-----+
04 |      Body Length      |
   +-----------------------+
08 |        Seconds        |
   +-----------------------+
0C |      Nanoseconds      |
   +-----------------------+
10 |      Body...          |
...
```


### ADC Data format 1

msgid: 20033 (`b'NA'`)

Body layout

```
      0     1     2     3
   +-----+-----+-----+-----+
00 |         Status        |
   +-----------------------+
04 |   Active ADC bitmap   |
   +-----------------------+
08 |    Sequence # ...     |
   +-----------------------+
0C |    ... Sequence #     |
   +-----------------------+
10 |        Seconds        |
   +-----------------------+
14 |      Nanoseconds      |
   +-----------------+-----+
18 |    First ADC    | ... |
   +-----------+-----+-----+
1C |     ...   |    ...    |
   +-----------+-----------+
```

Status field is unused and will always be zero.

### ADC Data format 2

msgid: 20034 (`b'NB'`)

Body layout

```
      0     1     2     3
   +-----+-----+-----+-----+
00 |         Status        |
   +-----------------------+
04 |   Active ADC bitmap   |
   +-----------------------+
08 |    Sequence # ...     |
   +-----------------------+
0C |    ... Sequence #     |
   +-----------------------+
10 |        Seconds        |
   +-----------------------+
14 |      Nanoseconds      |
   +-----------------------+
18 |     LOLO Channels     |
   +-----------------------+
1C |      LO Channels      |
   +-----------------------+
20 |      HI Channels      |
   +-----------------------+
24 |     HIHI Channels     |
   +-----------------+-----+
28 |    First ADC    | ... |
   +-----------+-----+-----+
2C |     ...   |    ...    |
   +-----------+-----------+
```

- Status
  - Bit 4: Calibration factors are invalid.
  - Bit 3: Packet transmission overrun
  - Bit 2: Packet building overrun
  - Bit 1: Time of day (Seconds/Nanosecods fields) may be invalid
  - Bit 0: System clock PLL unlocked
- ADC bitmap  (Least significant bit corresponds to channel 0)
- Sequence number.  64-bit unsigned.  Increments by one for each packet.
- Seconds.  Unsigned 32 bit POSIX seconds
- Bounds violation flags: LOLO, LO, HI, HIHI
  - `*Channels`.  Bitmap of channels meeting or exceeding that limit. Most significant bit corresponds to channel 32.
- ADC.  uint24_t.  lowest active channel first

## ADC Data

ADC Samples are reported as signed 24-bit (3 byte) packed integers.
