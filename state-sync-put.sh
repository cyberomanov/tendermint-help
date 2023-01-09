# config
SERVICE="quicksilverd"
COSMOS="quicksilverd"
CONFIG="/root/.quicksilverd/config/"

# logic
clear && \
CHANGED_ANY="false" && \
RPC_IP=$(cat ${CONFIG}/config.toml | grep -m 1 'laddr = "tcp://"*' | grep -oe "[0-9].[0-9].[0-9].[0-9]") && \
RPC_PORT=$(cat ${CONFIG}/config.toml | grep -oPm2 "(?<=^laddr = \")([^%]+)(?=\")" | awk 'NR==1 {print; exit}' | grep -o ":[0-9]*" | cut -c 2- | grep -o [0-9]*) && \

if [[ ${RPC_IP} != "0.0.0.0" ]]; then
    echo "WARN: RPC is closed."
    sed -i.bak -e "/\[rpc\]/,/\[p2p\]/s|\<laddr\> =.*|laddr = \"tcp://0.0.0.0:$RPC_PORT\"|;" ${CONFIG}/config.toml
    echo "INFO: RPC is opened now."
    CHANGED_ANY="true"
else
    echo "INFO: RPC is opened."
fi && \

SNAPSHOT_INTERVAL=$(cat ${CONFIG}/app.toml | grep "snapshot-interval =" | grep -o "[0-9]*")
if [[ ${SNAPSHOT_INTERVAL} == 0 ]]; then
    echo "WARN: snapshot_interval is not set."
    sed -i.bak -e  "s/^snapshot-interval *=.*/snapshot-interval = \"100\"/" ${CONFIG}/app.toml
    echo "INFO: snapshot_interval is 100 now."
    CHANGED_ANY="true"
else
    echo -e "INFO: snapshot_interval is ${SNAPSHOT_INTERVAL}."
fi && \

SNAPSHOT_KEEP_RECENT=$(cat ${CONFIG}/app.toml | grep "snapshot-keep-recent =" | grep -o "[0-9]*")
if [[ ${SNAPSHOT_KEEP_RECENT} == 0 ]]; then
    echo "WARN: snapshot-keep-recent is not set."
    sed -i.bak -e  "s/^snapshot-keep-recent *=.*/snapshot-keep-recent = \"2\"/" ${CONFIG}/app.toml
    echo "INFO: snapshot-keep-recent is 2 now."
    CHANGED_ANY="true"
else
    echo -e "INFO: snapshot-keep-recent is ${SNAPSHOT_KEEP_RECENT}."
fi && \

if [[ ${CHANGED_ANY} == "true" ]]; then
    echo "INFO: config has been edited." && \
    sudo systemctl restart ${SERVICE} && \
    echo "INFO: service has been restarted."
else
    echo "INFO: config has not been edited."
fi && \

ID=""
while [[ ${ID} == "" ]]; do
    sleep 2
    NODE_INFO=$(curl -s localhost:${RPC_PORT}/status | jq ".result.node_info")
    ID=$(echo ${NODE_INFO} | jq -r ".id")
    PEER_PORT=$(cat ${CONFIG}/config.toml | grep -oPm2 "(?<=^laddr = \")([^%]+)(?=\")" | awk 'NR==2 {print; exit}' | grep -o ":[0-9]*" | awk 'NR==2 {print; exit}' | cut -c 2-)
done && \

echo -e "\nINFO: peer >>>>>>>>>> ${ID}@$(hostname -I | awk '{print $1}'):${PEER_PORT}"
echo -e "INFO: rpc_address >>> $(hostname -I | awk '{print $1}'):${RPC_PORT}\n"

# sudo systemctl stop ${SERVICE} && sudo systemctl disable ${SERVICE} && sudo journalctl -fu ${SERVICE} -o cat
