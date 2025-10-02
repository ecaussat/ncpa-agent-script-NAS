#!/bin/bash

DISKS=$(ls /dev/sd? 2>/dev/null)
SCRIPT_DIR="/volume1/@appstore/monitoring-plugins/bin/"
SMART_SUMMARY=""
STATE=0

for DISK in $DISKS; do
  RESULT=$("$SCRIPT_DIR/check_ide_smart" -d "$DISK")
  DISK_NAME=$(basename "$DISK")
  SMART_SUMMARY+="$DISK_NAME: $RESULT; "

  # Si le check retourne WARNING ou CRITICAL, on ajuste l'état global
  CHECK_STATE=$?
  if [ "$CHECK_STATE" -gt "$STATE" ]; then
    STATE=$CHECK_STATE
  fi
done

echo "$SMART_SUMMARY"
