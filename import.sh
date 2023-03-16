#!/bin/bash

####################################################################################################
#                                                                                                  #
# [ Created At ]   : 03-10-2022                                                                    #
# [ LastUpdate ]   : 16-03-2023                                                                    #
# [ Description ]  : Script d'envoie des donnees dans Alfresco (PDF + metadonnees issues de la BD) #
# [ Author(s) ]    : NANFACK STEVE ULRICH                                                          #
# [ email(s) ]     : nanfacksteve7@gmail.com                                                       #
# [ contributors ] : Mr PROSPER OTTOU (DSI BUNEC) / Mr MANI OMGBA                                  #
#                                                                                                  #
####################################################################################################

# Test du nombre d'arguments
if [ "$#" -ne 2 ]; then
    echo -e "\nMauvais usage du script: \nSaisissez: ./import.sh path_to_pdf_folder path_to_file.csv \n"
    exit 1
fi

# Test Existence Dossier/CSV
if [ ! -d "$1" ] || [ ! -e "$2" ]; then
    echo -e "\nCe Dossier ou fichier csv n'existe pas !!\n"
    exit 1
fi

csvFile="$2"
full_path="$1"
endFolder="$(basename $full_path)"
grn='\e[1;32m' && red='\e[1;31m' && blu='\e[1;96m' && ylw='\e[1;93m' && nc='\e[0m' # Color's Message

# Test si Dossier = [ Registre | ID_agent ]
[[ "$endFolder" =~ ^[0-9]+$ ]] && type_dir='ID' || type_dir='register'

# Recuperation des parametres de connexion
read -r -a paramConn <<<"$(grep -v "AdresseIP port user password" parametresConnex.cfg)"
alfresco_target=${paramConn[4]:1:-1}
[[ -n "$(echo "${alfresco_target}" | egrep "Partagé|Shared")" ]] && alfresco_dir="Partagé|Shared" || alfresco_dir="${alfresco_target}"
[[ -n "$(echo "${alfresco_dir}" | egrep "Partagé|Shared")" ]] && src="-root-" || src="-shared-"

# Connexion Alfresco - Recupere ticket
reponse=$(curl -s -X POST "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/authentication/versions/1/tickets" -H "Content-Type: application/json" -d "{\"userId\": \"${paramConn[2]}\", \"password\": \"${paramConn[3]}\" }")
ticket=$(echo "$reponse" | grep -E -o "TICKET_[a-zA-Z0-9]*") # ou encore ticket=$(echo "$reponse" | cut -d'"' -f6)
#echo $ticket && exit

# Recupere l'ID du dossier $alfresco_dir
rep1=$(curl -s -X GET "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/alfresco/versions/1/nodes/${src}/children?alf_ticket=${ticket}")
ID_dir_alfresco=$(echo "$rep1" | grep -E -o "\"(${alfresco_dir})\",\"id\":\"[-a-zA-Z0-9]*" | cut -d'"' -f6) # ou encore ID_dir_alfresco=$(echo "$rep1" | cut -d'"' -f258)
if [ -z "$ID_dir_alfresco" ]; then echo -e "\n$red[ Error ] : Dossier ( $blu${alfresco_target}$red ) inexistant dans Alfresco\n" && exit 1; fi

# Importations des fonctions d'importations
source functions_reprise.sh
source functions_digit.sh

case "$type_dir" in

"ID")
    import_agent "$full_path" "$csvFile"
    ;;

"register")
    echo '=register'
    ;;

*)
    echo "Type de Dossier inconnu"
    ;;
esac

echo "fin case" && exit 0
