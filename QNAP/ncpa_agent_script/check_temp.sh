#!/bin/bash

CPU_WARN=70
DISK_WARN=55
STATE=0
RESULT=""
PREFIX="OK - "

# Température CPU
CPU_RAW=$(/sbin/getsysinfo cputmp 2>/dev/null)
CPU_TEMP=$(echo "$CPU_RAW" | grep -o '^[0-9]\+')

if [ -n "$CPU_TEMP" ]; then
  RESULT="CPU: ${CPU_TEMP}°C; "
  if [ "$CPU_TEMP" -gt "$CPU_WARN" ]; then
    STATE=1
    PREFIX="WARNING - "
    RESULT="CPU: ${CPU_TEMP}°C; "
  fi
else
  RESULT="CPU: Temp inconnue; "
  STATE=3
  PREFIX=""
fi

# Liste des disques via qcli_storage
DISK_IDS=$(qcli_storage -d | grep "^NAS_HOST" | awk '{print $2}')

for ID in $DISK_IDS; do
  RAW_TEMP=$(/sbin/getsysinfo hdtmp "$ID" 2>/dev/null)
  TEMP=$(echo "$RAW_TEMP" | grep -o '^[0-9]\+')
  DISK_NAME="/dev/sd$(echo "$ID" | awk '{printf("%c", 96 + $1)}')"

  if [ -n "$TEMP" ]; then
    RESULT+="$DISK_NAME: ${TEMP}°C; "
    if [ "$TEMP" -gt "$DISK_WARN" ] && [ "$STATE" -lt 1 ]; then
      STATE=1
      PREFIX="WARNING - "
    fi
  else
    RESULT+="$DISK_NAME: Temp inconnue; "
    STATE=3
    PREFIX=""
  fi
done

echo "${PREFIX}${RESULT}"
exit $STATE
