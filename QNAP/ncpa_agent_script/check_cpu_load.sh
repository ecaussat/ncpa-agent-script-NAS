#!/bin/bash

WARN=5.0
CRIT=10.0

# Récupération des charges
LOAD1=$(awk '{print $1}' /proc/loadavg)
LOAD5=$(awk '{print $2}' /proc/loadavg)
LOAD15=$(awk '{print $3}' /proc/loadavg)

# Vérification que les valeurs sont bien numériques
if ! [[ "$LOAD1" =~ ^[0-9.]+$ ]]; then
  echo "CPU Load: Inconnu"
  exit 3
fi

# Comparaison avec awk
if awk "BEGIN {exit ($LOAD1 > $CRIT ? 0 : 1)}"; then
  echo "CRITICAL - Load: $LOAD1 (1m), $LOAD5 (5m), $LOAD15 (15m)"
  exit 2
elif awk "BEGIN {exit ($LOAD1 > $WARN ? 0 : 1)}"; then
  echo "WARNING - Load: $LOAD1 (1m), $LOAD5 (5m), $LOAD15 (15m)"
  exit 1
else
  echo "OK - Load: $LOAD1 (1m), $LOAD5 (5m), $LOAD15 (15m)"
  exit 0
fi
