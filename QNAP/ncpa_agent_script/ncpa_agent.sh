#!/bin/bash

# Se placer dans le répertoire du script
cd "$(dirname "$0")"

# Initialisation des variables
TOKEN=""
HOSTNAME=""
DEBUGMODE=0
HELP=0
CHECK_UPS=0

# Lecture des arguments
for arg in "$@"; do
    case $arg in
        -token=*)
            TOKEN="${arg#*=}"
            ;;
        -hostname=*)
            HOSTNAME="${arg#*=}"
            ;;
        -debug)
            DEBUGMODE=1
            ;;
        -help)
            HELP=1
            ;;
        -onduleur)
            CHECK_UPS=1
            ;;
        *)
            echo "Argument inconnu : $arg"
            ;;
    esac
done

# Vérification des arguments obligatoires
if [[ -z "$TOKEN" || -z "$HOSTNAME" ]]; then
    echo "Erreur : les options -token et -hostname sont obligatoires."
    echo ""
    HELP=1
fi

# Affichage de l'aide
if [[ $HELP == 1 ]]; then
    echo "Usage : $0 -token=\"<votre_token>\" -hostname=\"<nom_hôte>\" [-debug] [-help] [-onduleur]"
    echo ""
    echo "Options disponibles :"
    echo "  -token=...       : Clé d'authentification pour l'envoi NRDP"
    echo "  -hostname=...    : Nom d'hôte à utiliser dans les checks Nagios"
    echo "  -onduleur        : Active la vérification de l'onduleur"
    echo "  -debug           : Active le mode debug"
    echo "  -help            : Affiche cette aide"
    exit 0
fi

# Affichage des paramètres si debug activé
if [[ $DEBUGMODE == 1 ]]; then
    echo "Répertoire courant : $(pwd)"
    echo "TOKEN = $TOKEN"
    echo "HOSTNAME = $HOSTNAME"
fi

# Inclure les fonctions d'envoi NRDP
source ./send_nrdp_check_function.sh

# URL NRDP
NRDP_URL="https://nagios.awcloud.fr/nrdp/"

# === CHECKS ===

# CPU Load
RESULT_CPU_Usage=$(./check_cpu_load.sh)
STATE_CPU_Usage=$?
send_nrdp_check_service "$HOSTNAME" "CPU Usage" "$STATE_CPU_Usage" "$RESULT_CPU_Usage" "$TOKEN" "$DEBUGMODE"

# Swap Usage
RESULT_SWAP_Usage=$(./check_swap_usage.sh)
STATE_Swap_Usage=$?
send_nrdp_check_service "$HOSTNAME" "Swap Usage" "$STATE_Swap_Usage" "$RESULT_SWAP_Usage" "$TOKEN" "$DEBUGMODE"

# Memory Usage
RESULT_Memory_Usage=$(./check_memory_usage.sh)
STATE_Memory_Usage=$?
send_nrdp_check_service "$HOSTNAME" "Memory Usage" "$STATE_Memory_Usage" "$RESULT_Memory_Usage" "$TOKEN" "$DEBUGMODE"

# Process Count
RESULT_Process_Count=$(./check_process_count.sh)
STATE_Process_Count=$?
send_nrdp_check_service "$HOSTNAME" "Process Count" "$STATE_Process_Count" "$RESULT_Process_Count" "$TOKEN" "$DEBUGMODE"

# Disk Usage
RESULT_Disk_Usage=$(./check_disk_usage.sh)
STATE_Disk_Usage=$?
send_nrdp_check_service "$HOSTNAME" "Disk Usage" "$STATE_Disk_Usage" "$RESULT_Disk_Usage" "$TOKEN" "$DEBUGMODE"

# SMART Status
RESULT_SMART_Status=$(./check_smart.sh)
STATE_Disk_SMART=$?
send_nrdp_check_service "$HOSTNAME" "Disk SMART" "$STATE_Disk_SMART" "$RESULT_SMART_Status" "$TOKEN" "$DEBUGMODE"

# RAID Status
RESULT_RAID_Status=$(./check_raid.sh)
STATE_RAID_Status=$?
send_nrdp_check_service "$HOSTNAME" "RAID Status" "$STATE_RAID_Status" "$RESULT_RAID_Status" "$TOKEN" "$DEBUGMODE"

# Temperature + Fan Status
RESULT_FAN_Temperature_Status=$(./check_temperature_fan.sh)
STATE_FAN_Temperature_Status=$?
send_nrdp_check_service "$HOSTNAME" "FAN and Temperature Status" "$STATE_FAN_Temperature_Status" "$RESULT_FAN_Temperature_Status" "$TOKEN" "$DEBUGMODE"

# UPS Status (si activé)
if [[ $CHECK_UPS == 1 ]]; then
    RESULT_UPS_Status=$(./check_ups.sh)
    STATE_UPS_Status=$?
    send_nrdp_check_service "$HOSTNAME" "UPS Status" "$STATE_UPS_Status" "$RESULT_UPS_Status" "$TOKEN" "$DEBUGMODE"
else
    if [[ $DEBUGMODE == 1 ]]; then
        echo "Check UPS ignoré (option -onduleur non présente)"
    fi
    STATE_UPS_Status=0
fi

# SSH Connections
RESULT_SSH_Status=$(./check_ssh_connections.sh)
STATE_SSH_Status=$?
send_nrdp_check_service "$HOSTNAME" "SSH Connexion" "$STATE_SSH_Status" "$RESULT_SSH_Status" "$TOKEN" "$DEBUGMODE"

# === État global ===

GLOBAL_STATE=0

if [[ $STATE_Disk_SMART == 2 || $STATE_RAID_Status == 2 || $STATE_FAN_Temperature_Status == 2 ]]; then
    GLOBAL_STATE=2
elif [[ $STATE_Swap_Usage == 1 || $STATE_Memory_Usage == 1 || $STATE_Process_Count == 1 || $STATE_Disk_Usage == 1 || $STATE_UPS_Status == 1 || $STATE_FAN_Temperature_Status == 1 ]]; then
    GLOBAL_STATE=1
fi

case $GLOBAL_STATE in
    0) GLOBAL_TEXT="Tous est OK";;
    1) GLOBAL_TEXT="Attention : certains services sont en erreur";;
    2) GLOBAL_TEXT="Un service est en état critique !";;
    *) GLOBAL_TEXT="État inconnu";;
esac

# Infos système
QNAP_INFO=$(./qnap_infos.sh)
QNAP_UPTIME=$(uptime -p)

# Envoi de l'état global
send_nrdp_host "$HOSTNAME" "__HOST__" "0" "NCPA Agent ECA v1 :\n $QNAP_INFO \n $QNAP_UPTIME \n $GLOBAL_TEXT" "$TOKEN" "$DEBUGMODE"
