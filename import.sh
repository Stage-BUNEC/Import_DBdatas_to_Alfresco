#!/bin/bash

# [ LastUpdate ]  : 29-09-2022
# [ Description ] : Script d'envoie des donnees dans Alfresco
# [ Author(s) ]   : Mr MANI / NANFACK STEVE

#csvfile=en4201_reprise_naissance.csv
csvFile=$1

# Recupere Nbre de Ligne
#nbrLign=$(grep -c "" "$csvFile")

# Recupere Nbre de Champ
# nbrColn=$(awk -F# '{print NF; exit;}' "$csvFile")

# creation Tablau Associatif
declare -A postFiedls=()

i=1
while read -r ligne; do

    IFS="#" read -r -a datas <<<"$(echo "$ligne" | cat)"

    #-------- Extraction des Meta donnees -----------#

    # infos enfants
    postFiedls['nom']="${datas[0]}"
    postFiedls['prenom']="${datas[1]}"
    postFiedls['dateNaiss']="${datas[2]}"
    postFiedls['lieuNaiss']="${datas[3]}"
    postFiedls['sexe']="${datas[4]}"

    #infos Pere enfant
    postFiedls['nomsPere']="${datas[5]}"
    postFiedls['dateNaissPere']="${datas[6]}"
    postFiedls['neVersPere']="${datas[7]}"
    postFiedls['lieuNaissPere']="${datas[25]}"
    postFiedls['domicilePere']="${datas[8]}"
    postFiedls['professionPere']="${datas[10]}"
    postFiedls['nationalitePere']="${datas[9]}"
    postFiedls['docRefPere']="${datas[24]}"

    #infos Mere enfant
    postFiedls['nomsMere']="${datas[11]}"
    postFiedls['dateNaissMere']="${datas[12]}"
    postFiedls['neVersMere']="${datas[13]}"
    postFiedls['lieuNaissMere']="${datas[14]}"
    postFiedls['domicileMere']="${datas[15]}"
    postFiedls['professionMere']="${datas[16]}"
    postFiedls['nationaliteMere']="${datas[17]}"
    postFiedls['docRefMere']="${datas[18]}"

    #infos Agents
    postFiedls['nomDeclarant']="${datas[20]}"
    postFiedls['qualDeclarant']="${datas[21]}"
    postFiedls['dateSignature']="${datas[22]}"
    postFiedls['dresseLe']="${datas[26]}"
    postFiedls['officier']="${datas[27]}"
    postFiedls['secretaire']="${datas[28]}"
    postFiedls['mentionMarg']="${datas[29]}"

    #infos fichier
    postFiedls['num_acte']="${datas[23]}"
    postFiedls['registre']="${datas[30]}"
    postFiedls['fileName']="${datas[31]}"
    postFiedls['path']="${datas[32]}"

    #for key in ${!postFiedls[*]}; do echo "$key --> ${postFiedls[$key]}"; done

    #------- Connexion a Alfrsco --------------#

    # recupere ticket
    reponse=$(curl -s -X POST http://172.16.1.99:8080/alfresco/api/-default-/public/authentication/versions/1/tickets -H "Content-Type: application/json" -d '{"userId": "admin", "password": "bunec"}')
    ticket=$(echo "$reponse" | cut -d'"' -f6)

    # recupere l'ID du dossier Partage/Shared
    rep=$(curl -s -X GET "http://172.16.1.99:8080/alfresco/api/-default-/public/alfresco/versions/1/nodes/-root-/children?alf_ticket=${ticket}")
    sharedID=$(echo "$rep" | cut -d'"' -f258)

    # creation noeud/Dossier dans Partage/Shared
    dossier=${postFiedls['registre']}
    rep2=$(curl -s -X POST -H "Content-Type: application/json" "http://172.16.1.99:8080/alfresco/api/-default-/public/alfresco/versions/1/nodes/${sharedID}/children?alf_ticket=${ticket}" -d '{"name":"'"$dossier"'", "nodeType":"cm:folder"}')

    # Envoie des donnees
    ## CODE A ECRIRE

    if [ $i -eq 1 ]; then break; fi
    i=$((i + 1))

done < <(grep -v "nomsenfant#prenomsenfant#datenaissenfant#lieunaissenfant#sexe#" "$csvFile")
