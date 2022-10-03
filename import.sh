#!/bin/bash

# [ LastUpdate ]  : 03-10-2022
# [ Description ] : Script d'envoie des donnees dans Alfresco (PDF + metadonnees)
# [ Author(s) ]   : Mr MANI / NANFACK STEVE

#csvfile=en4201_reprise_naissance.csv
csvFile=$1

# Recupere Nbre de Ligne
#nbrLign=$(grep -c "" "$csvFile")

# Recupere Nbre de Champ
# nbrColn=$(awk -F# '{print NF; exit;}' "$csvFile")

# Creation Tablau Associatif
declare -A postFiedls=()

i=1
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
    reponse=$(curl -s -X POST http://172.16.1.99:8080/alfresco/api/-default-/public/authentication/versions/1/tickets -H "Content-Type: application/json" -d '{"userId": "admin", "password": "bunec"}')
    ticket=$(echo "$reponse" | cut -d'"' -f6)

    # Recupere l'ID du dossier Partage/Shared
    rep=$(curl -s -X GET "http://172.16.1.99:8080/alfresco/api/-default-/public/alfresco/versions/1/nodes/-root-/children?alf_ticket=${ticket}")
    sharedID=$(echo "$rep" | cut -d'"' -f258)

    # Creation noeud/Dossier dans Partage/Shared
    dossier=${postFiedls['registre']}
    rep2=$(curl -s -X POST -H "Content-Type: application/json" "http://172.16.1.99:8080/alfresco/api/-default-/public/alfresco/versions/1/nodes/${sharedID}/children?alf_ticket=${ticket}" -d '{"name":"'"$dossier"'", "nodeType":"cm:folder"}')
    echo "$rep2" | grep "statusCode"

    # Envoie des donnees
    curl -s -X POST -H "Content-Type: multipart/form-data" -F "filedata"="@${postFiedls['fileName']}" -F "relativePath"="${postFiedls['registre']}" \
        -F "bc:numact"="${postFiedls['num_acte']}" -F "bc:firstname"="${postFiedls['nom']}" -F "bc:lastname"="${postFiedls['prenom']}" -F "bc:bornOnThe"="${postFiedls['dateNaiss']}" -F "bc:bornAt"="${postFiedls['lieuNaiss']}" -F "bc:sex"="${postFiedls['sexe']}" \
        -F "bc:of"="${postFiedls['nomsPere']}" -F "bc:fOnThe"="" -F "bc:fAt"="${postFiedls['lieuNaissPere']}" -F "bc:fresid"="${postFiedls['domicilePere']}" -F "bc:foccupation"="${postFiedls['professionPere']}" -F "bc:fnationality"="${postFiedls['nationalitePere']}" -F "bc:fdocref"="${postFiedls['docRefPere']}" \
        -F "bc:mof"="${postFiedls['nomsMere']}" -F "bc:mAt"="${postFiedls['lieuNaissMere']}" -F "bc:mOnThe"="" -F "bc:mresid"="${postFiedls['domicileMere']}" -F "bc:mOccupation"="${postFiedls['professionMere']}" -F "bc:mnationality"="${postFiedls['nationaliteMere']}" -F "bc:mdocref"="${postFiedls['docRefMere']}" \
        -F "bc:drawingUp"="${postFiedls['dresseLe']}" -F "bc:ondecof"="${postFiedls['qualDeclarant']}" -F "bc:byUs"="${postFiedls['officier']}" -F "bc:assistedof"="${postFiedls['secretaire']}" -F "bc:onthe"="${postFiedls['dateSignature']}" -F "bc:mentionMarg"="${postFiedls['mentionMarg']}" \
        "http://172.16.1.99:8080/alfresco/api/-default-/public/alfresco/versions/1/nodes/-shared-/children?alf_ticket=${ticket}"

    if [ $i -eq 1 ]; then break; fi
    i=$((i + 1))

done < <(grep -v "nomsenfant#prenomsenfant#datenaissenfant#lieunaissenfant#sexe#" "$csvFile")

# Suppression tableau
unset postFiedls
