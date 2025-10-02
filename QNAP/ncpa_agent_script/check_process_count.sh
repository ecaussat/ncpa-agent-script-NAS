#!/bin/bash

WARN=500
CRIT=600

# Récupération du nombre de processus
PROC_COUNT=$(ps aux | wc -l)

# Vérification que c’est bien un nombre
if ! [[ "$PROC_COUNT" =~ ^[0-9]+$ ]]; then
  echo "Process Count: Inconnu"
  exit 3
fi

# Évaluation des seuils
if [[ "$PROC_COUNT" -ge "$CRIT" ]]; then
  echo "CRITICAL - Process count is ${PROC_COUNT}"
  exit 2
elif [[ "$PROC_COUNT" -ge "$WARN" ]]; then
  echo "WARNING - Process count is ${PROC_COUNT}"
  exit 1
else
  echo "OK - Process count is ${PROC_COUNT}"
  exit 0
fi
