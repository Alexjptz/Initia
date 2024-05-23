echo "ENTER YOUR NODE NAME (MONIKER)"
read -r -p "Node name: " NODE_MONIKER
echo ""
echo "GET THE LAST SNAP NUMER ---> https://polkachu.com/testnets/initia/snapshots"
read -r -p "Enter snap number: " SNAP_INITIA

CHAIN_ID="initiation-1"
CHAIN_DENOM="initiad"
BINARY_NAME="initiad"
TELEGRAM="https://t.me/aigolenev"
BINARY_VERSION_TAG="v0.2.15"

echo -e "Node moniker: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag:  ${CYAN}$BINARY_VERSION_TAG${NC}"

sleep 1

echo -e "\e[1m\e[32m1. Updating packages and dependencies--> \e[0m" && sleep 1

# UPDATE SYS APT
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev libleveldb-dev jq build-essential bsdmainutils git make ncdu htop lz4 screen unzip bc fail2ban htop -y

echo -e "\e[1m\e[32m1. Install go--> \e[0m" && sleep 1

https://go.dev/dl/go1.22.3.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz



echo -e "\e[1m\e[32m1. Pulling initia and install--> \e[0m" && sleep 1

# pulling the repo initia
git clone https://github.com/initia-labs/initia.git
cd initia
git checkout v0.2.15
make install

echo -e "\e[1m\e[32m1. Initiatioon and set moniker--> \e[0m" && sleep 1

# initiation and set moniker
initiad init "$NODE_MONIKER" --chain-id initiation-1

echo -e "\e[1m\e[32m1. Pulling addrbook and genesis--> \e[0m" && sleep 1

# pulling addrbook and genesis
wget https://initia.s3.ap-southeast-1.amazonaws.com/initiation-1/addrbook.json -O ~/.initia/config/addrbook.json
wget https://initia.s3.ap-southeast-1.amazonaws.com/initiation-1/genesis.json -O ~/.initia/config/genesis.json

sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@initia-testnet.rpc.kjnodes.com:17959\"|" $HOME/.initia/config/config.toml
PEERS="aee7083ab11910ba3f1b8126d1b3728f13f54943@initia-testnet-peer.itrocket.net:11656,2bfad62fa5ba7cc91af4e19ee8d1356997a01079@84.247.166.24:51656,e6a35b95ec73e511ef352085cb300e257536e075@37.252.186.213:26656,07632ab562028c3394ee8e78823069bfc8de7b4c@37.27.52.25:19656,b4778656f255169b8b1d660b6af3a0df68d68e65@176.57.189.36:15656,54d2302155d1bd2a95354ea1d54e196db70a5361@84.46.251.215:656,767fdcfdb0998209834b929c59a2b57d474cc496@207.148.114.112:26656,093e1b89a498b6a8760ad2188fbda30a05e4f300@35.240.207.217:26656,5f934bd7a9d60919ee67968d72405573b7b14ed0@65.21.202.124:29656,e15f6e83d7e35c12f99476674137f3edd1865654@161.97.143.182:16656"
sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.initia/config/config.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.initia/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.15uinit,0.01uusdc"|g' $HOME/.initia/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.initia/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.initia/config/config.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.initia/config/config.toml

sudo tee /etc/systemd/system/initiad.service > /dev/null <<EOF
[Unit]
Description=Initia node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.initia
ExecStart=$(which initiad) start --home $HOME/.initia
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable initiad.service

# get a fresh snap and unpack
curl https://snapshots.polkachu.com/testnet-snapshots/initia/initia_$SNAP_INITIA.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.initia

sudo systemctl start initiad

echo '=============== SETUP FINISHED ==================='
echo -e "Check logs:            ${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}"
echo -e "Check synchronization: ${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}"
echo -e "Questions:             ${CYAN}$TELEGRAM${NC}"
echo -e "Start Initia:          ${CYAN}systemctl start initiad${NC}"
echo -e "Stop Initia:           ${CYAN}systemctl stop initiad${NC}"
echo -e "Restart Initia:        ${CYAN}systemctl restart initiad${NC}"
