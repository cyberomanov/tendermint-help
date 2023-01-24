#!/bin/bash

# editable
BIN=lavad
SERVICE="lavad"
CONFIG="/root/.lava/config/"
NEW_BIN="/root/lava/build/lavad"
UPGRADE_HEIGHT=41735  # leave 0, if there is an upgrade proposal. if it's an emergency upgrade, set an updrage height.

# non-editable
NODE=$(cat ${CONFIG}/config.toml | grep -oPm1 "(?<=^laddr = \")([^%]+)(?=\")")
NODE_HOME=$(echo ${CONFIG} | rev | cut -c 8- | rev)
PORT=$(echo ${NODE} | awk 'NR==1 {print; exit}' | grep -o ":[0-9]*" | awk 'NR==2 {print; exit}' | cut -c 2-)

if [[ $(which ${BIN} 2>&1) != "" ]]; then
    if systemctl --all --type service | grep -q "${SERVICE}"; then
        if [ -d ${CONFIG} ]; then
            NEW_BIN_VER=$(${NEW_BIN} version 2>&1)
            if [[ ${NEW_BIN_VER} != *"command not found"* && ${NEW_BIN_VER} != *"file or directory"* ]]; then
                if [[ ${UPGRADE_HEIGHT} == 0 ]]; then
                    echo -e "\nupgrade height is not found, looking for the upgrade proposal.\n"
                    KEY=0
                    while [[ ${KEY} == 0 ]]; do
                        UPGRADE_PLAN=$(${BIN} q upgrade plan --node ${NODE} --output json 2>&1)
                        if [[ ${UPGRADE_PLAN} != *"no upgrade scheduled"* ]]; then
                            UPGRADE_HEIGHT=$(echo ${UPGRADE_PLAN} | jq ".height" | tr -d '"')
                            KEY=1
                        else
                            echo "upgrade schedule does not exist yet. sleeping."
                            sleep 5
                        fi
                    done
                else
                    echo -e "\nupgrade height is hard-coded and equals ${UPGRADE_HEIGHT}.\n"
                fi

                SUCCESS=0
                while [[ $SUCCESS == 0 ]]; do
                    NODE_STATUS=$(timeout 5s ${BIN} status 2>&1 --node ${NODE} --home ${NODE_HOME})
                    LATEST_NODE_BLOCK=$(echo ${NODE_STATUS} | jq .'SyncInfo'.'latest_block_height' | tr -d '"')
                    if [[ $(echo "${LATEST_NODE_BLOCK} == ${UPGRADE_HEIGHT}" | bc) -eq 1 ]]; then
                        if [ -e ${NEW_BIN} ]; then
                            sudo mv ${NEW_BIN} $(which ${BIN})
                            sudo systemctl restart ${SERVICE}
                            echo -e "\nsuccessfuly move and service restart.\n"
                            sleep 30
                        else
                            echo -e "\nfile \"${NEW_BIN}\" does not exist. seems like the upgrade has been already done.\n"
                        fi
                        SUCCESS=1
                    elif [[ $(echo "${LATEST_NODE_BLOCK} > ${UPGRADE_HEIGHT}" | bc) -eq 1 ]]; then echo -e "\nchain is alive.\n"; SUCCESS=2;
                    else echo "block: ${LATEST_NODE_BLOCK}, waiting for ${UPGRADE_HEIGHT}."; sleep 5
                    fi
                done

                if [[ ${SUCCESS} != 2 ]]; then
                    echo -e "looking for the consensus.\n"
                    CONSENSUS=0

                    while [[ $CONSENSUS == 0 ]]; do
                        PERC=$(curl -s localhost:${PORT}/consensus_state | jq '.result.round_state.height_vote_set[0].prevotes_bit_array' | grep -oE [0-9].[0-9]* | tail -1)
                        if (( $(echo "${PERC} < 0.67" | bc) )); then
                            if   (( $(echo "${PERC} >= 0.00" | bc) && $(echo "${PERC} < 0.05" | bc) )); then echo -ne "${PERC} - [ ##                         ] - 0.67 \r";
                            elif (( $(echo "${PERC} >= 0.05" | bc) && $(echo "${PERC} < 0.1"  | bc) )); then echo -ne "${PERC} - [ ####                       ] - 0.67 \r";
                            elif (( $(echo "${PERC} >= 0.1"  | bc) && $(echo "${PERC} < 0.15" | bc) )); then echo -ne "${PERC} - [ ######                     ] - 0.67 \r";
                            elif (( $(echo "${PERC} >= 0.15" | bc) && $(echo "${PERC} < 0.2"  | bc) )); then echo -ne "${PERC} - [ ########                   ] - 0.67 \r";
                            elif (( $(echo "${PERC} >= 0.2"  | bc) && $(echo "${PERC} < 0.25" | bc) )); then echo -ne "${PERC} - [ ##########                 ] - 0.67 \r";
                            elif (( $(echo "${PERC} >= 0.25" | bc) && $(echo "${PERC} < 0.3"  | bc) )); then echo -ne "${PERC} - [ ############               ] - 0.67 \r";
                            elif (( $(echo "${PERC} >= 0.3"  | bc) && $(echo "${PERC} < 0.35" | bc) )); then echo -ne "${PERC} - [ ##############             ] - 0.67 \r";
                            elif (( $(echo "${PERC} >= 0.35" | bc) && $(echo "${PERC} < 0.4"  | bc) )); then echo -ne "${PERC} - [ ################           ] - 0.67 \r";
                            elif (( $(echo "${PERC} >= 0.4"  | bc) && $(echo "${PERC} < 0.45" | bc) )); then echo -ne "${PERC} - [ ##################         ] - 0.67 \r";
                            elif (( $(echo "${PERC} >= 0.45" | bc) && $(echo "${PERC} < 0.5"  | bc) )); then echo -ne "${PERC} - [ ####################       ] - 0.67 \r";
                            elif (( $(echo "${PERC} >= 0.5"  | bc) && $(echo "${PERC} < 0.55" | bc) )); then echo -ne "${PERC} - [ ######################     ] - 0.67 \r";
                            elif (( $(echo "${PERC} >= 0.55" | bc) && $(echo "${PERC} < 0.6"  | bc) )); then echo -ne "${PERC} - [ ########################   ] - 0.67 \r";
                            elif (( $(echo "${PERC} >= 0.6"  | bc) && $(echo "${PERC} < 0.67" | bc) )); then echo -ne "${PERC} - [ ########################## ] - 0.67 \r"; fi
                            sleep 5
                        else
                            CONSENSUS=1
                            echo -ne "0.67 - [ ########################## ] ${PERC}\r"
                            echo -ne '\n'
                        fi
                    done

                    echo -e "\nsuccessful update without f*cking cosmovisor!\n"
                fi
            else
                echo -e "\nfile \"${NEW_BIN}\" does not exist.\n"
            fi
        else
            echo -e "\nconfig '${CONFIG}' does not exist.\n"
        fi
    else
        echo -e "\nservice '${SERVICE}.service' does not exist.\n"
    fi
else
    echo -e "\nbin '${BIN}' does not exist.\n"
fi
