# Quartz Digitizer EPICS Driver

## Dependencies

- [EPICS Base](https://github.com/epics-base/epics-base) >= 7.0.8.1
- [feed-core](https://github.com/osprey-dcs/feed-core)
- [pscdrv](https://github.com/osprey-dcs/pscdrv)
  - Requires fftw3 option
- [autosave](https://github.com/epics-modules/autosave)
- [PVXS](https://github.com/epics-base/pvxs) (Optional)
  - Requires libevent2

# Building

```sh
apt-get update
apt-get install -y build-essential git libevent-dev libz-dev libfftw3-dev libreadline-dev python3 python-is-python3

git clone --branch 7.0 https://github.com/epics-base/epics-base
git clone --branch master https://github.com/epics-base/pvxs
git clone --branch master https://github.com/epics-modules/autosave
git clone --branch atf-dev https://github.com/osprey-dcs/feed-core
git clone --branch atf-dev https://github.com/osprey-dcs/pscdrv
git clone --branch main https://github.com/osprey-dcs/atf-acq-ioc

cat <<EOF > pvxs/configure/RELEASE.local
EPICS_BASE=\$(TOP)/../epics-base
EOF

cat <<EOF > feed-core/configure/RELEASE.local
EPICS_BASE=\$(TOP)/../epics-base
EOF

cat <<EOF > pscdrv/configure/RELEASE.local
EPICS_BASE=\$(TOP)/../epics-base
EOF
cat <<EOF > pscdrv/configure/CONFIG_SITE.local
USE_FFTW=YES
EOF

cat <<EOF > feed-core/configure/RELEASE.local
EPICS_BASE=\$(TOP)/../epics-base
EOF

cat <<EOF > autosave/configure/RELEASE.local
EPICS_BASE=\$(TOP)/../epics-base
EOF

cat <<EOF > atf-acq-ioc/configure/RELEASE.local
AUTOSAVE=\$(TOP)/../autosave
PVXS=\$(TOP)/../pvxs
FEED_CORE=\$(TOP)/../feed-core
PSCDRV=\$(TOP)/../pscdrv
EPICS_BASE=\$(TOP)/../epics-base
EOF

make -C epics-base
make -C pvxs
make -C autosave
make -C feed-core
make -C pscdrv
make -C atf-acq-ioc
```

## Running

One Quartz IOC instance in each system will be designated as
the timing master/EVG node, with some additional database files loaded.
See [`node01.cmd`](iocBoot/siocNASA_ACQ/node01.cmd) for an example.

For other Quartz IOC instances, see [`node02.cmd`](iocBoot/siocNASA_ACQ/node02.cmd)
and [`nodeXX.cmd`](iocBoot/siocNASA_ACQ/nodeXX.cmd) for an example.

## OPI Screens

Virtual control panel display files for [Phoebus](http://phoebus.org/)
are provided under `opi/`.

## systemd

[`ioc-adc@.service`](ioc-adc@.service) is an example systemd unit
file which runs Quartz IOCs using
[procServ](https://github.com/ralphlange/procServ).
