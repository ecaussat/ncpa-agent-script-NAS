#!/bin/bash

START_HOUR=18
END_HOUR=9

CURRENT_HOUR=$(date +%H)
SSH_CONNECTIONS=$(who | grep -E '(:[0-9]+|pts/[0-9]+)' | wc -l)
CONNECTIONS=$(who | grep -E '(:[0-9]+|pts/[0-9]+)')

if [ $CURRENT_HOUR -ge $START_HOUR ] || [ $CURRENT_HOUR -lt $END_HOUR ]; then
    if [ $SSH_CONNECTIONS -gt 0 ]; then
        echo "CRITICAL - SSH/Terminal connections detected : $CONNECTIONS"
        exit 2
    else
        echo "OK - No SSH/Terminal connections"
        exit 0
    fi
else
    echo "OK - Outside monitoring hours : $CONNECTIONS"
    exit 0
fi
