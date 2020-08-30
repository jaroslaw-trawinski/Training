#1 - Login into azure account
az login

#2 - Create resource group
Write-Output 'Creating Resource Group...'
$rg = 'demo'
$location = 'northeurope'

az group create `
    --name $rg  `
    --location $location

#3 - Create virtual network
Write-Output 'Creating VNET...'
az network vnet create `
    --name $rg-vnet-1 `
    --resource-group $rg `
    --location $location `
    --address-prefix 172.1.0.0/16 `
    --subnet-name $rg-vnet-1-sub-1 `
    --subnet-prefix 172.1.1.0/24 

#4 - Create network security group
Write-Output 'Creating NSG...'
az network nsg create `
    --name $rg-vnet-1-nsg-1 `
    --resource-group $rg

#5 - Create public IP address
Write-Output "Creating public IP..." 
az network public-ip create `
    --name $rg-vnet-1-pub-ip-1 `
    --resource-group $rg `
    --allocation-method Dynamic # or Static

#6.1 - Create Network Interface for Linux VM
Write-Output 'Creating NIC for Linux VM...'
az network nic create `
    --name $rg-vnet-1-nic-linux-1 `
    --resource-group $rg `
    --location $location  `
    --subnet $rg-vnet-1-sub-1 `
    --network-security-group $rg-vnet-1-nsg-1 `
    --vnet-name $rg-vnet-1
    # --public-ip-address $rg-vnet-1-pub-ip-1 #disallowed by policy

#6.2 - Create Linux VM
Write-Output 'Creating Linux VM...'
az vm create `
    --name $rg-vm-linux-1 `
    --resource-group $rg `
    --location $location `
    --image "UbuntuLTS" `
    --nics $rg-vnet-1-nic-linux-1 `
    --authentication-type ssh `
    --admin-username demoadmin `
    --ssh-key-value C:\Users\jaros\.ssh\id_rsa.pub

az vm image list -o table
#7.1 - Create Network Interface for Windows VM
Write-Output 'Creating NIC for Windows VM...'
az network nic create `
    --name $rg-vnet-1-nic-windows-1 `
    --resource-group $rg `
    --location $location `
    --subnet $rg-vnet-1-sub-1 `
    --network-security-group $rg-vnet-1-nsg-1 `
    --vnet-name $rg-vnet-1 
    # --public-ip-address $rg-pub-ip-1v #disallowed by policy

#7.2 - Create Windows VM
Write-Output 'Creating Windows VM...'
az vm create `
    --name $rg-vm-win1 `
    --resource-group $rg `
    --location $location `
    --image "win2016datacenter" `
    --nics $rg-vnet-1-nic-windows-1 `
    --admin-username demoadmin `
    --admin-password 'FlexDev2020!'


#8 - Get list of VMs
Write-Output 'Getting list of VM IDs...'
$VmIds = az vm list `
    --resource-group $rg `
    -o tsv `
    --query "[].id" 

Write-Output 'Created and running VMs:'
Write-Output $VmIds

#9 - Stop VMs
Write-Output 'Stopping VMS...'
# az vm stop --ids $VmIds

#10 - Deallocate VMs 
Write-Output 'Deallocating VMS...'
# az vm deallocate --ids $VmIds