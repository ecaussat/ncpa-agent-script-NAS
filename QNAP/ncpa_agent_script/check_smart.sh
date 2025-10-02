#!/bin/bash

SMART_SUMMARY=""
STATE=0

# Récupération des numéros de disque via qcli_storage
DISK_IDS=$(qcli_storage -d | grep "^NAS_HOST" | awk '{print $2}')

for ID in $DISK_IDS; do
  STATUS=$(/sbin/getsysinfo hdsmart "$ID" 2>/dev/null)

  # Si la commande ne retourne rien, on ignore
  if [ -z "$STATUS" ]; then
    continue
  fi

  # Conversion du numéro en lettre (1 → a, 2 → b, etc.)
  DISK_NAME="/dev/sd$(echo "$ID" | awk '{printf("%c", 96 + $1)}')"

  case "$STATUS" in
    GOOD)
      SMART_SUMMARY+="$DISK_NAME: OK; "
      CHECK_STATE=0
      ;;
    WARNING)
      SMART_SUMMARY+="$DISK_NAME: WARNING; "
      CHECK_STATE=1
      ;;
    ABNORMAL|FAILED)
      SMART_SUMMARY+="$DISK_NAME: CRITICAL; "
      CHECK_STATE=2
      ;;
    *)
      SMART_SUMMARY+="$DISK_NAME: UNKNOWN ($STATUS); "
      CHECK_STATE=3
      ;;
  esac

  if [ "$CHECK_STATE" -gt "$STATE" ]; then
    STATE=$CHECK_STATE
  fi
done

echo "$SMART_SUMMARY"
exit $STATE
