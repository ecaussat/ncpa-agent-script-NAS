#!/bin/bash

SYNO_MODEL=$(cat /proc/sys/kernel/syno_hw_version)

DSM_VERSION=$(grep productversion /etc.defaults/VERSION | cut -d'"' -f2)
BUILD=$(grep buildnumber /etc.defaults/VERSION | cut -d'"' -f2)

SYNO_SERIAL=$(cat /proc/sys/kernel/syno_serial)

echo "SYNOLOGY $SYNO_MODEL, S/N: $SYNO_SERIAL, DSM Version: $DSM_VERSION-$BUILD"
