#!/bin/bash

# [ LastUpdate ]  : 27-09-2022
# [ Description ] :
# [ Author(s) ]   : Mr MANI / NANFACK STEVE

#csvfile=en4201_reprise_naissance.csv
csvFile=$1
#source fonctions.sh

# Recupere Nbre de Ligne
#nbrLign=$(grep -c "" "$csvFile")
#echo "$nbrLign"

# Recupere Nbre de Champ
# nbrColn=$(awk -F# '{print NF; exit;}' "$csvFile")
# echo "$nbrColn"

affichInfos() {
    echo -e "\nnom: $nom \nprenom: $prenom \nDateNaiss: $dateNaiss \nLieuNaiss: $lieuNaiss \nSexe: $sexe 
    \nNomsPere: $nomsPere \nDateNaiss: $dateNaissPere \nNe Vers: $neVersPere \nLieuNaiss: $lieuNaissPere \nDomicilie: $domicilePere \nProf: $professionPere \nNationalite: $nationalitePere \ndocRef: $docRefPere
    \nNomsMere: $nomsMere \nDateNaiss: $dateNaissMere \nNe Vers: $neVersMere \nLieuNaiss: $lieuNaissMere \nDomicilie: $domicileMere \nProf: $professionMere \nNationalite: $nationaliteMere \ndocRef: $docRefMere
    \nNomDeclarant: $nomDeclarant \nQual.Declar.: $qualDeclarant \nData Sign: $dateSignature \nDresse Le: $dresseLe \nOfficier: $officier \nSecretaire: $secretaire \nMention Marg: $mentionMarg
    \nNumero Acte: $num_acte \nRegistre: $registre \nNom PDF: $fileName \nChemin: $path"
}
i=1
while read -r ligne; do

    IFS="#" read -r -a datas <<<"$(echo "$ligne")"

    #-------- Extraction des Meta donnees -----------#

    # infos enfants
    nom="${datas[0]}"
    prenom="${datas[1]}"
    dateNaiss="${datas[2]}"
    lieuNaiss="${datas[3]}"
    sexe="${datas[4]}"

    #infos Pere enfant
    nomsPere="${datas[5]}"
    dateNaissPere="${datas[6]}"
    neVersPere="${datas[7]}"
    lieuNaissPere="${datas[25]}"
    domicilePere="${datas[8]}"
    professionPere="${datas[10]}"
    nationalitePere="${datas[9]}"
    docRefPere="${datas[24]}"

    #infos Mere enfant
    nomsMere="${datas[11]}"
    dateNaissMere="${datas[12]}"
    neVersMere="${datas[13]}"
    lieuNaissMere="${datas[14]}"
    domicileMere="${datas[15]}"
    professionMere="${datas[16]}"
    nationaliteMere="${datas[17]}"
    docRefMere="${datas[18]}"

    #infos Agents
    nomDeclarant="${datas[20]}"
    qualDeclarant="${datas[21]}"
    dateSignature="${datas[22]}"
    dresseLe="${datas[26]}"
    officier="${datas[27]}"
    secretaire="${datas[28]}"
    mentionMarg="${datas[29]}"

    #infos fichier
    num_acte="${datas[23]}"
    registre="${datas[30]}"
    fileName="${datas[31]}"
    path="${datas[32]}"

    #affichInfos
    #if [ $i -eq 1 ]; then break; fi;i=$((i + 1))

    #------- Connexion a Alfrsco --------------#

    curl -X POST http://172.16.1.99:8080/alfresco/api/-default-/public/authentication/versions/1/tickets -H "Content-Type: application/json" -d '{"userId": "admin", "password": "bunec"}'

done < <(grep -v "nomsenfant#prenomsenfant#datenaissenfant#lieunaissenfant#sexe#" "$csvFile")

#echo "-" "${#datas[@]}"
