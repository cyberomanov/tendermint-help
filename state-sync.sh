# config
SERVICE="rizond"
COSMOS="rizond"
CONFIG="/root/.rizon/config/"
HOME_DIR="/root/.rizon/"
SNAP_RPC="http://rpc:port"
PRUNING=100

# logic
LATEST_HEIGHT=$(curl -s ${SNAP_RPC}/block | jq -r ".result.block.header.height") && \
BLOCK_HEIGHT=$((LATEST_HEIGHT - PRUNING)) && \
TRUST_HASH=$(curl -s "${SNAP_RPC}/block?height=${BLOCK_HEIGHT}" | jq -r ".result.block_id.hash") && \
RPC_RESULT=$(echo ${LATEST_HEIGHT} ${BLOCK_HEIGHT} ${TRUST_HASH} | grep "[0-9]* [0-9]* [A-Z0-9]*")

if [[ ${RPC_RESULT} != "" ]]; then
    clear && \
    echo "INFO: RPC is OK." && \

    sudo systemctl stop ${SERVICE} && \
    echo "INFO: service '${SERVICE}' has been stopped." && \

    ${COSMOS} unsafe-reset-all --home ${HOME_DIR} --keep-addr-book > /dev/null 2>&1; \
    ${COSMOS} tendermint unsafe-reset-all --home ${HOME_DIR} --keep-addr-book > /dev/null 2>&1; \
    echo "INFO: unsafe-reset-all has been done." && \

    sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
    s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
    s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
    s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
    s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" ${CONFIG}/config.toml  && \
    echo "INFO: config has been edited." && \

    sudo systemctl restart ${SERVICE} && \
    echo "INFO: service has been restarted. input any value to open logs: " && \
    read foo && \

    journalctl -fu ${SERVICE} -o cat
else
    clear && \
    echo -e "\nERROR: RPC is NOT OK.\n"
fi
