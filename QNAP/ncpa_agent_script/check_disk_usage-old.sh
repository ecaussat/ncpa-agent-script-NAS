#!/bin/bash

WARN=80
CRIT=90
MOUNTPOINT="/share/CACHEDEV1_DATA"

# Récupération de l'utilisation disque en %
USAGE=$(df -h | awk -v mount="$MOUNTPOINT" '
  $NF == mount { 
    for (i=1; i<=NF; i++) {
      if ($i ~ /%$/) {
        gsub("%", "", $i);
        print $i;
        exit;
      }
    }
  }
')

if [[ -z "$USAGE" ]]; then
  echo "Disk Usage: Inconnu"
  exit 3
elif [[ "$USAGE" -ge "$CRIT" ]]; then
  echo "CRITICAL - Disk usage at ${USAGE}%"
  exit 2
elif [[ "$USAGE" -ge "$WARN" ]]; then
  echo "WARNING - Disk usage at ${USAGE}%"
  exit 1
else
  echo "OK - Disk usage at ${USAGE}%"
  exit 0
fi
