# Load balance VMs across availability zones

# Variable block
location="East US"
resourceGroup="Lyllaresgrp"
tag="load-balance-vms-across-availability-zones"
vNet="vnet-lb"
subnet="subnet-lb"
loadBalancerPublicIp="public-ip-lb"
ipSku="Standard"
zone="1 2 3"
loadBalancer="load-balancer"
frontEndIp="front-end-ip-lb"
backEndPool="back-end-pool-lb"
probe80="port80-health-probe-lb"
loadBalancerRuleWeb="load-balancer-rule-port80"
loadBalancerRuleSSH="load-balancer-rule-port22"
networkSecurityGroup="network-security-group-lb"
networkSecurityGroupRuleSSH="network-security-rule-port22-lb"
networkSecurityGroupRuleWeb="-network-security-rule-port80-lb"
nic="nic-lb"
vm="vmlylla"
image="UbuntuLTS"
login="lylla"
mdbserv="mariaserverlylla"
myNATgateway="NAT-gateway"
myNATgatewayIP="NAT-gateway-IP"
UserMDB="marialylla"


# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a virtual network and a subnet.
echo "Creating $vNet and $subnet"
az network vnet create --resource-group $resourceGroup --name $vNet --location "$location" --subnet-name $subnet

# Create a zonal Standard public IP address for load balancer.
echo "Creating $loadBalancerPublicIp"
az network public-ip create --resource-group $resourceGroup --name $loadBalancerPublicIp --sku $ipSku --zone $zone

# Create an Azure Load Balancer.
echo "Creating $loadBalancer with $frontEndIP and $backEndPool"
az network lb create --resource-group $resourceGroup --name $loadBalancer --public-ip-address $loadBalancerPublicIp --frontend-ip-name $frontEndIp --backend-pool-name $backEndPool --sku $ipSku

# Create an LB probe on port 80.
echo "Creating $probe80 in $loadBalancer"
az network lb probe create --resource-group $resourceGroup --lb-name $loadBalancer --name $probe80 --protocol tcp --port 80

# Create an LB rule for port 80.
echo "Creating $loadBalancerRuleWeb for $loadBalancer"
az network lb rule create --resource-group $resourceGroup --lb-name $loadBalancer --name $loadBalancerRuleWeb --protocol tcp --frontend-port 80 --backend-port 80 --frontend-ip-name $frontEndIp --backend-pool-name $backEndPool --probe-name $probe80

# Create three NAT rules for port 22.
echo "Creating three NAT rules named $loadBalancerRuleSSH"
for i in `seq 1 3`; do
az network lb inbound-nat-rule create --resource-group $resourceGroup --lb-name $loadBalancer --name $loadBalancerRuleSSH$i --protocol tcp --frontend-port 422$i --backend-port 22 --frontend-ip-name $frontEndIp
done

# Create a network security group
echo "Creating $networkSecurityGroup"
az network nsg create --resource-group $resourceGroup --name $networkSecurityGroup

# Create a network security group rule for port 22.
echo "Creating $networkSecurityGroupRuleSSH in $networkSecurityGroup for port 22"
az network nsg rule create --resource-group $resourceGroup --nsg-name $networkSecurityGroup --name $networkSecurityGroupRuleSSH --protocol tcp --direction inbound --source-address-prefix '*' --source-port-range '*'  --destination-address-prefix '*' --destination-port-range 22 --access allow --priority 1000

# Create a network security group rule for port 80.
echo "Creating $networkSecurityGroupRuleWeb in $networkSecurityGroup for port 22"
az network nsg rule create --resource-group $resourceGroup --nsg-name $networkSecurityGroup --name $networkSecurityGroupRuleWeb --protocol tcp --direction inbound --priority 1001 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 --access allow --priority 2000

# Create three virtual network cards and associate with public IP address and NSG.
echo "Creating three NICs named $nic for $vNet and $subnet"
for i in `seq 1 3`; do
az network nic create --resource-group $resourceGroup --name $nic$i --vnet-name $vNet --subnet $subnet --network-security-group $networkSecurityGroup --lb-name $loadBalancer --lb-address-pools $backEndPool --lb-inbound-nat-rules $loadBalancerRuleSSH$i
done

# Create three virtual machines, this creates SSH keys if not present.
echo "Creating three VMs named $vm with $nic using $image"
for i in `seq 1 3`; do
az vm create --resource-group $resourceGroup --name $vm$i --zone $i --nics $nic$i --image $image --admin-username $login --generate-ssh-keys --no-wait
done

# List the virtual machines
az vm list --resource-group $resourceGroup




# Test the load balancer


IpPublic=$(az network public-ip show \
    --resource-group $resourceGroup \
    --name $loadBalancerPublicIp \
    --query ipAddress \
    --output tsv)

echo $IpPublic
#####################################################3333
# Create a NAT Gateway

az network public-ip create \
    --resource-group $resourceGroup \
    --name $myNATgatewayIP \
    --sku Standard \
    --zone $zone

az network nat gateway create \
    --resource-group $resourceGroup \
    --name $myNATgateway \
    --public-ip-addresses $myNATgatewayIP \
    --idle-timeout 10

az network vnet subnet update \
    --resource-group $resourceGroup \
    --vnet-name $vNet \
    --name $subnet \
    --nat-gateway $myNATgateway

# Create a Maria DB server

az mariadb server create \
    --resource-group $resourceGroup \
    --name $mdbserv \
    --ssl-enforcement Disabled \
    --location francecentral \
    --admin-user $UserMDB \
    --admin-password Pass123456@! \
    --sku-name GP_Gen5_2 \
    --version 10.2

az mariadb server firewall-rule create \
    --resource-group $resourceGroup \
    --server $mdbserv \
    --name AllowMyIP \
    --start-ip-address $IpPublic \
    --end-ip-address $IpPublic



az mariadb server show \
    --resource-group $resourceGroup \
    --name $mdbserv

ssh -i .ssh/id_rsa $azureuser@$IpPublic -p 4221 