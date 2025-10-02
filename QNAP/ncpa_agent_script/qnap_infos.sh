#!/bin/bash

CONF_FILE="/etc/config/uLinux.conf"

# Extraction des infos système
MODEL=$(grep -i "^Model =" "$CONF_FILE" | cut -d= -f2 | xargs)
SERIAL=$(/sbin/get_hwsn)
VERSION=$(grep -i "^Version =" "$CONF_FILE" | head -n1 | cut -d= -f2 | xargs)
NUMBER=$(grep -i "^Number =" "$CONF_FILE" | head -n1 | cut -d= -f2 | xargs)
BUILD=$(grep -i "^Build Number =" "$CONF_FILE" | head -n1 | cut -d= -f2 | xargs)

# Affichage formaté
echo "QNAP $MODEL, S/N: ${SERIAL:-inconnu}, QTS $VERSION.$NUMBER Build $BUILD"
