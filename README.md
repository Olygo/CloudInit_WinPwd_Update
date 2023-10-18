# OCI Cloud-Init WinPwd Update


## Overview

**This OCI Cloud-Init script :**

- Automates the installation of PowerShell 7.3.8 and OCI PowerShell modules on a Windows-based OCI compute instance. 
- Retrieves a secret from OCI Vault to update the Windows password for the OPC account
- Configures certain instance parameters. 
- Sends an OCI Notification.

**2 examples are provided :**

**- ./all-in-one_script/cloudinit.ps1**

		Starts from PowerShell 5
		Downloads PowerShell 7 MSI from GitHub
		Installs PowerShell 7 binaries
		Creates PowerShell 7 script
		Runs PowerShell 7 script
		Installs OCI PowerShell Modules
		Updates OPC password

**- ./object-storage_script/cloudinit.ps1**

		Starts from PowerShell 5
		Downloads PowerShell 7 MSI from an OCI Object storage bucket URl using a Pre-Authenticated Request
		Installs PowerShell 7 binaries
		Downloads PowerShell 7 script from an OCI Object storage bucket URl using a Pre-Authenticated Request
		Executes PowerShell 7 script 
		Installs OCI PowerShell Modules
		Updates OPC password
		
./object-storage_script/bucket/oci_ps7_script.ps1 must be uploaded in your bucket.

## Usage

Download or copy the script in the Cloud-Init section [while creating the compute instance](https://docs.public.oneportal.content.oci.oraclecloud.com/en-us/iaas/Content/Compute/Tasks/launchinginstance.htm).

Update the following variables :

- `$secret_id`: Replace with the OCID of the secret you want to retrieve.
- `$topic_id`: Replace with the OCID of the OCI Notification topic you want to use.

Once you have customized the script and updated the required variables, you can use it as part of your OCI compute instance creation process to automate the installation and configuration of PowerShell and related OCI modules.

## Prerequisites

Because this script will retrieve data from your OCI tenancy (Secret in vault, data from object storage, etc.) you must allow instance authentication.

1. **Create a dynamic group**

   - [Create a dynamic group](https://docs.oracle.com/en-us/iaas/Content/Identity/dynamicgroups/To_create_a_dynamic_group.htm)
   - Set a matching rule identifying either a compartment (all the instances in it) or a single instance OCID.
    
2. **Create a policy**

   - [Create a policy](https://docs.oracle.com/en-us/iaas/Content/Identity/policymgmt/managingpolicies_topic-To_create_a_policy.htm)
	
	If your tenancy uses [Identity Domains](https://docs.oracle.com/en/cloud/paas/application-integration/oracle-integration-oci/setting-users-groups-and-policies1.html#GUID-E6A80629-A6CA-4E9F-8681-20D31F909EC7):

		Allow dynamic-group 'YOUR-IDCS-DOMAIN-NAME'/'YOUR-DG-NAME' to manage all-resources in compartment YOUR-COMPARTMENT

	If your tenancy doesn't use [Identity Domains](https://docs.oracle.com/en/cloud/paas/application-integration/oracle-integration-oci/setting-users-groups-and-policies1.html#GUID-E6A80629-A6CA-4E9F-8681-20D31F909EC7):

		Allow dynamic-group YOUR-DG-NAME to manage all-resources in compartment YOUR-COMPARTMENT

	Feel free to adapt your policy statements based on your security requirements, for example:
	
		Allow dynamic-group YOUR-DG-NAME to read secret-family in compartment YOUR-COMPARTMENT where target.vault.id='YOUR_VAULT_OCID'
		Allow dynamic-group YOUR-DG-NAME to read objectstorage-namespaces in tenancy
		Allow dynamic-group YOUR-DG-NAME to read buckets in compartment YOUR-COMPARTMENT
		Allow dynamic-group YOUR-DG-NAME to read objects in compartment YOUR-COMPARTMENT where target.bucket.name='YOUR_BUCKET_NAME'
		Allow dynamic-group YOUR-DG-NAME to use ons-topic in compartment YOUR-COMPARTMENT	


***Both policy and dynamic-group can be removed after instances provisioning***

3. **Create a Vault and a Secret**

   - [Create an OCI Vault](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/Tasks/managingvaults_topic-To_create_a_new_vault.htm) to store your secret, your Windows password.

   - [Create a Secret in a Vault](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/Tasks/managingsecrets_topic-To_create_a_new_secret.htm) to store your password encrypted
    


## What does this OCI Cloud-init script do?
This OCI Cloud-init script performs the following tasks:


1. **Download PowerShell 7.3.8**

   The script downloads PowerShell 7.3.8 from GitHub using the provided URL.
    
   The MSI file will be saved to 'c:\PowerShell.msi'.

2. **Install PowerShell 7.3.8**

   PowerShell 7.3.8 is installed using the downloaded MSI file. This step is executed silently.
   
   PowerShell 7 is a prerequisite for using OCI PowerShell Modules

3. **Reload Environment Variables**

   The script reloads environment variables to detect PowerShell 7 (pwsh.exe) from PowerShell 5 session.

4. **Create PowerShell 7 Script Locally**

   The script creates a PowerShell script named 'oci_ps7.ps1' with the necessary configurations. 
   
   You can customize this script if needed.

5. **Install OCI PowerShell Modules**

   The script installs required OCI PowerShell modules from the PowerShell Gallery. These modules include:

   - [OCI.PSModules.Common](https://www.powershellgallery.com/packages/OCI.PSModules.Common/)
   - [OCI.PSModules.Objectstorage](https://www.powershellgallery.com/packages/OCI.PSModules.Objectstorage/)
   - [OCI.PSModules.Secrets](https://www.powershellgallery.com/packages/OCI.PSModules.Secrets/)
   - [OCI.PSModules.Ons](https://www.powershellgallery.com/packages/OCI.PSModules.Ons/)


6. **Retrieve Secret from OCI Vault**

   The script retrieves a secret from OCI Vault using a specific `$secret_id`. 

	You need to set the following parameters:

    `$secret_id`: Your secret OCID in your OCI Vault


7. **Update OPC account password**

   It decodes the secret and updates the Windows password for the 'opc' account using the decoded secret.

8. **Send OCI Notification**

	***This script runs after instance provisioning, you must wait to receive the notification before being able to connect with your own password***

   The script sends an OCI Notification when update completed.
   
   You must create [an OCI Notification Topic](https://docs.oracle.com/en-us/iaas/Content/Notification/Tasks/create-topic.htm)
   as well as [an an Email Subscription](https://docs.oracle.com/en-us/iaas/Content/Notification/Tasks/create-subscription-email.htm#top)
   
   You need to set the following parameters:

   `$topic_id`: The OCID of your OCI Notification topic.

   Finally, it sends the message using the specified topic.

   The Email notification contains the following information about the Compute instance:
	
		Display Name: MyComputeInstance
		Private Ip: 192.168.1.100
		Public Ip: 135.8.9.10
		Shape: VM.Standard.E5.Flex
		Region: eu-frankfurt-1
		Availability Domain: EU-FRANKFURT-1-AD-1
		Fault Domain: FAULT-DOMAIN-2

9. **Clean Up**

   After execution, the script removes the downloaded MSI file and the 'oci_ps7.ps1' script from the local system.

## Debug information

You can read the Cloudbase log file if something goes wrong.

		C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\cloudbase-init 

## Additional information

**Store MSI and/or scripts in OCI Object Storage**

If you store the MSI installer and/or the OCI Cloud-Init script in OCI Object Storage, you must create a [Pre-Authenticated Request](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/usingpreauthenticatedrequests_topic-To_create_a_preauthenticated_request_for_all_objects_in_a_bucket.htm). 

The script assumes you have a URL like this:

   ```
   https://YOUR-NAMESPACE.objectstorage.REGION.oci.customer-oci.com/p/xxx.XXX/n/YOUR-NAMESPACE/b/BUCKET-NAME/o/OBJECT-NAME
   ```

   
**OCI PowerShell Modules**

[https://www.powershellgallery.com/packages?q=oci](https://www.powershellgallery.com/packages?q=oci)

**See Package Details (commands)**

[https://www.powershellgallery.com/packages/OCI.PSModules/](https://www.powershellgallery.com/packages/OCI.PSModules/)
[https://www.powershellgallery.com/packages/OCI.PSModules.Core/](https://www.powershellgallery.com/packages/OCI.PSModules.Core/)
[https://www.powershellgallery.com/packages/OCI.PSModules.Identity/](https://www.powershellgallery.com/packages/OCI.PSModules.Identity/)
[https://www.powershellgallery.com/packages/OCI.PSModules.Identitydomains/](https://www.powershellgallery.com/packages/OCI.PSModules.Identitydomains/)
[https://www.powershellgallery.com/packages/OCI.PSModules.Vault/](https://www.powershellgallery.com/packages/OCI.PSModules.Vault/)
[https://www.powershellgallery.com/packages/OCI.PSModules.Keymanagement/](https://www.powershellgallery.com/packages/OCI.PSModules.Keymanagement/)


**Install all OCI PS Modules (only if used)**

		Install-Module -Name OCI.PSModules -Force

**install most common OCI PS Modules (only if used)**

		Install-Module -Name OCI.PSModules.Core -Force
		Install-Module -Name OCI.PSModules.Identity -Force
		Install-Module -Name OCI.PSModules.Identitydomains -Force
		Install-Module -Name OCI.PSModules.Vault -Force
		Install-Module -Name OCI.PSModules.Keymanagement -Force


**See Package Details about installed OCI PS Modules**

[https://www.powershellgallery.com/packages/OCI.PSModules.Common/](https://www.powershellgallery.com/packages/OCI.PSModules.Common/)
[https://www.powershellgallery.com/packages/OCI.PSModules.Objectstorage/](https://www.powershellgallery.com/packages/OCI.PSModules.Objectstorage/)
[https://www.powershellgallery.com/packages/OCI.PSModules.Secrets/](https://www.powershellgallery.com/packages/OCI.PSModules.Secrets/)
[https://www.powershellgallery.com/packages/OCI.PSModules.Ons/](https://www.powershellgallery.com/packages/OCI.PSModules.Ons/)

## License

This script is provided under the [MIT License](LICENSE). You are free to use, modify, and distribute it as per the terms of the license.


## Disclaimer
**Please test properly on test resources, before using it on production resources to prevent unwanted outages or unwanted bills.**


## Questions ?
Please feel free to reach out for any clarifications or assistance in using this script in your OCI CloudShell environment.

**_olygo.git@gmail.com_**