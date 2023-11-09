#!/bin/bash

# Charger les variables d'environnement à partir du fichier .env
source ../config/extract.env

# Exécuter le script Python et capturer la sortie dans des variables
credentials=$(python ../config/extract_server_ldap_vault.py)

# Extraire le login et le mot de passe à partir de la sortie capturée
ldap_username=$(echo "$credentials" | awk '{print $1}')
ldap_password=$(echo "$credentials" | awk '{print $2}')

# Fonction pour extraire les données de LDAP
extract_data_from_ldap() {
    export LDAPTLS_REQCERT=never
    local search_filter="Filtre sur les groupes"

    ldapsearch -LLL -H "$ldap_server" -D "$ldap_username" -w "$ldap_password" -b "$search_base" "$search_filter"
    unset LDAPTLS_REQCERT

}

# Fonction pour exporter les données au format LDIF
export_to_ldif() {
    local data="$1"
    local filename="$2"

    if [ -z "$data" ]; then
        echo "Aucune donnée LDAP trouvée."
        return
    fi

    while read -r line; do
        echo "$line" >> "$filename"
    done <<< "$data"
}

# Exécution du script
data=$(extract_data_from_ldap)
export_to_ldif "$data" "vpa_group_extract.ldif"