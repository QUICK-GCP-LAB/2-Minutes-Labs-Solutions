export REGION_1="${ZONE_1%-*}"

export REGION_2="${ZONE_2%-*}"

gcloud compute networks create vpn-network-1 --subnet-mode custom

gcloud compute networks subnets create subnet-a \
--network vpn-network-1 --range 10.1.1.0/24 --region "$REGION_1"

gcloud compute firewall-rules create network-1-allow-custom \
  --network vpn-network-1 \
  --allow tcp:0-65535,udp:0-65535,icmp \
  --source-ranges 10.0.0.0/8

gcloud compute firewall-rules create network-1-allow-ssh-icmp \
    --network vpn-network-1 \
    --allow tcp:22,icmp

gcloud compute instances create server-1 --machine-type=e2-medium --zone $ZONE_1 --subnet subnet-a

gcloud compute networks create vpn-network-2 --subnet-mode custom

gcloud compute networks subnets create subnet-b \
--network vpn-network-2 --range 192.168.1.0/24 --region $REGION_2

gcloud compute firewall-rules create network-2-allow-custom \
  --network vpn-network-2 \
  --allow tcp:0-65535,udp:0-65535,icmp \
  --source-ranges 192.168.0.0/16

gcloud compute firewall-rules create network-2-allow-ssh-icmp \
    --network vpn-network-2 \
    --allow tcp:22,icmp

gcloud compute instances create server-2 --machine-type=e2-medium --zone $ZONE_2 --subnet subnet-b



## OLD

gcloud compute addresses create vpn-1-static-ip --project=$DEVSHELL_PROJECT_ID --region=$REGION_1

gcloud compute addresses create vpn-2-static-ip --project=$DEVSHELL_PROJECT_ID --region=$REGION_2

sleep 20

IP_ADDRESS_1=$(gcloud compute addresses describe vpn-1-static-ip --region=$REGION_1 --format="get(address)")


IP_ADDRESS_2=$(gcloud compute addresses describe vpn-2-static-ip --region=$REGION_2 --format="get(address)")


gcloud compute target-vpn-gateways create vpn-1 --project=$DEVSHELL_PROJECT_ID --region=$REGION_1 --network=vpn-network-1 && gcloud compute forwarding-rules create vpn-1-rule-esp --project=$DEVSHELL_PROJECT_ID --region=$REGION_1 --address=$IP_ADDRESS_1 --ip-protocol=ESP --target-vpn-gateway=vpn-1 && gcloud compute forwarding-rules create vpn-1-rule-udp500 --project=$DEVSHELL_PROJECT_ID --region=$REGION_1 --address=$IP_ADDRESS_1 --ip-protocol=UDP --ports=500 --target-vpn-gateway=vpn-1 && gcloud compute forwarding-rules create vpn-1-rule-udp4500 --project=$DEVSHELL_PROJECT_ID --region=$REGION_1 --address=$IP_ADDRESS_1 --ip-protocol=UDP --ports=4500 --target-vpn-gateway=vpn-1 && gcloud compute vpn-tunnels create tunnel1to2 --project=$DEVSHELL_PROJECT_ID --region=$REGION_1 --peer-address=$IP_ADDRESS_2 --shared-secret=gcprocks --ike-version=2 --local-traffic-selector=0.0.0.0/0 --remote-traffic-selector=0.0.0.0/0 --target-vpn-gateway=vpn-1 && gcloud compute routes create tunnel1to2-route-1 --project=$DEVSHELL_PROJECT_ID --network=vpn-network-1 --priority=1000 --destination-range=10.1.3.0/24 --next-hop-vpn-tunnel=tunnel1to2 --next-hop-vpn-tunnel-region=$REGION_1


gcloud compute target-vpn-gateways create vpn-2 --project=$DEVSHELL_PROJECT_ID --region=$REGION_2 --network=vpn-network-2 && gcloud compute forwarding-rules create vpn-2-rule-esp --project=$DEVSHELL_PROJECT_ID --region=$REGION_2 --address=$IP_ADDRESS_2 --ip-protocol=ESP --target-vpn-gateway=vpn-2 && gcloud compute forwarding-rules create vpn-2-rule-udp500 --project=$DEVSHELL_PROJECT_ID --region=$REGION_2 --address=$IP_ADDRESS_2 --ip-protocol=UDP --ports=500 --target-vpn-gateway=vpn-2 && gcloud compute forwarding-rules create vpn-2-rule-udp4500 --project=$DEVSHELL_PROJECT_ID --region=$REGION_2 --address=$IP_ADDRESS_2 --ip-protocol=UDP --ports=4500 --target-vpn-gateway=vpn-2 && gcloud compute vpn-tunnels create tunnel2to1 --project=$DEVSHELL_PROJECT_ID --region=$REGION_2 --peer-address=$IP_ADDRESS_1 --shared-secret=gcprocks --ike-version=2 --local-traffic-selector=0.0.0.0/0 --remote-traffic-selector=0.0.0.0/0 --target-vpn-gateway=vpn-2 && gcloud compute routes create tunnel2to1-route-1 --project=$DEVSHELL_PROJECT_ID --network=vpn-network-2 --priority=1000 --destination-range=10.5.4.0/24 --next-hop-vpn-tunnel=tunnel2to1 --next-hop-vpn-tunnel-region=$REGION_2