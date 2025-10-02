
## Instructions pour QNAP :

-Activer l'accès SSH depuis l'interface web du QNAP

-Se connecter avec un client SSH comme Putty ou Bitvise.

-Passer en admin (root) : (saisi du mot de passe requis)
`sudo bash`

-Aller au dossier home du compte administrateur (en générale c'est dans dans /share/CACHEDEV1_DATA/homes/admin) :
`cd /share/CACHEDEV1_DATA/homes/admin`

-Télécharger l'archive zip pour qnap :
`curl -O -L https://raw.githubusercontent.com/ecaussat/ncpa-agent-script-NAS/refs/heads/main/QNAP/ncpa_agent_script.zip`

-Décompresser l'archive, aller dans le dossier et donner les droits en execution :
`unzip ncpa_agent_script.zip`
`cd ncpa_agent_script`
`chmod +x *.sh`

-Vérifier si toutes les étapes précédentes ont fonctionner : (la commande "ls" doit afficher les fichiers en vert)
`ls`

Pour la suite, il faut ajouter l'hôte côté serveur Nagios

-Vérifier le bon fonctionnement de l'agent en mode debug et voir si les infos remonte sur le serveur NAGIOS :
`/share/CACHEDEV1_DATA/homes/admin/ncpa_agent_script/ncpa_agent.sh -token="**SECRET_TOKEN_CONF_SUR_NAGIOS**" -hostname="**NOM_DHOTE_DEFINI_SUR_NAGIOS**" -debug`
(ajouter -ups si onduleur à contrôler)

-Une fois le bon fonctionnement valider par le test manuelle, il faut configurer la tâche planifier pour s’exécuter régulièrement et finaliser la mise en place :
(dans cette exemple, l'agent se lance toute les deux minutes)

`vi /etc/config/crontab`

> `*/2 * * * *
> /share/CACHEDEV1_DATA/homes/admin/ncpa_agent_script/ncpa_agent.sh
> -token="**SECRET_TOKEN_CONF_SUR_NAGIOS**" -hostname="**NOM_DHOTE_DEFINI_SUR_NAGIOS**" 1>/dev/null 2>/dev/null`

`crontab /etc/config/crontab && /etc/init.d/crond.sh restart`
