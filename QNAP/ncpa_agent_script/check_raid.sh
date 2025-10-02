#!/bin/bash

RAID_INFO=$(sudo md_checker)

STATE=0
RESULT="RAID OK - Tous les volumes sont sains"
FAILED_DISKS=()
VOLUME_NAME=""

# Extraire le nom du volume RAID (ex: md1)
VOLUME_NAME=$(echo "$RAID_INFO" | grep -i "^Name:" | awk -F: '{print $2}' | xargs)

# Vérifie si le RAID est dégradé
if echo "$RAID_INFO" | grep -q "Status: *DEGRADED"; then
    STATE=2
    RESULT="RAID CRITICAL - Volume $VOLUME_NAME dégradé"
fi

# Vérifie si le RAID est en ligne
if echo "$RAID_INFO" | grep -q "Status: *ONLINE"; then
    STATE=0
    RESULT="RAID OK - Volume $VOLUME_NAME en ligne"
fi

# Recherche les disques en panne
while IFS= read -r line; do
    if echo "$line" | grep -q "Failed"; then
        disk=$(echo "$line" | awk '{print $3}')
        FAILED_DISKS+=("$disk")
    fi
done <<< "$RAID_INFO"

# Si des disques sont en panne
if [ ${#FAILED_DISKS[@]} -gt 0 ]; then
    DISK_LIST=$(IFS=, ; echo "${FAILED_DISKS[*]}")
    if [ $STATE -eq 0 ]; then
        STATE=1
        RESULT="RAID WARNING - Volume $VOLUME_NAME OK mais disque(s) en panne : $DISK_LIST"
    else
        RESULT="$RESULT - Disque(s) en panne : $DISK_LIST"
    fi
fi

echo "$RESULT"
exit $STATE
