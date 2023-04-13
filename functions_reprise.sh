import_birth_certificate() {

    # Variables Auxiliaires
    file_nbr=0
    toDay=$(date -I)
    date=$(date '+%F_%X')
    alfr_send_log="$$_birth_certificate_send_$toDay.log"
    success_import_files="/home/sun/Documents/imported"

    echo -e "\n------------------[ Importations des donnees des$red Naissaces$nc ]---------------------\n"
    echo -e "$vlt[ INFOS ] : $nc@IP = $vlt${paramConn[0]} $nc| Port = $vlt${paramConn[1]} $nc| Dossier_Cible_Alfresco = $vlt${alfresco_target}$nc \n"

    while read -r ligne; do

        IFS="#" read -r -a datas <<<"$(echo "$ligne" | cat)"
        file_name=${datas[30]} # on recupere le nom du fichier

        # on recupere le status. (vide = non-trouve | non-vide = trouve = fichier existe)
        find_status=$(find "$full_path" -name "$file_name")

        if [ -n "$find_status" ]; then

            #-------- Extraction des Meta donnees -----------#
            if [ "$type_dir" = "ID" ]; then
                temp="${find_status%/*pdf}"
                registre="${temp#$full_path}"
                path="$full_path${registre}/"

            elif [ "$type_dir" = "register" ]; then
                registre="$end_path_dir"
                path="$full_path"
            fi

            # Creation Tablau Associatif
            declare -A postFiedls=()

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
            postFiedls['lieuNaissPere']="${datas[24]}"
            postFiedls['domicilePere']="${datas[8]}"
            postFiedls['professionPere']="${datas[10]}"
            postFiedls['nationalitePere']="${datas[9]}"
            postFiedls['docRefPere']="${datas[23]}"

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
            postFiedls['nomDeclarant']="${datas[19]}"
            postFiedls['qualDeclarant']="${datas[20]}"
            postFiedls['dateSignature']="${datas[21]}"
            postFiedls['dresseLe']="${datas[25]}"
            postFiedls['officier']="${datas[26]}"
            postFiedls['secretaire']="${datas[27]}"
            postFiedls['mentionMarg']="${datas[28]}"

            # Infos fichier
            postFiedls['num_acte']="${datas[22]}"
            #postFiedls['registre']="${datas[29]}"
            postFiedls['fileName']="${datas[30]}"
            postFiedls['path']="${datas[31]}"

            # Affichage Meta Donnees
            #for key in ${!postFiedls[*]}; do echo "$key --> ${postFiedls[$key]}"; done

            # Creation Dossier/Registre
            rep2=$(curl -s -X POST -H "Content-Type: application/json" "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/alfresco/versions/1/nodes/${ID_dir_alfresco}/children?alf_ticket=${ticket}" -d '{"name":"'"${registre}"'", "nodeType":"cm:folder"}')
            statusCode=$(echo -e "$rep2" | grep -E -o "\"statusCode\":[0-9]*" | cut -d: -f2)

            if [ "$statusCode" = "401" ]; then

                # reconnexion
                reponse=$(curl -s -X POST "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/authentication/versions/1/tickets" -H "Content-Type: application/json" -d "{\"userId\": \"${paramConn[2]}\", \"password\": \"${paramConn[3]}\" }")
                ticket=$(echo "$reponse" | grep -E -o "TICKET_[a-zA-Z0-9]*")

                # creation registre
                rep2=$(curl -s -X POST -H "Content-Type: application/json" "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/alfresco/versions/1/nodes/${ID_dir_alfresco}/children?alf_ticket=${ticket}" -d '{"name":"'"${registre}"'", "nodeType":"cm:folder"}')
                statusCode=$(echo -e "$rep2" | grep -E -o "\"statusCode\":[0-9]*" | cut -d: -f2)
            fi

            # Envoie des donnees
            rep3=$(curl -s -X POST -H "Content-Type: multipart/form-data" -F "filedata"="@$path${postFiedls['fileName']}" -F "relativePath"="${registre}" \
                -F "bc:numact"="${postFiedls['num_acte']}" -F "bc:firstname"="${postFiedls['nom']}" -F "bc:lastname"="${postFiedls['prenom']}" -F "bc:bornOnThe"="${postFiedls['dateNaiss']}" -F "bc:bornAt"="${postFiedls['lieuNaiss']}" -F "bc:sex"="${postFiedls['sexe']}" \
                -F "bc:of"="${postFiedls['nomsPere']}" -F "bc:fOnThe"="" -F "bc:fAt"="${postFiedls['lieuNaissPere']}" -F "bc:fresid"="${postFiedls['domicilePere']}" -F "bc:foccupation"="${postFiedls['professionPere']}" -F "bc:fnationality"="${postFiedls['nationalitePere']}" -F "bc:fdocref"="${postFiedls['docRefPere']}" \
                -F "bc:mof"="${postFiedls['nomsMere']}" -F "bc:mAt"="${postFiedls['lieuNaissMere']}" -F "bc:mOnThe"="" -F "bc:mresid"="${postFiedls['domicileMere']}" -F "bc:mOccupation"="${postFiedls['professionMere']}" -F "bc:mnationality"="${postFiedls['nationaliteMere']}" -F "bc:mdocref"="${postFiedls['docRefMere']}" \
                -F "bc:drawingUp"="${postFiedls['dresseLe']}" -F "bc:ondecof"="${postFiedls['qualDeclarant']}" -F "bc:byUs"="${postFiedls['officier']}" -F "bc:assistedof"="${postFiedls['secretaire']}" -F "bc:onthe"="${postFiedls['dateSignature']}" -F "bc:mentionMarg"="${postFiedls['mentionMarg']}" \
                "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/alfresco/versions/1/nodes/${ID_dir_alfresco}/children?alf_ticket=${ticket}")

            # Gestion des logs
            if [ ! -e "$alfr_send_log" ]; then echo -e "Date\t   Time\t\t Alfr_dir\t\t  Register\t\t\t File_Name\t  \t\t\t\tState\tTotal \n" >"$alfr_send_log"; fi
            etat=$(echo -e "$rep3" | grep -E -o "\"statusCode\":[0-9]*" | cut -d: -f2)
            [[ $etat = "" ]] && etat="sent" || etat="exist"

            if [ etat="sent" ] || [ etat="exist" ]; then

                sed -i "2i $(echo -e "$(date +'%F %X')  ${alfresco_target}\t\t  ${registre}\t ${postFiedls['fileName']}\t\t$etat \t_")" "$alfr_send_log"
                file_nbr=$((file_nbr + 1))
                echo -e "file: ${postFiedls['fileName']}\t |  state:$grn $etat $nc\t | trated:$blu $file_nbr $nc"

                # deplacement de fichiers
                [[ ! -d "$success_import_files/${registre}" ]] && mkdir -p "$success_import_files/${registre}"
                mv "$path${postFiedls['fileName']}" "$success_import_files/${registre}"

            else

                etat="fail"
                sed -i "2i $(echo -e "$(date +'%F %X')  ${alfresco_target}\t\t  ${registre}\t ${postFiedls['fileName']}\t\t$etat \t_")" "$alfr_send_log"
                echo -e "file: ${postFiedls['fileName']}\t |  state:$red $etat $nc\t | trated:$ylw $file_nbr $nc"
            fi

        fi

    done < <(grep -v "nomsenfant#prenomsenfant#datenaissenfant#lieunaissenfant#sexe#" "$csvFile")

    # Infos Import
    sed -i "2i $(echo -e "$(date +'%F %X')  ${alfresco_target}\t\t\  _\t\t\t\t\t _\t\t\t\t\t\t$etat \t$file_nbr")" "$alfr_send_log"

    # Suppression tableau
    echo -e "\nFin Importation\n"
    unset postFiedls
}

import_weeding_certificate() {
    echo "mariage"
}

import_death_certificate() {
    echo "deces"
}
