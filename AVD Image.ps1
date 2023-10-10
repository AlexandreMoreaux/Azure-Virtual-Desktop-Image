#Azure Subscription Name
$AzureSubscriptionName = "MSDN FR 2"
$ResourceLocation = "westeurope"
$NameoftheAvdImageCustomRole = "Azure Virtual Desktop Image Custom Role3"
$UserManagedIdName = "My_AVD_Images_ID"
$AVDImageResourceGroup = "My_AVD_Images"
$AvdAzureComputeGalleryName = "My_AVD_Azure_Compute_Gallery"

#Github repository where the script will be download
$AvdImageCustomRolegithubRawUrl = "https://raw.githubusercontent.com/Aldebarancloud/WVDCourse/main/AVD-Image-Custom-role.json"
$AvdImageUserManagedIdentitygithubRawUrl = "https://raw.githubusercontent.com/Aldebarancloud/WVDCourse/main/AVD-Image-User-Managed-identity.json"
$AvdAzureComputeGalleryRawUrl = ""

# Download the JSON file from GitHub and save it locally
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

#Change the letters by the letter you want to use 
Invoke-WebRequest -Uri $AvdImageCustomRolegithubRawUrl -OutFile C:\AVD-Image-Custom-role.json
Invoke-WebRequest -Uri $AvdImageUserManagedIdentitygithubRawUrl -OutFile C:\AVD-Image-User-Managed-identity.json
Invoke-WebRequest -Uri $AvdAzureComputeGalleryRawUrl -OutFile C:\AVD-Azure-Compute-Gallery

#Connect to the Azure Account and Azure AD
Install-Module az -Force
Import-Module az -Force
Install-Module azuread -Force
Import-Module azuread -Force
Connect-AzAccount
$Subscription = Get-AzSubscription -SubscriptionName $AzureSubscriptionName
$SubscriptionId = $Subscription.Id
Select-AzSubscription -SubscriptionId $SubscriptionId
$TenantId = $subscription.TenantId
Connect-AzureAD -TenantId $TenantId

#Register Provider
Register-AzResourceProvider -ProviderNamespace Microsoft.KeyVault
Register-AzResourceProvider -ProviderNamespace Microsoft.Network
Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
Register-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
Register-AzResourceProvider -ProviderNamespace Microsoft.insights
Register-AzResourceProvider -ProviderNamespace Microsoft.DesktopVirtualization

# Read the JSON file of the Custom Role
#Change the letters by the letter you want to use 
$jsonContent = Get-Content -Path C:\AVD-Image-Custom-role.json | ConvertFrom-Json

# Modify the value of the custom role for the Azure Subscription with the subscription id get previously
$jsonContent.AssignableScopes = $jsonContent.AssignableScopes -replace "{subscriptionId}", $SubscriptionId
$jsonContent.Name = $NameoftheAvdImageCustomRole

# Write the updated JSON back to the file
$jsonContent | ConvertTo-Json | Set-Content -Path C:\AVD-Image-Custom-role.json

# Read the JSON file of the Managed Identity
$jsonContent2 = Get-Content -Path C:\AVD-Image-User-Managed-identity.json | ConvertFrom-Json

# Update the values of the Managed Identity with the variable set previously
$jsonContent2.resources[0].name = $UserManagedIdName
$jsonContent2.resources[0].location = $ResourceLocation

# Read the JSON file of the Azure Compute Gallery
$jsonContent3 = Get-Content -Path C:\AVD-Azure-Compute-Gallery | ConvertFrom-Json

# Update the values of the Managed Identity with the variable set previously
$jsonContent3.resources[0].name = $AvdAzureComputeGalleryName
$jsonContent3.resources[0].location = $ResourceLocation

# Create the custom role from the JSON file
#Change the letters by the letter you want to use
New-AzRoleDefinition -InputFile C:\AVD-Image-Custom-role.json
#Congratulation the Custom role is created 

#Deploy the ARM template to create the User managed identity
New-AzResourceGroup -Name $AVDImageResourceGroup -Location $ResourceLocation
New-AzResourceGroupDeployment -ResourceGroupName $AVDImageResourceGroup -TemplateFile C:\AVD-Image-User-Managed-identity.json
#Congratulation the User Managed Identity is created 

#Assign the Custom Role the User Managed Id
Install-Module Az.ManagedServiceIdentity -Force
Import-Module Az.ManagedServiceIdentity -Force
$AvdImageCustomRole = Get-AzRoleDefinition $NameoftheAvdImageCustomRole
$userManagedIdentity = Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $identityName
$UserManagedIdentityId = $userManagedIdentity.Id
$AvdImageCustomRoleScope = "/subscriptions/$SubscriptionId/resourceGroups/$UserManagedIDResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$UserManagedIdName"
New-AzRoleAssignment -ObjectId $UserManagedIdentityId -RoleDefinitionName $AvdImageCustomRole.Name -Scope $AvdImageCustomRoleScope
#Congratulation the Custom Role has been assigned to the User Managed Identity

#Deploy the ARM template to create the Azure Compute Gallery
New-AzResourceGroup -Name $AVDImageResourceGroup -Location $ResourceLocation
New-AzResourceGroupDeployment -ResourceGroupName $AVDImageResourceGroup -TemplateFile C:\AVD-Azure-Compute-Gallery
#Congratulation the Azure Compute Gallery is created 