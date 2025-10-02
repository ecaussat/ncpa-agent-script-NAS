#!/bin/bash

WARN=20  # en pourcentage
CRIT=10  # en pourcentage

# Récupération des valeurs
read TOTAL USED FREE <<< $(free -m | awk '/^Swap:/ {print $2, $3, $4}')

# Vérification que les valeurs sont bien numériques
if ! [[ "$TOTAL" =~ ^[0-9]+$ && "$USED" =~ ^[0-9]+$ ]]; then
  echo "Swap Usage: Inconnu"
  exit 3
fi

# Si le swap est désactivé
if [[ "$TOTAL" -eq 0 ]]; then
  echo "OK - Swap désactivé"
  exit 0
fi

# Calcul du pourcentage utilisé
USED_PERCENT=$(( 100 * USED / TOTAL ))

# Évaluation des seuils
if [[ "$USED_PERCENT" -ge "$CRIT" ]]; then
  echo "CRITICAL - Swap usage at ${USED_PERCENT}% (Used: ${USED}MB / Total: ${TOTAL}MB)"
  exit 2
elif [[ "$USED_PERCENT" -ge "$WARN" ]]; then
  echo "WARNING - Swap usage at ${USED_PERCENT}% (Used: ${USED}MB / Total: ${TOTAL}MB)"
  exit 1
else
  echo "OK - Swap usage at ${USED_PERCENT}% (Used: ${USED}MB / Total: ${TOTAL}MB)"
  exit 0
fi
