#bin/bash

export RESOURCE_GROUP_NAME=Lyllaresgrp
export LOCATION=westeurope
export VM_NAME=myvmlylla
export VM_IMAGE=ubuntuLTS
export ADMIN_USERNAME=lylla

echo---creation groupe de ressource et vm--------
az group create--name$RESOURCE_GROUP_NAME--location$LOCATION

az vm create\
--resource-group$RESOURCE_GROUP_NAME\
--name$VM_NAME\
--image$VM_IMAGE\
--admin-username$ADMIN_USERNAME\
--generate-ssh-keys\
--public-ip-skuStandard
