#1 - Login into azure account
az login

#2 - Set resource group & location
$rg = 'demo'
$location = 'northeurope'

#2. Attach the new disk
az vm disk attach `
    --name $rg-vm-disk-1 `
    --vm-name $rg-vm-linux-1 `
    --resource-group $rg `
    --new `
    --size-gb 25 `
    --sku "Premium_LRS" # other options are StandartSSD_LRS, and standard_LRS

az vm disk attach `
    --name $rg-vm-disk-2 `
    --vm-name $rg-vm-win1 `
    --resource-group $rg `
    --new `
    --size-gb 25 `
    --sku "Premium_LRS"

# Check VM IP Address
$VmIpAddress = az vm list-ip-addresses `
    --resource-group $rg `
    --query "[?contains(virtualMachine.name, 'linux')].virtualMachine.network.privateIpAddresses[0]" `
    --output tsv

# SSH into VM Linux machine
ssh demoadmin@$VmIpAddress

# Find new block device
lsblk
dmesg | grep SCSI

# Partition the disk
sudo fdisk /dev/sdc
m
n
p
w

# Format the disk with ext4
sudo mkfs -t ext4 /dev/sdc1

sudo mkdir /data

az disk list `
    --resource-group $rg `
    --output table

az disk update `
    --name $rg-vm-disk-2 `
    --resource-group $rg `
    --size 100

# Detach the new disk
az vm disk detach `
    --name $rg-vm-disk-2 `
    --vm-name $rg-vm-win1 `
    --resource-group $rg

# Delete the disk
az disk delete `
    --name $rg-vm-disk-1 `
    --resource-group $rg

# Grab IP Address
az vm show `
    --name $rg-vm-win1 `
    --resource-group $rg 

