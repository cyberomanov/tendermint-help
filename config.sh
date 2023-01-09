# config
COSMOS="gravity"
ID="11"
SNAPSHOT_INTERVAL=100
SNAPSHOT_KEEP_RECENT=2

# logic
sed -i.bak -e "\
s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:11${ID}0\"%; \
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:11${ID}1\"%; \
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:11${ID}2\"%; \
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:11${ID}3\"%; \
s%^external_address = \"\"%external_address = \"`echo $(hostname -I | awk '{print $1}'):11${ID}4`\"%; \
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":11${ID}5\"%" $HOME/.${COSMOS}/config/config.toml

sed -i.bak -e "s/^indexer *=.*/indexer = \"kv\"/" $HOME/.${COSMOS}/config/config.toml
# sed -i.bak -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.${COSMOS}/config/config.toml
sed -i.bak -e "s/^snapshot-interval *=.*/snapshot-interval = \"${SNAPSHOT_INTERVAL}\"/" $HOME/.${COSMOS}/config/app.toml
sed -i.bak -e "s/^snapshot-keep-recent *=.*/snapshot-keep-recent = \"${SNAPSHOT_KEEP_RECENT}\"/" $HOME/.${COSMOS}/config/app.toml

sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $HOME/.${COSMOS}/config/config.toml
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 100/g' $HOME/.${COSMOS}/config/config.toml
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 100/g' $HOME/.${COSMOS}/config/config.toml

sed -i.bak -e "\
s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:8${ID}5\"%; \
s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:8${ID}6\"%" $HOME/.${COSMOS}/config/app.toml

sed -i.bak -e "\
s%^pruning = \"default\"%pruning = \"custom\"%; \
s%^pruning-keep-recent = \"0\"%pruning-keep-recent = \"100\"%; \
s%^pruning-interval = \"0\"%pruning-interval = \"10\"%; \
s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:11${ID}6\"%; \
s%^address = \":8080\"%address = \":11${ID}7\"%; \
s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:11${ID}8\"%; \
s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:11${ID}9\"%" $HOME/.${COSMOS}/config/app.toml
