# Running a Dedicated Ethereum RPC Node in Google Cloud || [GSP1116](https://www.cloudskillsboost.google/focuses/61475?parent=catalog) ||

## 💡 **Solution [here]()** 

####  Download and Run the Initial Script 

```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/refs/heads/main/Running%20a%20Dedicated%20Ethereum%20RPC%20Node%20in%20Google%20Cloud/gsp1116-1.sh

sudo chmod +x gsp1116-1.sh

./gsp1116-1.sh
```

```
sudo su ethereum
```
```
bash
```
```
cd ~
sudo apt update -y
sudo apt-get update -y
sudo apt install -y dstat jq
```
```
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
rm add-google-cloud-ops-agent-repo.sh
```
```
mkdir /mnt/disks/chaindata-disk/ethereum/
mkdir /mnt/disks/chaindata-disk/ethereum/geth
mkdir /mnt/disks/chaindata-disk/ethereum/geth/chaindata
mkdir /mnt/disks/chaindata-disk/ethereum/geth/logs
mkdir /mnt/disks/chaindata-disk/ethereum/lighthouse
mkdir /mnt/disks/chaindata-disk/ethereum/lighthouse/chaindata
mkdir /mnt/disks/chaindata-disk/ethereum/lighthouse/logs

sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt-get -y install Ethereum
geth version

RELEASE_URL="https://api.github.com/repos/sigp/lighthouse/releases/latest"
LATEST_VERSION=$(curl -s $RELEASE_URL | jq -r '.tag_name')

DOWNLOAD_URL=$(curl -s $RELEASE_URL | jq -r '.assets[] | select(.name | endswith("x86_64-unknown-linux-gnu.tar.gz")) | .browser_download_url')

curl -L "$DOWNLOAD_URL" -o "lighthouse-${LATEST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"

tar -xvf "lighthouse-${LATEST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"

rm "lighthouse-${LATEST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"

sudo mv lighthouse /usr/bin

lighthouse --version

cd ~
mkdir ~/.secret
openssl rand -hex 32 > ~/.secret/jwtsecret
chmod 440 ~/.secret/jwtsecret
```
```
export CHAIN=eth
export NETWORK=mainnet
export EXT_IP_ADDRESS_NAME=$CHAIN-$NETWORK-rpc-ip
export EXT_IP_ADDRESS=$(gcloud compute addresses list --filter=$EXT_IP_ADDRESS_NAME --format="value(address_range())")

nohup geth --datadir "/mnt/disks/chaindata-disk/ethereum/geth/chaindata" \
--http.corsdomain "*" \
--http \
--http.addr 0.0.0.0 \
--http.port 8545 \
--http.corsdomain "*" \
--http.api admin,debug,web3,eth,txpool,net \
--http.vhosts "*" \
--gcmode full \
--cache 2048 \
--mainnet \
--metrics \
--metrics.addr 127.0.0.1 \
--syncmode snap \
--authrpc.vhosts="localhost" \
--authrpc.port 8551 \
--authrpc.jwtsecret=/home/ethereum/.secret/jwtsecret \
--txpool.accountslots 32 \
--txpool.globalslots 8192 \
--txpool.accountqueue 128 \
--txpool.globalqueue 2048 \
--nat extip:$EXT_IP_ADDRESS \
&> "/mnt/disks/chaindata-disk/ethereum/geth/logs/geth.log" &
```
```
sudo chmod 666 /etc/google-cloud-ops-agent/config.yaml

sudo cat << EOF >> /etc/google-cloud-ops-agent/config.yaml
logging:
  receivers:
    syslog:
      type: files
      include_paths:
      - /var/log/messages
      - /var/log/syslog

    ethGethLog:
      type: files
      include_paths: ["/mnt/disks/chaindata-disk/ethereum/geth/logs/geth.log"]
      record_log_file_path: true

    ethLighthouseLog:
      type: files
      include_paths: ["/mnt/disks/chaindata-disk/ethereum/lighthouse/logs/lighthouse.log"]
      record_log_file_path: true

    journalLog:
      type: systemd_journald

  service:
    pipelines:
      logging_pipeline:
        receivers:
        - syslog
        - journalLog
        - ethGethLog
        - ethLighthouseLog
EOF

sudo systemctl stop google-cloud-ops-agent
sudo systemctl start google-cloud-ops-agent

sudo journalctl -xe | grep "google_cloud_ops_agent_engine"
```
```
sudo cat << EOF >> /etc/google-cloud-ops-agent/config.yaml
metrics:
  receivers:
    prometheus:
        type: prometheus
        config:
          scrape_configs:
            - job_name: 'geth_exporter'
              scrape_interval: 10s
              metrics_path: /debug/metrics/prometheus
              static_configs:
                - targets: ['localhost:6060']
            - job_name: 'lighthouse_exporter'
              scrape_interval: 10s
              metrics_path: /metrics
              static_configs:
                - targets: ['localhost:5054']

  service:
    pipelines:
      prometheus_pipeline:
        receivers:
        - prometheus
EOF

sudo systemctl stop google-cloud-ops-agent
sudo systemctl start google-cloud-ops-agent

sudo journalctl -xe | grep "google_cloud_ops_agent_engine"
```
```
exit
```

```
curl -LO raw.githubusercontent.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/refs/heads/main/Running%20a%20Dedicated%20Ethereum%20RPC%20Node%20in%20Google%20Cloud/gsp1116-2.sh

sudo chmod +x gsp1116-2.sh

./gsp1116-2.sh
```

### 🎉 **Congratulations on Completing the Lab!**  

##### *Your expertise and effort are shining through—keep up the amazing work!*  

#### 🔗 **Stay Connected for More Labs and Resources:**  
- 🌐 [Telegram Channel](https://t.me/quickgcplab)  
- 🤝 [Discussion Group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)