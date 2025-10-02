
# Fonction Bash : send_nrdp_host
send_nrdp_host() {
  local HOSTNAME="$1"
  local SERVICENAME="$2"
  local STATE="$3"
  local RESULT="$4"
  local TOKEN="$5"
  local DEBUGMODE="$6"
  local NRDP_URL="https://nagios.awcloud.fr/nrdp/"

  # Nettoyage du résultat
  RESULT=$(echo "$RESULT" | sed 's/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g')

  # Construction du XML
  local XML="<?xml version='1.0'?>
<checkresults>
  <checkresult type='host'>
    <hostname>${HOSTNAME}</hostname>
    <servicename>${SERVICENAME}</servicename>
    <state>${STATE}</state>
    <output>${RESULT}</output>
  </checkresult>
</checkresults>"

  # Encodage du XML
  local ENCODED_XML=$(echo "$XML" | jq -s -R -r @uri)

  # Envoi via curl et capture de la réponse
  local RESPONSE=$(curl -s -k -X POST "$NRDP_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data "token=${TOKEN}&cmd=submitcheck&xml=${ENCODED_XML}")

  # Affichage de debug si BAD XML
  if echo "$RESPONSE" | grep -q "BAD XML"; then
    echo "❌ ERREUR : BAD XML détecté"
    echo "🔍 XML brut :"
    echo "$XML"
    echo "🔍 XML encodé :"
    echo "$ENCODED_XML"
    echo "🔍 Réponse complète :"
    echo "$RESPONSE"
  else
    echo "✅ Check envoyé avec succès : $SERVICENAME"
    if [[ $DEBUGMODE == 1 ]]; then
        echo "DEBUG : $RESPONSE"
    fi
  fi
}


send_nrdp_check_service() {
  local HOSTNAME="$1"
  local SERVICENAME="$2"
  local STATE="$3"
  local RESULT="$4"
  local TOKEN="$5"
  local DEBUGMODE="$6"
  local NRDP_URL="https://nagios.awcloud.fr/nrdp/"
  # Nettoyage du résultat
  RESULT=$(echo "$RESULT" | sed 's/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g')

  # Construction du XML
  local XML="<?xml version='1.0'?>
<checkresults>
  <checkresult type='service'>
    <hostname>${HOSTNAME}</hostname>
    <servicename>${SERVICENAME}</servicename>
    <state>${STATE}</state>
    <output>${RESULT}</output>
  </checkresult>
</checkresults>"

  # Encodage du XML
  local ENCODED_XML=$(echo "$XML" | jq -s -R -r @uri)

 # Envoi via curl et capture de la réponse
  local RESPONSE=$(curl -s -k -X POST "$NRDP_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data "token=${TOKEN}&cmd=submitcheck&xml=${ENCODED_XML}")

  # Affichage de debug si BAD XML
  if echo "$RESPONSE" | grep -q "BAD XML"; then
    echo "❌ ERREUR : BAD XML détecté"
    echo "🔍 XML brut :"
    echo "$XML"
    echo "🔍 XML encodé :"
    echo "$ENCODED_XML"
    echo "🔍 Réponse complète :"
    echo "$RESPONSE"
  else
    echo "✅ Check envoyé avec succès : $SERVICENAME"
    if [[ $DEBUGMODE == 1 ]]; then
        echo "DEBUG : $RESPONSE"
    fi
  fi
}
