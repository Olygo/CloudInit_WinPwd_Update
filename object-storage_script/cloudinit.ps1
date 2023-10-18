#ps1_sysnative

## download PowerShell 7.3.8
$url = 'https://YOUR-NAME-SPACE.objectstorage.REGION.oci.customer-oci.com/p/xxxxxxxxxxxxx/n/YOUR-NAMESPACE/b/BUCKET-NAME/o/OBJECT-NAME'
$msi_path = 'c:\PowerShell.msi'
wget $url -outfile $msi_path

## install PowerShell 7.3.8
Start-Process -wait $msi_path /quiet

## reload environment variables by setting them again in the current session (required to detect pwsh)
$env:Path = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)

## download PowerShell 7 script locally
$script_url = 'https://YOUR-NAME-SPACE.objectstorage.REGION.oci.customer-oci.com/p/xxxxxxxxxxxxx/n/YOUR-NAMESPACE/b/BUCKET-NAME/o/OBJECT-NAME'
$script_path = 'oci_ps7_script.ps1'
wget $script_url -outfile $script_path

## execute PowerShell7 script
pwsh $script_path

## remove local file
if (Test-Path $script_path) {
    Remove-Item -Path $script_path -Force
}