#!/bin/bash

echo creation GR-------------------------
resourcegroup="lylgr"
location="westus3"
az group create --name $resourcegroup --location $location

echo Create virtual machine-------------------
vmname="mywpvm"
username="lylla"
az vm create \
    --resource-group $resourcegroup \
    --name $vmname \
    --image UbuntuLTS \
    --public-ip-sku Standard \
    --admin-username $username
	



az vm open-port --port 80 --resource-group $resourcegroup --name $vmname
	