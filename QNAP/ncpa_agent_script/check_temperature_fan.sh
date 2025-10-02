#!/bin/bash

# Seuils
FAN_WARN=631
FAN_CRIT=1000
CPU_WARN=60
CPU_CRIT=66
SYS_WARN=48
SYS_CRIT=51
DISK_WARN=45
DISK_CRIT=50

STATE=0
RESULT=""

# Température CPU
CPU_TEMP=$(/sbin/getsysinfo cputmp 2>/dev/null | grep -o '^[0-9]\+')
if [[ -n "$CPU_TEMP" ]]; then
  RESULT+="CPU Temp: ${CPU_TEMP}°C; "
  if [[ "$CPU_TEMP" -ge "$CPU_CRIT" ]]; then
    STATE=2
  elif [[ "$CPU_TEMP" -ge "$CPU_WARN" && "$STATE" -lt 1 ]]; then
    STATE=1
  fi
else
  RESULT+="CPU Temp: Inconnue; "
  STATE=3
fi

# Température système
SYS_RAW=$(/sbin/getsysinfo systmp 2>/dev/null)
SYS_TEMP=$(echo "$SYS_RAW" | grep -o '^[0-9]\+')
if [[ -n "$SYS_TEMP" ]]; then
  RESULT+="System Temp: ${SYS_TEMP}°C; "
  if [[ "$SYS_TEMP" -ge "$SYS_CRIT" ]]; then
    STATE=2
  elif [[ "$SYS_TEMP" -ge "$SYS_WARN" && "$STATE" -lt 1 ]]; then
    STATE=1
  fi
else
  RESULT+="System Temp: Inconnue; "
  STATE=3
fi

# Température des disques
DISK_IDS=$(qcli_storage -d | grep "^NAS_HOST" | awk '{print $2}')
for ID in $DISK_IDS; do
  RAW_TEMP=$(/sbin/getsysinfo hdtmp "$ID" 2>/dev/null)
  TEMP=$(echo "$RAW_TEMP" | grep -o '^[0-9]\+')
  DISK_NAME="/dev/sd$(echo "$ID" | awk '{printf("%c", 96 + $1)}')"

  if [[ -n "$TEMP" ]]; then
    RESULT+="$DISK_NAME: ${TEMP}°C; "
    if [[ "$TEMP" -ge "$DISK_CRIT" ]]; then
      STATE=2
    elif [[ "$TEMP" -ge "$DISK_WARN" && "$STATE" -lt 1 ]]; then
      STATE=1
    fi
  else
    RESULT+="$DISK_NAME: Temp inconnue; "
    STATE=3
  fi
done

# Vitesse des ventilateurs
FAN_COUNT=$(/sbin/getsysinfo sysfannum 2>/dev/null)
if [[ "$FAN_COUNT" =~ ^[0-9]+$ ]]; then
  for (( i=1; i<=FAN_COUNT; i++ )); do
    RPM=$(/sbin/getsysinfo sysfan "$i" 2>/dev/null | grep -o '[0-9]\+')
    if [[ "$RPM" =~ ^[0-9]+$ ]]; then
      RESULT+="Fan $i: ${RPM} RPM; "
      if [[ "$RPM" -ge "$FAN_CRIT" ]]; then
        STATE=2
      elif [[ "$RPM" -ge "$FAN_WARN" && "$STATE" -lt 1 ]]; then
        STATE=1
      fi
    else
      RESULT+="Fan $i: RPM inconnu; "
      STATE=3
    fi
  done
else
  RESULT+="Fan: Inconnu; "
  STATE=3
fi

# Affichage final
case $STATE in
  0) echo "OK - $RESULT";;
  1) echo "WARNING - $RESULT";;
  2) echo "CRITICAL - $RESULT";;
  *) echo "UNKNOWN - $RESULT";;
esac

exit $STATE
