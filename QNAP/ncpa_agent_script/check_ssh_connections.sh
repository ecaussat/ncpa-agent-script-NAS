#!/bin/bash

START_HOUR=18
END_HOUR=9
CURRENT_HOUR=$(date +%H)

# Connexions SSH actives via netstat
SSH_CONNECTIONS=$(netstat -tnp 2>/dev/null | grep ':22 ' | grep ESTABLISHED)
COUNT=$(echo "$SSH_CONNECTIONS" | grep -c '^')

if [ "$CURRENT_HOUR" -ge "$START_HOUR" ] || [ "$CURRENT_HOUR" -lt "$END_HOUR" ]; then
    STATUS="CRITICAL - SSH connections detected:"
    EXIT_CODE=2
else
    STATUS="OK - Utilisateur(s) connecté(s) dans les heures de bureau :"
    EXIT_CODE=0
fi

# Valeur par défaut pour HZ si getconf est absent
HZ=100
UPTIME=$(awk '{print int($1)}' /proc/uptime)

# Boucle sans sous-shell
while IFS= read -r line; do
    remote=$(echo "$line" | awk '{print $5}')
    pidprog=$(echo "$line" | awk '{print $7}')
    pid=$(echo "$pidprog" | cut -d'/' -f1)

    # Extraction du nom d'utilisateur depuis le champ sshd:username si présent
    user=$(echo "$SSH_CONNECTIONS" | awk -F'sshd: ' '{print $2}')
    
    # Fallback via ps si le nom n'est pas trouvé
    if [ -z "$user" ] && [[ "$pid" =~ ^[0-9]+$ ]]; then
        user=$(ps -o user= -p "$pid" 2>/dev/null | awk '{print $1}')
    fi

    [ -z "$user" ] && user="unknown"

    # Calcul de la durée de session
    if [ -r "/proc/$pid/stat" ]; then
        start_jiffies=$(awk '{print $22}' /proc/$pid/stat)
        start_seconds=$((start_jiffies / HZ))
        duration_sec=$((UPTIME - start_seconds))

        #duration=$(printf '%dd %02dh %02dm %02ds' $((duration_sec/86400)) $((duration_sec%86400/3600)) $((duration_sec%3600/60)) $((duration_sec%60)))

        if [ "$duration_sec" -ge 86400 ]; then
            # Plus d'un jour
            duration=$(printf '%dd %02dh %02dm' $((duration_sec/86400)) $((duration_sec%86400/3600)) $((duration_sec%3600/60)))
        elif [ "$duration_sec" -ge 3600 ]; then
            # Plus d'une heure
            duration=$(printf '%02dh %02dm %02ds' $((duration_sec/3600)) $((duration_sec%3600/60)) $((duration_sec%60)))
        else
            # Moins d'une heure
            duration=$(printf '%02dm %02ds' $((duration_sec/60)) $((duration_sec%60)))
        fi

    else
        duration="unknown"
    fi

    STATUS="$STATUS $user, source $remote, depuis $duration"
done <<< "$SSH_CONNECTIONS"

echo "$STATUS"
exit $EXIT_CODE

