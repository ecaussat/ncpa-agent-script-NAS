#!/bin/bash

WARN=90
CRIT=99

# Récupération des valeurs
read TOTAL USED FREE SHARED BUFFERS CACHED <<< $(free -m | awk '/^Mem:/ {print $2, $3, $4, $5, $6, $7}')

# Calcul de la mémoire réellement utilisée
REAL_USED=$(( USED - BUFFERS - CACHED ))

# Calcul du pourcentage utilisé
USED_PERCENT=$(( 100 * REAL_USED / TOTAL ))

# Vérification que USED_PERCENT est bien un nombre
if ! [[ "$USED_PERCENT" =~ ^[0-9]+$ ]]; then
  echo "Memory Usage: Inconnu"
  exit 3
fi

# Évaluation des seuils
if [[ "$USED_PERCENT" -ge "$CRIT" ]]; then
  echo "CRITICAL - Memory usage at ${USED_PERCENT}% (Used: ${REAL_USED}MB / Total: ${TOTAL}MB)"
  exit 2
elif [[ "$USED_PERCENT" -ge "$WARN" ]]; then
  echo "WARNING - Memory usage at ${USED_PERCENT}% (Used: ${REAL_USED}MB / Total: ${TOTAL}MB)"
  exit 1
else
  echo "OK - Memory usage at ${USED_PERCENT}% (Used: ${REAL_USED}MB / Total: ${TOTAL}MB)"
  exit 0
fi
