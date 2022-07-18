#!/bin/bash
echo "=================================================="
echo -e "\033[0;35m"
echo " d8b   db  .d88b.  d8888b. d88888b db   dD db    db
echo " 888o  88 .8P  Y8. 88  `8D 88'     88 ,8P' 88    88
echo " 88V8o 88 88    88 88   88 88ooooo 88,8P   88    88
echo " 88 V8o88 88    88 88   88 88~~~~~ 88`8b   88    88
echo " 88  V888 `8b  d8' 88  .8D 88.     88 `88. 88b  d88
echo " VP   V8P  `Y88P'  Y8888D' Y88888P YP   YD ~Y8888P'
echo -e "\e[0m"
echo "=================================================="

# Menu

PS3='Select an action: '
options=(
"Install Node"
"Check Log"
"Check balance"
"Request tokens in discord"
"Create Validator"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install Node")
echo "============================================================"
echo "Install start"
echo "============================================================"
echo "Setup NodeName:"
echo "============================================================"
read NODENAME
echo "============================================================"
echo "Setup WalletName:"
echo "============================================================"
read WALLETNAME
echo export NODENAME=${NODENAME} >> $HOME/.bash_profile
echo export WALLETNAME=${WALLETNAME} >> $HOME/.bash_profile
echo export CHAIN_ID=teritori-testnet-v2 >> $HOME/.bash_profile
source ~/.bash_profile

#UPDATE APT
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

#INSTALL GO
wget https://golang.org/dl/go1.18.3.linux-amd64.tar.gz; \
rm -rv /usr/local/go; \
tar -C /usr/local -xzf go1.18.3.linux-amd64.tar.gz && \
rm -v go1.18.3.linux-amd64.tar.gz && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile && \
source ~/.bash_profile && \
go version

cd $HOME
rm -rf $HOME/teritori-chain $HOME/.teritorid
#INSTALL
git clone https://github.com/TERITORI/teritori-chain
cd teritori-chain
git checkout teritori-testnet-v2
make install

teritorid init $NODENAME --chain-id $CHAIN_ID


echo "============================================================"
echo "Be sure to write down the mnemonic!"
echo "============================================================"
#WALLET
teritorid keys add $WALLETNAME

teritorid tendermint unsafe-reset-all --home $HOME/.teritorid
rm $HOME/.teritorid/config/genesis.json
cp $HOME/teritori-chain/genesis/genesis.json $HOME/.teritorid/config/genesis.json
wget -O $HOME/.teritorid/config/addrbook.json https://raw.githubusercontent.com/StakeTake/guidecosmos/main/teritori/teritori-testnet-v2/addrbook.json

SEEDS=""
PEERS="0b42fd287d3bb0a20230e30d54b4b8facc412c53@176.9.149.15:26656,2f394edda96be07bf92b0b503d8be13d1b9cc39f@5.9.40.222:26656,8ce81af6b4acee9688b9b3895fc936370321c0a3@78.46.106.69:26656"; \
sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.teritorid/config/config.toml

# config pruning
indexer="null"
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"

sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.teritorid/config/config.toml
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.teritorid/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.teritorid/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.teritorid/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.teritorid/config/app.toml



tee $HOME/teritorid.service > /dev/null <<EOF
[Unit]
Description=teritori
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which teritorid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo mv $HOME/teritorid.service /etc/systemd/system/

# start service
sudo systemctl daemon-reload
sudo systemctl enable teritorid
sudo systemctl restart teritorid

break
;;

"Check Log")

journalctl -u teritorid -f -o cat

break
;;


"Check balance")
teritorid q bank balances $(teritorid keys show $WALLETNAME -a --bech acc)
break
;;

"Create Validator")
teritorid tx staking create-validator \
  --amount 1000000muon \
  --from $WALLETNAME \
  --commission-max-change-rate "0.05" \
  --commission-max-rate "0.20" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey $(teritorid tendermint show-validator) \
  --moniker $NODENAME \
  --chain-id $CHAIN_ID \
  --gas 300000 \
  -y
break
;;

"Request tokens in discord")
echo "========================================================================================================================"
echo "In order to receive tokens, you need to go to the Discord server
and request tokens in the validator channel"
echo "========================================================================================================================"

break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
