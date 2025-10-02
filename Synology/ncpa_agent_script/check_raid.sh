#!/bin/bash

RAID_INFO=$(synospace --enum -v)

STATE=0
RESULT="RAID OK - Tous les volumes sont sains"
FAILED_DISKS=()
VOLUME_NAME=""

# Extraire le nom du volume (ex: volume1)
VOLUME_NAME=$(echo "$RAID_INFO" | grep -oP "^<{10,} \[\K[^]]+")

# Vérifie si le RAID est dégradé
if echo "$RAID_INFO" | grep -q "raid status=\[degrade\]"; then
    STATE=2
    RESULT="RAID CRITICAL - Volume $VOLUME_NAME dégradé"
fi

# Vérifie si une reconstruction est en cours
if echo "$RAID_INFO" | grep -q "raid building mode=\[.*\]" && ! echo "$RAID_INFO" | grep -q "raid building mode=\[none\]"; then
    STATE=1
    RESULT="RAID WARNING - Reconstruction en cours sur $VOLUME_NAME"
fi

# Recherche les disques en panne
while IFS= read -r line; do
    if echo "$line" | grep -q "status \[Failed\]"; then
        disk=$(echo "$line" | sed -n 's/.*DISK \[\(.*\)\], status \[Failed\].*/\1/p')
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

