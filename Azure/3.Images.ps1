#1 - Login into azure account
az login

#2 - Create resource group
$rg = 'demo'
$location = 'northeurope'

az group create `
    --name $rg  `
    --location $location

#3 - Create VNET Subnet - GatewaySubnet
az network vnet subnet create `
    --name GatewaySubnet `
    --resource-group $rg `
    --vnet-name $rg-vnet-1 `
    --address-prefix 172.1.250.0/24 

#4 - Create public IP address
az network public-ip create `
    --name $rg-vnet-1-pub-ip-1 `
    --resource-group $rg `
    --allocation-method Dynamic

#5 - Create the VPN gateway
az network vnet-gateway create `
  --name $rg-vnet-gtw-1 `
  --resource-group $rg `
  --public-ip-address $rg-vnet-1-pub-ip-1 `
  --vnet $rg-vnet-1 `
  --gateway-type Vpn `
  --sku VpnGw1 `
  --vpn-type RouteBased `
  --address-prefixes 172.100.0.0/24 `
  --client-protocol SSTP

#6 - Create root certificate
$rootCert = New-SelfSignedCertificate `
    -Subject "CN=AzureP2SRootCert" `
    -Type Custom `
    -KeySpec Signature `
    -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 `
    -KeyLength 2048 `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeyUsageProperty Sign `
    -KeyUsage CertSign

#7 - Obtain root certificate data in Base64 format
$rootCertBase64=[system.convert]::ToBase64String($rootCert.RawData)

#7 - Add root certificate to VNET gateway
az network vnet-gateway root-cert create `
    --name root `
    --gateway-name $rg-vnet-gtw-1 `
    --resource-group $rg `
    --public-cert-data $rootCertBase64

#8 - Generate VPN client configuration
az network vnet-gateway vpn-client generate `
    --name $rg-vnet-gtw-1 `
    --resource-group $rg

#9 Connect

#7 - Create client certificate
# $rootCert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {$_.Subject -match "CN=AzureP2SRootCert"}

$clientCert=New-SelfSignedCertificate `
    -Subject "CN=AzureP2SClient1" `
    -Signer $rootCert `
    -Type Custom `
    -DnsName AzureP2SClient `
    -KeySpec Signature `
    -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 `
    -KeyLength 2048 `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")

#8 - Get Vm IP addresses
az vm list-ip-addresses -o table

#9 - Check connection
ping 172.1.1.4

#10 - Login via SSH to VM Linux
ssh demoadmin@172.1.1.7

#11 - Remove client certificate
$clientCert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {$_.Subject -match "CN=AzureP2SClient1"}
az network vnet-gateway revoked-cert create `
--name Client1 `
--gateway-name $rg-vnet-gtw-1 `
--resource-group $rg `
--thumbprint $clientCert.Thumbprint