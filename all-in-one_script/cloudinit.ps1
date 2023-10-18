#ps1_sysnative

## download PowerShell 7.3.8
$url = 'https://github.com/PowerShell/PowerShell/releases/download/v7.3.8/PowerShell-7.3.8-win-x64.msi'
$msi_path = 'c:\PowerShell.msi'
wget $url -outfile $msi_path

## install PowerShell 7.3.8
Start-Process -wait $msi_path /quiet

## reload environment variables by setting them again in the current session (required to detect pwsh)
$env:Path = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)

## create PowerShell 7 script locally
$oci_ps7_script = 'c:\oci_ps7.ps1'

@'

## set your own object OCIDs
$secret_id = 'ocid1.vaultsecret.oc1.REGION.xxxxxxx...'
$topic_id = 'ocid1.onstopic.oc1.REGION.xxxxxxx...'

## install OCI Powershell modules

Get-PSRepository
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Install-Module -Name OCI.PSModules.Common -Force
Install-Module -Name OCI.PSModules.Objectstorage -Force
Install-Module -Name OCI.PSModules.Secrets -Force
Install-Module -Name OCI.PSModules.Ons -Force

Import-Module OCI.PSModules.Common
Import-Module OCI.PSModules.Objectstorage
Import-Module OCI.PSModules.Secrets
Import-Module OCI.PSModules.Ons

## retrieve password from OCI Vault

$auth_type = 'InstancePrincipal'

## retrieve secret bundle 
$secret = Get-OCISecretsSecretBundle -SecretId $secret_id -AuthType $auth_type

## extract Base64-encoded secret content from the secret bundle.
$base64Secret = $secret.SecretBundleContent.content
#Write-Host $base64Secret

## convert the Base64 string back to bytes
$decodedSecretBytes = [System.Convert]::FromBase64String($base64Secret)
#Write-Host $decodedSecretBytes

# define the SecureString
$secureString = ConvertTo-SecureString -AsPlainText -Force -String ([System.Text.Encoding]::ASCII.GetString($decodedSecretBytes))

## = = = = = = = = = = = = = = = = = = = = = = = = = = 
## use this code to verify secret is correctly decoded
## = = = = = = = = = = = = = = = = = = = = = = = = = = 

## convert back the SecureString to a plain text string
#$plainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString))

## print the plain text password for verification
#Write-Host "Plain text password: $plainTextPassword"

## = = = = = = = = = = = = = = = = = = = = = = = = = = 

# change the password for the user account "opc"
Set-LocalUser -Name "opc" -Password $secureString

## send OCI Notification
$messageDetails = New-Object Oci.OnsService.Models.MessageDetails
$messageDetails.Title = "Compute Instance Provisioned"

## retrieve instance properties
## ref: https://docs.oracle.com/en-us/iaas/Content/Compute/Tasks/gettingmetadata.htm
$inst_metadata = curl -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/
$vnic_metadata = curl -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/vnics/
$public_ip = curl http://ifconfig.net/

## convert JSON to PowerShell object
$instance_data = $inst_metadata | ConvertFrom-Json
$network_data = $vnic_metadata | ConvertFrom-Json

## extract values
$shape = $instance_data.shape
$ad = $instance_data.availabilityDomain
$region = $instance_data.canonicalRegionName
$displayName = $instance_data.displayName
$fd = $instance_data.faultDomain
$private_ip = $network_data.privateIp

## construct message body
$messageBody = @"
Display Name: $displayName
Private Ip: $private_ip
Public Ip: $public_ip
Shape: $shape
Region: $region
Availability Domain: $ad
Fault Domain: $fd
"@

## set the message body
$messageDetails.Body = $messageBody

## send ONS Notification
Invoke-OCIOnsPublishMessage -TopicId $topic_id -MessageDetails $messageDetails -AuthType $auth_type

## remove local files

## retrieve the path of the script itself
$script_path = $MyInvocation.MyCommand.Definition

## wait for completion
Start-Sleep -Seconds 5

## Check if the script still exists
if (Test-Path $script_path) {
    Remove-Item -Path $script_path -Force
}

'@ | Out-File -FilePath $oci_ps7_script -Encoding UTF8

## execute PowerShell7 script
pwsh $oci_ps7_script

## remove local file
if (Test-Path $msi_path) {
    Remove-Item -Path $msi_path -Force
}