#!/bin/bash

# Charger les variables d'environnement à partir du fichier .env
source .env


# Exécuter le script Python et capturer la sortie dans des variables
credentials=$(python import_server_ldap_vault.py)

# Extraire le login et le mot de passe à partir de la sortie capturée
ldap_username=$(echo "$credentials" | awk '{print $1}')
ldap_password=$(echo "$credentials" | awk '{print $2}')


# Fonction pour établir la connexion LDAP
establish_ldap_connection() {
    export LDAPTLS_REQCERT=never

    local server="$1"
    local port="$2"
    local username="$3"
    local password="$4"

    ldapsearch_cmd="ldapsearch -x -H $server:$port -D \"$username\" -w \"$password\""

    # Exécuter la commande ldapsearch en arrière-plan
    ldap_output=$(eval "$ldapsearch_cmd" 2>&1 &)
    ldapsearch_pid=$!

    # Attendre que le processus ldapsearch en arrière-plan se termine
    wait $ldapsearch_pid

    # Vérifier si la commande a réussi en vérifiant le code de sortie
    if [ $? -eq 0 ]; then
    # Vérifier la présence de la chaîne "LDAPv3" dans la sortie
        if echo "$ldap_output" | grep -q "LDAPv3"; then
            echo "Connexion réussie : $ldap_output"
            return 0
        else
            echo "Échec de la connexion : $ldap_output"
            return 1
        fi
    else
        echo "Échec de la commande ldapsearch : $ldap_output"
        return 1
    fi
}


# Fonction pour lire un fichier LDIF et ajouter les DNs d'utilisateurs avec les attributs uid, mail et homedirectory à l'OU "users"
add_users_to_ou() {
    local ldif_file="$1"
    local server="$2"
    local port="$3"
    local username="$4"
    local password="$5"

    # Utiliser la commande ldapadd pour ajouter les utilisateurs à l'OU "users"
    ldapadd_cmd="LDAPTLS_REQCERT=never ldapadd -x -H $server:$port -D \"$username\" -w \"$password\" -f $ldif_file"
    eval "$ldapadd_cmd"
}


# Tenter d'établir la connexion au premier serveur
if establish_ldap_connection "$first" "$ldap_port" "$ldap_username" "$ldap_password"; then
    echo "Connexion réussie à First. Ajout des utilisateurs..."
    for input_file in "${input_files[@]}"; do
        # Ajouter les utilisateurs au premier serveur
        add_users_to_ou "$input_file" "$first" "$ldap_port" "$ldap_username" "$ldap_password"
    done
        # Parcourir tous les fichiers LDIF dans le répertoire
    for ldif_file in ./vpa*.ldif; do

        # Renommer le fichier avec l'extension .old
        mv "$ldif_file" "${ldif_file}.old"

    done

    echo "Renommage terminés."

else

    echo "La connexion à First a échoué. Tentative de connexion à Second..."

    # Tenter d'établir la connexion au deuxième serveur
    if establish_ldap_connection "$Second" "$ldap_port" "$ldap_username" "$ldap_password"; then
        echo "Connexion réussie à Second. Ajout des utilisateurs..."
        for input_file in "${input_files[@]}"; do
            # Ajouter les utilisateurs au deuxième serveur
            add_users_to_ou "$input_file" "$Second" "$ldap_port" "$ldap_username" "$ldap_password"
        done
            # Parcourir tous les fichiers LDIF dans le répertoire
        for ldif_file in ./vpa*.ldif; do

            # Renommer le fichier avec l'extension .old
            mv "$ldif_file" "${ldif_file}.old"

        done

           echo "Renommage terminés."

    else
        echo "La connexion à Second a également échoué."
        exit 1
    fi
fi