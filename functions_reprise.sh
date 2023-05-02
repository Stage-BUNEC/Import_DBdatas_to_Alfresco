import_birth_certificate() {

    # Variables Auxiliaires
    file_nbr=0
    toDay=$(date -I)
    date=$(date '+%F_%X')
    alfr_send_log="$$_birth_certificate_send_$toDay.log"

    success_import_files="$HOME/imported"
    [[ ! -d "$success_import_files" ]] && mkdir -p "$success_import_files"

    echo -e "\n-----------------------------[ Importations des donnees des$red Naissaces$nc ]-----------------------------------\n"
    echo -e "$vlt[ INFOS ] : $nc@IP = $vlt${paramConn[0]} $nc| Port = $vlt${paramConn[1]} $nc| Dossier_Cible_Alfresco = $vlt${alfresco_target}$nc | type_dossier = $vlt$type_dir $nc\n"

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

            #-------- Gestion des logs -----------#

            # En-tete fichier
            if [ ! -e "$alfr_send_log" ]; then echo -e "Date\t   Time\t\t Alfr_dir\t\t  Register\t\t\t File_Name\t  \t\t\t\tState\tTotal \n" >"$alfr_send_log"; fi

            # status d'envoie
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

    # Variables Auxiliaires
    file_nbr=0
    toDay=$(date -I)
    date=$(date '+%F_%X')
    alfr_send_log="$$_wedding_certificate_send_$toDay.log"

    success_import_files="$HOME/imported"
    [[ ! -d "$success_import_files" ]] && mkdir -p "$success_import_files"

    echo -e "\n-----------------------------[ Importations des donnees des$red Mariages$nc ]-----------------------------------\n"
    echo -e "$vlt[ INFOS ] : $nc@IP = $vlt${paramConn[0]} $nc| Port = $vlt${paramConn[1]} $nc| Dossier_Cible_Alfresco = $vlt${alfresco_target}$nc | type_dossier = $vlt$type_dir $nc\n"

    while read -r ligne; do

        IFS="#" read -r -a datas <<<"$(echo "$ligne" | cat)"
        file_name=${datas[31]} # on recupere le nom du fichier

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

            # Infos Epoux
            postFiedls['nomEpx']="${datas[1]}"
            postFiedls['dateNaissEpx']="${datas[2]}"
            postFiedls['lieuNaissEpx']="${datas[3]}"
            postFiedls['nationaliteEpx']="${datas[4]}"
            postFiedls['professionEpx']="${datas[5]}"
            postFiedls['docRefEpx']="${datas[6]}"
            postFiedls['domicileEpx']="${datas[7]}"
            postFiedls['nomsPereEpx']="${datas[8]}"
            postFiedls['nomsMereEpx']="${datas[9]}"
            postFiedls['nomsChefEpx']="${datas[10]}"
            postFiedls['nomsTemoinEpx']="${datas[11]}"

            # Infos Epouse
            postFiedls['nomEpse']="${datas[12]}"
            postFiedls['dateNaissEpse']="${datas[13]}"
            postFiedls['lieuNaissEpse']="${datas[14]}"
            postFiedls['nationaliteEpse']="${datas[15]}"
            postFiedls['professionEpse']="${datas[16]}"
            postFiedls['docRefEpse']="${datas[17]}"
            postFiedls['domicileEpse']="${datas[18]}"
            postFiedls['nomsPereEpse']="${datas[19]}"
            postFiedls['nomsMereEpse']="${datas[20]}"
            postFiedls['nomsChefEpse']="${datas[21]}"
            postFiedls['nomsTemoinEpse']="${datas[22]}"

            # Infos Mariage
            postFiedls['regimMatrimonial']="${datas[23]}"
            postFiedls['regimDesBiens']="${datas[24]}"
            postFiedls['cecPrincipal']="${datas[25]}"
            postFiedls['lieuSignature']="${datas[25]}"
            postFiedls['dateMariage']="${datas[26]}"
            postFiedls['secretaire']="${datas[27]}"
            postFiedls['officier']="${datas[28]}"
            postFiedls['dateSignature']="${datas[29]}"

            # Infos SANS VALEUR
            postFiedls['docRefPeresEpx']=""
            postFiedls['is_valid']=""
            postFiedls['nipu_epouse']=""
            postFiedls['nipu_epoux']=""
            postFiedls['opposition']=""
            postFiedls['rattachement']=""
            postFiedls['vaidated_date']=""

            # Infos fichier
            postFiedls['num_acte']="${datas[0]}"
            postFiedls['fileName']="${datas[31]}"
            postFiedls['path']="${datas[32]}"

            # Affichage Meta Donnees
            for key in ${!postFiedls[*]}; do echo "$key --> ${postFiedls[$key]}"; done && exit

            if [ "$statusCode" = "401" ]; then

                # reconnexion
                reponse=$(curl -s -X POST "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/authentication/versions/1/tickets" -H "Content-Type: application/json" -d "{\"userId\": \"${paramConn[2]}\", \"password\": \"${paramConn[3]}\" }")
                ticket=$(echo "$reponse" | grep -E -o "TICKET_[a-zA-Z0-9]*")

                # creation registre
                rep2=$(curl -s -X POST -H "Content-Type: application/json" "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/alfresco/versions/1/nodes/${ID_dir_alfresco}/children?alf_ticket=${ticket}" -d '{"name":"'"${registre}"'", "nodeType":"cm:folder"}')
                statusCode=$(echo -e "$rep2" | grep -E -o "\"statusCode\":[0-9]*" | cut -d: -f2)
            fi

            # Envoie des donnees
            rep3=$(
                curl -s -X POST -H "Content-Type: multipart/form-data" -F "filedata"="@$path${postFiedls['fileName']}" -F "relativePath"="${registre}" \
                    -F "wd:numact"="${postFiedls['num_acte']}" -F "wd:fmr"="${postFiedls['nomEpx']}" -F "wd:fwedof"="${postFiedls['nomEpx']}" -F "wd:mr"="${postFiedls['nomEpx']}" -F "fOnThe"="${postFiedls['dateNaissEpx']}" -F "wd:fAt"="${postFiedls['lieuNaissEpx']}" -F "wd:fnationality"="${postFiedls['nationaliteEpx']}" -F "wd:fOccupation"="${postFiedls['professionEpx']}" -F "wd:fdocref"="${postFiedls['docRefEpx']}" -F "wd:fresid"="${postFiedls['domicileEpx']}" -F "wd:fsonof"="${postFiedls['nomsPereEpx']}" -F "wd:msonof"="${postFiedls['nomsMereEpx']}" -F "wd:InPresenceOf"="${postFiedls['nomsChefEpx']}" -F "wd:witnessf"="${postFiedls['nomsTemoinEpx']}" \
                    -F "wd:mlle"="${postFiedls['nomEpse']}" -F "wd:mwedof_1"="${postFiedls['nomEpse']}" -F "wd:mwedof"="${postFiedls['nomEpse']}" -F "wd:mOnThe"="${postFiedls['dateNaissEpse']}" -F "wd:mAt"="${postFiedls['lieuNaissEpse']}" -F "wd:mnationality"="${postFiedls['nationaliteEpse']}" -F "wd:mOccupation"="${postFiedls['professionEpse']}" -F "wd:mdocref"="${postFiedls['docRefEpse']}" -F "wd:mresid"="${postFiedls['domicileEpse']}" -F "wd:daugtherOf"="${postFiedls['nomsPereEpse']}" -F "wd:andDaugtherOf"="${postFiedls['nomsMereEpse']}" -F "wd:andInPresenceOf"="${postFiedls['nomsChefEpse']}" -F "wd:witnessm"="${postFiedls['nomsTemoinEpse']}" \
                    -F "wd:matrimSyst"="${postFiedls['regimMatrimonial']}" -F "wd:propRegister"="${postFiedls['regimDesBiens']}" -F "wd:nom_cec"="${postFiedls['cecPrincipal']}" -F "wd:placeSign"="${postFiedls['lieuSignature']}" -F "wd:celebdate"="${postFiedls['dateMariage']}" -F "wd:assistedBy"="${postFiedls['secretaire']}" -F "wd:stateRegistrar"="${postFiedls['officier']}" -F "wd:onThe"="${postFiedls['dateSignature']}" \
                    -F "wd:ffdocref" -F "wd:is_valid"="" -F "wd:nipu_epouse"="" -F "wd:nipu_epoux"="" -F "wd:opposition"="" -F "wd:rattachement"="" -F "wd:vaidated_date"="" \
                    "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/alfresco/versions/1/nodes/${ID_dir_alfresco}/children?alf_ticket=${ticket}"
            )

            #-------- Gestion des logs -----------#

            # En-tete fichier
            if [ ! -e "$alfr_send_log" ]; then echo -e "Date\t   Time\t\t Alfr_dir\t\t  Register\t\t\t File_Name\t  \t\t\t\tState\tTotal \n" >"$alfr_send_log"; fi

            # status d'envoie
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
    done < <(grep -v "num_acte#noms_epoux#" "$csvFile")
}

import_death_certificate() {

    # Variables Auxiliaires
    file_nbr=0
    toDay=$(date -I)
    date=$(date '+%F_%X')
    alfr_send_log="$$_death_certificate_send_$toDay.log"

    success_import_files="$HOME/imported"
    [[ ! -d "$success_import_files" ]] && mkdir -p "$success_import_files"

    echo -e "\n-----------------------------[ Importations des donnees des$red Deces$nc ]-----------------------------------\n"
    echo -e "$vlt[ INFOS ] : $nc@IP = $vlt${paramConn[0]} $nc| Port = $vlt${paramConn[1]} $nc| Dossier_Cible_Alfresco = $vlt${alfresco_target}$nc | type_dossier = $vlt$type_dir $nc\n"

    while read -r ligne; do

        IFS="#" read -r -a datas <<<"$(echo "$ligne" | cat)"
        file_name=${datas[28]} # on recupere le nom du fichier

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

            # Infos Defunt
            postFiedls['noms']="${datas[1]}"
            postFiedls['prenoms']="${datas[2]}"
            postFiedls['dateNaiss']="${datas[3]}"
            postFiedls['dateDeces']="${datas[4]}"
            postFiedls['lieuDeces']="${datas[5]}"
            postFiedls['lieuNaiss']="${datas[6]}"
            postFiedls['sexe']="${datas[7]}"
            postFiedls['situationMatrim']="${datas[8]}"
            postFiedls['profession']="${datas[9]}"
            postFiedls['domicile']="${datas[10]}"
            postFiedls['nomsPere']="${datas[11]}"
            postFiedls['nomsMere']="${datas[12]}"
            postFiedls['nomFosa']="${datas[13]}"

            # Infos Declarant
            postFiedls['nomsD']="${datas[14]}"
            postFiedls['professionD']="${datas[15]}"
            postFiedls['qualiteStatutD']="${datas[16]}"

            # Infos Temoins
            postFiedls['nomsTemoinUn']="${datas[17]}"
            postFiedls['professionTemoinUn']="${datas[18]}"
            postFiedls['domicileTemoinUn']="${datas[19]}"
            postFiedls['nomsTemoinDeux']="${datas[20]}"
            postFiedls['professionTemoinDeux']="${datas[21]}"
            postFiedls['domicileTemoinDeux']="${datas[22]}"

            # Infos FOSA
            postFiedls['officier']="${datas[23]}"
            postFiedls['secretaire']="${datas[24]}"
            postFiedls['dateSignature']="${datas[25]}"
            postFiedls['dateVers']="${datas[26]}"

            # Infos SANS VALEUR
            postFiedls['decryptedkey']=""
            postFiedls['drawingUp']=""
            postFiedls['encryptedmessage']=""
            postFiedls['is_valid']=""
            postFiedls['NIPU']=""
            postFiedls['nom_cec']=""
            postFiedls['originalmessage']=""
            postFiedls['rattachement']=""
            postFiedls['vaidated_date']=""

            # Infos fichier
            postFiedls['num_acte']="${datas[0]}"
            postFiedls['fileName']="${datas[28]}"
            postFiedls['path']="${datas[29]}"

            # Affichage Meta Donnees
            for key in ${!postFiedls[*]}; do echo "$key --> ${postFiedls[$key]}"; done && exit

            if [ "$statusCode" = "401" ]; then

                # reconnexion
                reponse=$(curl -s -X POST "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/authentication/versions/1/tickets" -H "Content-Type: application/json" -d "{\"userId\": \"${paramConn[2]}\", \"password\": \"${paramConn[3]}\" }")
                ticket=$(echo "$reponse" | grep -E -o "TICKET_[a-zA-Z0-9]*")

                # creation registre
                rep2=$(curl -s -X POST -H "Content-Type: application/json" "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/alfresco/versions/1/nodes/${ID_dir_alfresco}/children?alf_ticket=${ticket}" -d '{"name":"'"${registre}"'", "nodeType":"cm:folder"}')
                statusCode=$(echo -e "$rep2" | grep -E -o "\"statusCode\":[0-9]*" | cut -d: -f2)
            fi

            # Envoie des donnees
            rep3=$(
                curl -s -X POST -H "Content-Type: multipart/form-data" -F "filedata"="@$path${postFiedls['fileName']}" -F "relativePath"="${registre}" \
                    -F "dt:numAct"="${postFiedls['num_acte']}" -F "dt:firstName"="${postFiedls['noms']}" -F "dt:lastName"="${postFiedls['prenoms']}" -F "dt:bornOnThe"="${postFiedls['dateNaiss']}" -F "dt:bornOntThe"="${postFiedls['dateNaiss']}" -F "dt:dieOnThe"="${postFiedls['dateDeces']}" -F "dt:dieAt"="${postFiedls['lieuDeces']}" -F "dt:bornAt"="${postFiedls['lieuNaiss']}" -F "dt:sex"="${postFiedls['sexe']}" -F "dt:matrimSyst"="${postFiedls['situationMatrim']}" -F "dt:occupation"="${postFiedls['profession']}" -F "dt:resid"="${postFiedls['domicile']}" \
                    -F "dt:sonof"="${postFiedls['nomsPere']}" -F "dt:andsonof"="${postFiedls['nomsMere']}" -F "dt:inAccordancewith"="${postFiedls['nomFosa']}" -F "dt:nameofD"="${postFiedls['nomsD']}" -F "dt:occupationD"="${postFiedls['professionD']}" -F "dt:role"="${postFiedls['qualiteStatutD']}" -F "dt:fwitness"="${postFiedls['nomsTemoinUn']}" -F "dt:foccupation"="${postFiedls['professionTemoinUn']}" -F "dt:fresid"="${postFiedls['domicileTemoinUn']}" -F "dt:switness"="${postFiedls['nomsTemoinDeux']}" -F "dt:soccupation"="${postFiedls['professionTemoinDeux']}" -F "dt:sresid"="${postFiedls['domicileTemoinDeux']}" \
                    -F "dt:byUs"="${postFiedls['officier']}" -F "dt:assitedof"="${postFiedls['secretaire']}" -F "dt:onThe"="${postFiedls['dateSignature']}" -F "dt:datevers"="${postFiedls['dateVers']}" -F "dt:decryptedkey"="" -F "dt:drawingUp"="" -F "dt:encryptedmessage"="" -F "dt:is_valid"="" -F "dt:NIPU"="" -F "dt:nom_cec"="" -F "dt:originalmessage"="" -F "dt:rattachement"="" -F "dt:vaidated_date"="" \
                    "http://${paramConn[0]}:${paramConn[1]}/alfresco/api/-default-/public/alfresco/versions/1/nodes/${ID_dir_alfresco}/children?alf_ticket=${ticket}"
            )

            #-------- Gestion des logs -----------#

            # En-tete fichier
            if [ ! -e "$alfr_send_log" ]; then echo -e "Date\t   Time\t\t Alfr_dir\t\t  Register\t\t\t File_Name\t  \t\t\t\tState\tTotal \n" >"$alfr_send_log"; fi

            # status d'envoie
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
    done < <(grep -v "num_acte#noms_prenoms_decede#" "$csvFile")
}
