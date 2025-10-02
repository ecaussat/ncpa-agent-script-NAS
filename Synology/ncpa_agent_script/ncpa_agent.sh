#!/bin/bash

# Se placer dans le répertoire du script
cd "$(dirname "$0")"
#solution 2 :
#cd "$(dirname "$(readlink -f "$0")")"

# Initialisation des variables
TOKEN=""
HOSTNAME=""
DEBUGMODE=0
HELP=0
HECK_UPS=0 # Par défaut, ne pas exécuter le check UPS

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
    echo "Usage : $0 -token=\"<votre_token>\" -hostname=\"<nom_hôte>\" [-debug] [-help]"
    echo ""
    echo "Options disponibles :"
    echo "  -token=...       : Clé d'authentification pour l'envoi NRDP"
    echo "  -hostname=...    : Nom d'hôte à utiliser dans les checks Nagios"
    echo "  -onduleur           : Active la Vérification de l'onduleur"
    echo "  -debug           : Active le mode debug (affiche les variables)"
    echo "  -help            : Affiche cette aide"
    exit 0
fi

# Affichage des paramètres si debug activé :
if [[ $DEBUGMODE == 1 ]]; then
    # Vérification chemin courant :
    echo "Répertoire courant : $(pwd)"
    # Vérification info de connnexion :
    echo "TOKEN = $TOKEN"
    echo "HOSTNAME = $HOSTNAME"
fi

# Chemin d'installation du paquet Plugins Monitoring de SynoCommunity
libexec="/volume1/@appstore/monitoring-plugins/bin"
# Vérification de l'existence du dossier
if [[ ! -d "$libexec" ]]; then
    echo "Erreur : le dossier '$libexec' n'existe pas. Le paquet monitoring-plugins est-il installé ?"
    echo ""
    echo "Rappel : Pour l'installer, il faut aller sur l'interface DSM Web, ouvrir le 'Centre de paquets',"
    echo "Cliquer sur 'Paramètres' ==> 'Sources de paquet' ==> 'Ajouter' ==>"
    echo "'NOM' = 'SynoComunity'"
    echo "'Emplacement' = 'https://packages.synocommunity.com/'"
    echo "Valider par des 'OK'"
    echo "Puis, dans le Centre de paquet, dans 'Communauté' ==> chercher 'Monitoring Plugins' ==> 'Installer' ==> Valider les alerte d'installation"
    exit 3
fi

#inclu le script d'encodage et envoi
source ./send_nrdp_check_function.sh

# Paramètres NRDP
NRDP_URL="https://nagios.awcloud.fr/nrdp/"

# Exécution du check CPU Usage
RESULT_CPU_Usage=$($libexec/check_load -w 50 -c 90)
STATE_CPU_Usage=$?
send_nrdp_check_service "$HOSTNAME" "CPU Usage" "$STATE_CPU_Usage" "$RESULT_CPU_Usage" "$TOKEN" "$DEBUGMODE"

# Exécution du check Swap Usage
RESULT_SWAP_Usage=$($libexec/check_swap -w 20% -c 10%)
STATE_Swap_Usage=$?
send_nrdp_check_service "$HOSTNAME" "Swap Usage" "$STATE_Swap_Usage" "$RESULT_SWAP_Usage" "$TOKEN" "$DEBUGMODE"

# Exécution du check Memory Usage
RESULT_Memory_Usage=$(./check_mem.pl -w 90 -c 99 | sed 's/<br>.*//' )
STATE_Memory_Usage=$?
send_nrdp_check_service "$HOSTNAME" "Memory Usage" "$STATE_Memory_Usage" "$RESULT_Memory_Usage" "$TOKEN" "$DEBUGMODE"

# Exécution du check Process Count
RESULT_Process_Count=$($libexec/check_procs -w 500 -c 600)
STATE_Process_Count=$?
send_nrdp_check_service "$HOSTNAME" "Process Count" "$STATE_Process_Count" "$RESULT_Process_Count" "$TOKEN" "$DEBUGMODE"

# Exécution du check Disk Usage
RESULT_Disk_Usage=$($libexec/check_disk -w 20 -c 10 /volume1)
STATE_Disk_Usage=$?
send_nrdp_check_service "$HOSTNAME" "Disk Usage" "$STATE_Disk_Usage" "$RESULT_Disk_Usage" "$TOKEN" "$DEBUGMODE"

# Exécution du check SMART Disk
RESULT_SMART_Status=$(./check_smart.sh)
STATE_Disk_SMART=$?
send_nrdp_check_service "$HOSTNAME" "Disk SMART" "$STATE_Disk_SMART" "$RESULT_SMART_Status" "$TOKEN" "$DEBUGMODE"

# Exécution du check RAID Status
RESULT_RAID_Status=$(./check_raid.sh)
STATE_RAID_Status=$?
send_nrdp_check_service "$HOSTNAME" "RAID Status" "$STATE_RAID_Status" "$RESULT_RAID_Status" "$TOKEN" "$DEBUGMODE"

# Exécution du check Temperature Status
RESULT_Temperature_Status=$(./check_temp.sh)
STATE_Temperature_Status=$?
send_nrdp_check_service "$HOSTNAME" "Temperature Status" "$STATE_Temperature_Status" "$RESULT_Temperature_Status" "$TOKEN" "$DEBUGMODE"

# Exécution du check UPS Status
#nécéssite qu'un onduleur soit en place ET que le serveur UPS soit configuré et autorise la connexion de 127.0.0.1
if [[ $CHECK_UPS == 1 ]]; then
    RESULT_UPS_Status=$($libexec/check_ups -H 127.0.0.1 -u ups)
    STATE_UPS_Status=$?
    send_nrdp_check_service "$HOSTNAME" "UPS Status" "$STATE_UPS_Status" "$RESULT_UPS_Status" "$TOKEN" "$DEBUGMODE"
else
    if [[ $DEBUGMODE == 1 ]]; then
        echo "Check UPS ignoré (option -onduleur non présente)"
    fi
    STATE_UPS_Status=0  # Considéré comme OK pour l'état global
fi

# Exécution du check FAN Status
RESULT_FAN_Status=$(./check_fan.sh)
STATE_FAN_Status=$?
send_nrdp_check_service "$HOSTNAME" "FAN Status" "$STATE_FAN_Status" "$RESULT_FAN_Status" "$TOKEN" "$DEBUGMODE"

# Exécution du check SSH Connexion
RESULT_SSH_Status=$(./check_ssh_connections.sh)
STATE_SSH_Status=$?
send_nrdp_check_service "$HOSTNAME" "SSH Connexion" "$STATE_SSH_Status" "$RESULT_SSH_Status" "$TOKEN" "$DEBUGMODE"

# Initialisation de l'état global
GLOBAL_STATE=0  # 0 = OK, 1 = WARNING, 2 = CRITICAL

# Vérification des checks critiques et Warning pour définir l'état de l'hote en WARNING si un service pose problème
if [[ $STATE_Disk_SMART == 2 ]]; then GLOBAL_STATE=2; fi
if [[ $STATE_RAID_Status == 2 ]]; then GLOBAL_STATE=2; fi
if [[ $STATE_Temperature_Status == 2 ]]; then GLOBAL_STATE=2; fi
if [[ $GLOBAL_STATE == 0 ]]; then
  if [[ $STATE_Swap_Usage == 1 ]]; then GLOBAL_STATE=1; fi
  if [[ $STATE_Memory_Usage == 1 ]]; then GLOBAL_STATE=1; fi
  if [[ $STATE_Process_Count == 1 ]]; then GLOBAL_STATE=1; fi
  if [[ $STATE_Disk_Usage == 1 ]]; then GLOBAL_STATE=1; fi
  if [[ $STATE_UPS_Status == 1 ]]; then GLOBAL_STATE=1; fi
  if [[ $STATE_FAN_Status == 1 ]]; then GLOBAL_STATE=1; fi
fi
case $GLOBAL_STATE in
  0) GLOBAL_TEXT="Tous est OK";;
  1) GLOBAL_TEXT="Attention certain services sont en erreur";;
  2) GLOBAL_TEXT="Un service est en état critique !";;
  *) GLOBAL_TEXT="Etat inconnu";;
esac

# Envoi de l'état global en tant que check host + VERSION
SYNO_INFO=$(./syno_infos.sh)
SYNO_UPTIME=$(uptime -p)
send_nrdp_host "$HOSTNAME" "__HOST__" "0" "NCPA Agent ECA v1 :\n $SYNO_INFO \n $SYNO_UPTIME \n $GLOBAL_TEXT" "$TOKEN" "$DEBUGMODE"
