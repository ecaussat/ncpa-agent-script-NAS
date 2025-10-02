#!/bin/bash

# Température CPU
CPU_TEMP_RAW=$(awk '{print $1/1000}' /sys/class/hwmon/hwmon0/temp1_input)
CPU_TEMP=$(printf "%.0f" "$CPU_TEMP_RAW")  # arrondi à l'entier

# Seuils
CPU_WARN=70
DISK_WARN=55

STATE=0
RESULT="CPU: ${CPU_TEMP}°C; "

# Vérification CPU
if [ "$CPU_TEMP" -gt "$CPU_WARN" ]; then
  STATE=1
  RESULT="WARNING - CPU temp ${CPU_TEMP}°C; "
fi

# Liste des disques
DISKS=$(ls /dev/sd? 2>/dev/null)

# Vérification des températures disques
for DISK in $DISKS; do
  RAW_TEMP=$(synodisk --read_temp "$DISK" 2>/dev/null)
  DISK_NAME=$(basename "$DISK")

  # Extraction du nombre avec grep + sed
  TEMP=$(echo "$RAW_TEMP" | grep -o '[0-9]\+' | head -n1)

  if [ -n "$TEMP" ]; then
    RESULT+="$DISK_NAME: ${TEMP}°C; "
    if [ "$TEMP" -gt "$DISK_WARN" ] && [ "$STATE" -lt 1 ]; then
      STATE=1
      RESULT="WARNING - $RESULT"
    fi
  else
    RESULT+="$DISK_NAME: Temp inconnue; "
    STATE=3
  fi
done

# Affiche et quitte avec les résultats et le status :
echo "$RESULT"
exit $STATE
