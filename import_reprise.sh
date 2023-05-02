#!/bin/bash

####################################################################################################
#                                                                                                  #
# [ Created At ]   : 03-10-2022                                                                    #
# [ LastUpdate ]   : 13-04-2023                                                                    #
# [ Description ]  : Script d'envoie des donnees de REPRISE dans Alfresco                          #
#                    (PDF + metadonnees issues de la BD)                                           #
#                                                                                                  #
# [ Author(s) ]    : NANFACK STEVE ULRICH                                                          #
# [ email(s) ]     : nanfacksteve7@gmail.com                                                       #
# [ contributors ] : Mr PROSPER OTTOU (DSI BUNEC) / Mr MANI OMGBA                                  #
#                                                                                                  #
####################################################################################################

red='\e[1;31m' && grn='\e[1;32m' && vlt='\e[1;35m' && ylw='\e[1;93m' blu='\e[1;94m' && wht='\e[1;97m' && nc='\e[0m' # Color's Message

# Test du nombre d'arguments
if [ "$#" -ne 3 ]; then
    echo -e "\nMauvais usage du script: \nSaisissez: ./import_reprise.sh path_to_pdf_folder path_to_file.csv certificate_type\n"
    exit 1
fi

# Test Existence Dossier/CSV
[[ ! -d "$1" ]] && echo -e "\n$red[Error] : Dossier $nc($1) $red inexistant !!! \n" && exit 1
[[ ! -e "$2" ]] && echo -e "\n$red[Error] : Fichier $nc($2) $red inexistant !!! \n" && exit 1

csvFile="$2"
[[ "$1" = */ ]] && full_path="$1" || full_path="$1/" # ajoute un '/' si necessaire
end_path_dir="$(basename $full_path)"

# Test si Dossier = [ Registre | ID_agent ]
type_dir='unknown'
[[ "$end_path_dir" =~ ^[0-9]+$ ]] && type_dir='ID'
[[ "$end_path_dir" =~ ^[0-9]+.[A-Z0-9_-]+.[0-9]+$ ]] && type_dir='register'
#echo $type_dir && exit 0
[[ $type_dir = 'unknown' ]] && echo -e "\n$red[Error] : Le dossier $ylw($end_path_dir) $red n'est ni un$vlt registre, $red ni un$vlt dossier id \n" && exit 1

# Test Type d'acte = [ naissance | mariage | deces ]
type_certificate="$3"

# Recuperation des parametres de connexion
read -r -a paramConn <<<"$(grep -v "AdresseIP port user password" parametresConnex.cfg)"
alfresco_target=${paramConn[4]:1:-1}
[[ -n "$(echo "${alfresco_target}" | egrep "Partagé|Shared")" ]] && alfresco_dir="Partagé|Shared" || alfresco_dir="${alfresco_target}"
[[ -n "$(echo "${alfresco_dir}" | egrep "Partagé|Shared")" ]] && src="-root-" || src="-shared-"

# Connexion Alfresco - Recupere ticket
reponse=$(curl -s -X POST "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/authentication/versions/1/tickets" -H "Content-Type: application/json" -d "{\"userId\": \"${paramConn[2]}\", \"password\": \"${paramConn[3]}\" }")
ticket=$(echo "$reponse" | grep -E -o "TICKET_[a-zA-Z0-9]*") # ou encore ticket=$(echo "$reponse" | cut -d'"' -f6)
[[ -z "$ticket" ]] && echo -e "$red\n[ Error ] : Impossible de se connecter a Alfresco \n" && exit 1
#echo $ticket && exit

# Recupere l'ID du dossier $alfresco_dir
rep1=$(curl -s -X GET "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/alfresco/versions/1/nodes/${src}/children?alf_ticket=${ticket}")
ID_dir_alfresco=$(echo "$rep1" | grep -E -o "\"(${alfresco_dir})\",\"id\":\"[-a-zA-Z0-9]*" | cut -d'"' -f6) # ou encore ID_dir_alfresco=$(echo "$rep1" | cut -d'"' -f258)
if [ -z "$ID_dir_alfresco" ]; then echo -e "\n$red[ Error ] : Dossier ( $blu${alfresco_target}$red ) inexistant dans Alfresco\n" && exit 1; fi

# Importations des fonctions d'importations
source functions_reprise.sh
status_import=false

case "$type_certificate" in

"naissances")
    import_birth_certificate
    status_import=true
    ;;

"mariages")
    import_weeding_certificate
    status_import=true
    ;;
"deces")
    import_death_certificate
    status_import=true
    ;;
*)
    echo -e "$red\n[ Error ] : Type d'Acte inconnu.! $nc\n"
    echo -e "Choisir entre [ naissances | mariages | deces ]\n" && exit 1
    ;;
esac

[[ $status_import = true ]] && echo -e "$grn\nImportation reussie !$nc\n" || echo -e "$red\nImportation echouee !$nc\n"
