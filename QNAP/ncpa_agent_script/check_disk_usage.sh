#!/bin/bash

WARN=80
CRIT=90
MOUNTPOINT="/share/CACHEDEV1_DATA"

# Récupération de la ligne contenant le point de montage
LINE=$(df -h | grep "$MOUNTPOINT" | tr -s ' ')

# Vérification que la ligne a bien été trouvée
if [[ -z "$LINE" ]]; then
  echo "Disk Usage: Inconnu"
  exit 3
fi

# Extraction des champs
SIZE=$(echo "$LINE" | cut -d' ' -f2)
AVAIL=$(echo "$LINE" | cut -d' ' -f3)
USED=$(echo "$LINE" | cut -d' ' -f4)
USEP=$(echo "$LINE" | cut -d' ' -f5 | tr -d '%')

# Vérification que USEP est bien un nombre
if ! [[ "$USEP" =~ ^[0-9]+$ ]]; then
  echo "Disk Usage: Inconnu"
  exit 3
fi

# Évaluation des seuils
if [[ "$USEP" -ge "$CRIT" ]]; then
  echo "CRITICAL - Disk usage at ${USEP}% (Used: $USED / Total: $SIZE / Free: $AVAIL)"
  exit 2
elif [[ "$USEP" -ge "$WARN" ]]; then
  echo "WARNING - Disk usage at ${USEP}% (Used: $USED / Total: $SIZE / Free: $AVAIL)"
  exit 1
else
  echo "OK - Disk usage at ${USEP}% (Used: $USED / Total: $SIZE / Free: $AVAIL)"
  exit 0
fi

