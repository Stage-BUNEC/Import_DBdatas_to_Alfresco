#!/bin/bash

# [ LastUpdate ]  : 03-10-2022
# [ Description ] : Script d'envoie des donnees dans Alfresco (PDF + metadonnees)
# [ Author(s) ]   : Mr MANI / NANFACK STEVE

# Test du nombre d'arguments
if [ "$#" -ne 1 ]; then
    echo -e "\nMauvais usage du script: \nSaisissez: ./import.sh path_to_file.csv \n"
    exit 1
fi

csvFile=$1
# Variables Auxiliaires
date=$(date '+%F_%X')
path=${csvFile%/[a-zA-Z]*}/

if [ ! -e "$csvFile" ]; then
    echo -e "\nErreur: Fichier Inexistant\n"
    exit 1
fi

# Creation Tablau Associatif
declare -A postFiedls=()

# Recuperation des parametres de connexion
read -r -a paramConn <<<"$(grep -v "AdresseIP port user password" parametresConnex.cfg)"

while read -r ligne; do

    IFS="#" read -r -a datas <<<"$(echo "$ligne" | cat)"

    #-------- Extraction des Meta donnees -----------#

    # Infos enfants
    postFiedls['nom']="${datas[0]}"
    postFiedls['prenom']="${datas[1]}"
    postFiedls['dateNaiss']="${datas[2]}"
    postFiedls['lieuNaiss']="${datas[3]}"
    postFiedls['sexe']="${datas[4]}"

    # Infos Pere enfant
    postFiedls['nomsPere']="${datas[5]}"
    postFiedls['dateNaissPere']="${datas[6]}"
    postFiedls['neVersPere']="${datas[7]}"
    postFiedls['lieuNaissPere']="${datas[25]}"
    postFiedls['domicilePere']="${datas[8]}"
    postFiedls['professionPere']="${datas[10]}"
    postFiedls['nationalitePere']="${datas[9]}"
    postFiedls['docRefPere']="${datas[24]}"

    # Infos Mere enfant
    postFiedls['nomsMere']="${datas[11]}"
    postFiedls['dateNaissMere']="${datas[12]}"
    postFiedls['neVersMere']="${datas[13]}"
    postFiedls['lieuNaissMere']="${datas[14]}"
    postFiedls['domicileMere']="${datas[15]}"
    postFiedls['professionMere']="${datas[16]}"
    postFiedls['nationaliteMere']="${datas[17]}"
    postFiedls['docRefMere']="${datas[18]}"

    # Infos Agents
    postFiedls['nomDeclarant']="${datas[20]}"
    postFiedls['qualDeclarant']="${datas[21]}"
    postFiedls['dateSignature']="${datas[22]}"
    postFiedls['dresseLe']="${datas[26]}"
    postFiedls['officier']="${datas[27]}"
    postFiedls['secretaire']="${datas[28]}"
    postFiedls['mentionMarg']="${datas[29]}"

    # Infos fichier
    postFiedls['num_acte']="${datas[23]}"
    postFiedls['registre']="${datas[30]}"
    postFiedls['fileName']="${datas[31]}"
    postFiedls['path']="${datas[32]}"

    # Affichage Meta Donnees
    #for key in ${!postFiedls[*]}; do echo "$key --> ${postFiedls[$key]}"; done

    #------- Connexion a Alfrsco --------------#

    # Recupere ticket
    reponse=$(curl -s -X POST "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/authentication/versions/1/tickets" -H "Content-Type: application/json" -d "{\"userId\": \"${paramConn[2]}\", \"password\": \"${paramConn[3]}\" }")
    ticket=$(echo "$reponse" | grep -E -o "TICKET_[a-zA-Z0-9]*") # ou encore ticket=$(echo "$reponse" | cut -d'"' -f6)

    # Recupere l'ID du dossier Partage/Shared
    rep1=$(curl -s -X GET "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/alfresco/versions/1/nodes/-root-/children?alf_ticket=${ticket}")
    sharedID=$(echo "$rep1" | grep -E -o "\"Shared\",\"id\":\"[-a-zA-Z0-9]*" | cut -d'"' -f6) # ou encore sharedID=$(echo "$rep1" | cut -d'"' -f258)

    # Creation noeud/Dossier dans Partage/Shared
    rep2=$(curl -s -X POST -H "Content-Type: application/json" "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/alfresco/versions/1/nodes/${sharedID}/children?alf_ticket=${ticket}" -d '{"name":"'"${postFiedls['registre']}"'", "nodeType":"cm:folder"}')
    (echo "$rep2" | grep -E -o "\"statusCode\":[0-9]*" >/dev/null) # recupere "statusCode" mais ne fait rien

    # Envoie des donnees SSI le fichier existe
    if [ -e "$path${postFiedls['fileName']}" ]; then
        rep3=$(curl -s -X POST -H "Content-Type: multipart/form-data" -F "filedata"="@$path${postFiedls['fileName']}" -F "relativePath"="${postFiedls['registre']}" \
            -F "bc:numact"="${postFiedls['num_acte']}" -F "bc:firstname"="${postFiedls['nom']}" -F "bc:lastname"="${postFiedls['prenom']}" -F "bc:bornOnThe"="${postFiedls['dateNaiss']}" -F "bc:bornAt"="${postFiedls['lieuNaiss']}" -F "bc:sex"="${postFiedls['sexe']}" \
            -F "bc:of"="${postFiedls['nomsPere']}" -F "bc:fOnThe"="" -F "bc:fAt"="${postFiedls['lieuNaissPere']}" -F "bc:fresid"="${postFiedls['domicilePere']}" -F "bc:foccupation"="${postFiedls['professionPere']}" -F "bc:fnationality"="${postFiedls['nationalitePere']}" -F "bc:fdocref"="${postFiedls['docRefPere']}" \
            -F "bc:mof"="${postFiedls['nomsMere']}" -F "bc:mAt"="${postFiedls['lieuNaissMere']}" -F "bc:mOnThe"="" -F "bc:mresid"="${postFiedls['domicileMere']}" -F "bc:mOccupation"="${postFiedls['professionMere']}" -F "bc:mnationality"="${postFiedls['nationaliteMere']}" -F "bc:mdocref"="${postFiedls['docRefMere']}" \
            -F "bc:drawingUp"="${postFiedls['dresseLe']}" -F "bc:ondecof"="${postFiedls['qualDeclarant']}" -F "bc:byUs"="${postFiedls['officier']}" -F "bc:assistedof"="${postFiedls['secretaire']}" -F "bc:onthe"="${postFiedls['dateSignature']}" -F "bc:mentionMarg"="${postFiedls['mentionMarg']}" \
            "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/alfresco/versions/1/nodes/-shared-/children?alf_ticket=${ticket}")
        echo "[ $date ]: $rep3" >>send.log
    fi

done < <(grep -v "nomsenfant#prenomsenfant#datenaissenfant#lieunaissenfant#sexe#" "$csvFile")

# Suppression tableau%-
unset postFiedls
