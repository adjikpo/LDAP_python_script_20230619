#!/bin/bash


# Charger les variables d'environnement à partir du fichier .env
source .extract.env

# Exécuter le script Python et capturer la sortie dans des variables
credentials=$(python extract_server_ldap_vault.py)

# Extraire le login et le mot de passe à partir de la sortie capturée
ldap_username=$(echo "$credentials" | awk '{print $1}')
ldap_password=$(echo "$credentials" | awk '{print $2}')


# Fonction pour établir la connexion LDAP
establish_ldap_connection() {
    local server="$1"
    local port="$2"
    local username="$3"
    local password="$4"

    export LDAPTLS_REQCERT=never
    ldapsearch_cmd="ldapsearch -x -H $server:$port -D \"$username\" -w \"$password\""

    # Exécuter la commande ldapsearch en arrière-plan pour établir la connexion
    eval "$ldapsearch_cmd" &
    ldapsearch_pid=$!

    # Attendre que la connexion soit établie
    while ! kill -0 $ldapsearch_pid 2>/dev/null; do
        sleep 1
    done
    unset LDAPTLS_REQCERT
}

# Fonction pour effectuer la recherche LDAP avec le memberuid
search_ldap_by_memberuid() {
    export LDAPTLS_REQCERT=never
    local memberuid="$1"

    search_filter="(&(objectclass=person)(uid=$memberuid))"
    attributes=("objectClass" "givenName" "sn" "gidNumber" "roomNumber" "uidNumber" "cn" "uid" "mail" "homeDirectory" )

    # Effectuer la recherche LDAP
    conn=$(ldapsearch -x -LLL -H "$ldap_server:$ldap_port" -D "$ldap_username" -w "$ldap_password" -b "$search_base" -s sub "$search_filter" "${attributes[@]}" )

    # Afficher les résultats de la recherche
    if [ -n "$conn" ]; then
        echo "dn: uid=$memberuid,ou=users,dc=vpa,dc=enedis,dc=fr"
        echo "$conn"
        echo
    else
        echo "Aucun résultat LDAP trouvé pour le MemberUID: $memberuid"
    fi
    unset LDAPTLS_REQCERT
}

# Établir la connexion LDAP
establish_ldap_connection "$ldap_server" "$ldap_port" "$ldap_username" "$ldap_password"

# Vérifier si la connexion est établie avec succès
if [ $? -eq 0 ]; then
    echo "Connexion LDAP établie avec succès."

    # Lecture du fichier LDIF
    while IFS= read -r line; do
        if [[ $line =~ ^cn:\ (.*) ]]; then
            cn="${BASH_REMATCH[1]}"
            filename="${cn// /_}.ldif"  # Remplace les espaces par des underscores et ajoute l'extension .ldif
            echo "CN: $cn"
        elif [[ $line =~ ^memberUid:\ (.*) ]]; then
            memberuid="${BASH_REMATCH[1]}"
            echo "memberUID: $memberuid"
            search_ldap_by_memberuid "$memberuid"  >> "$filename"
        fi
    done < "$ldif_file"
else
    echo "Échec de la connexion LDAP."
fi