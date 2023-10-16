##############
# Variables #
##############
$AzureSubscriptionName = "MSDN FR 2"
$ResourceLocation = "westeurope"
$NameoftheAvdImageCustomRole = "Azure Virtual Desktop Image Custom Role3"
$UserManagedIdName = "My_AVD_Images_ID"
$AVDImageResourceGroup = "My_AVD_Images"
$AvdAzureComputeGalleryName = "My_AVD_Azure_Compute_Gallery"

########################################################
# Github repository where the script will be download #
########################################################
$AvdImageCustomRolegithubRawUrl = "https://github.com/AlexandreMoreaux/Azure-Virtual-Desktop-Image/blob/main/AVD-Image-Custom-role.json"
$AvdImageUserManagedIdentitygithubRawUrl = "https://github.com/AlexandreMoreaux/Azure-Virtual-Desktop-Image/blob/main/AVD-Image-User-Managed-identity.json"
$AvdAzureComputeGalleryRawUrl = "https://raw.githubusercontent.com/AlexandreMoreaux/Azure-Virtual-Desktop-Image/main/AVD-Azure-Compute-Gallery.json"
$AvdImageCustomRoleOutputFile = "AVD-Image-Custom-role.json"
$AvdImageUserManagedIdentityOutputFile = "AVD-Image-User-Managed-identity.json"
$AvdAzureComputeGalleryOutputFile = "AVD-Azure-Compute-Gallery.json"

##########################
# Create Temp Directory #
##########################
$folderPath = "C:\AvdImage"

if (-not (Test-Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath
    Write-Host "Folder created: $folderPath"
} else {
    Write-Host "Folder already exists: $folderPath"
}

###########################################################
# Download the JSON file from GitHub and save it locally #
###########################################################
Set-Location $folderPath
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
Invoke-WebRequest -Uri $AvdImageCustomRolegithubRawUrl -OutFile $AvdImageCustomRoleOutputFile
Invoke-WebRequest -Uri $AvdImageUserManagedIdentitygithubRawUrl -OutFile $AvdImageUserManagedIdentityOutputFile
Invoke-WebRequest -Uri $AvdAzureComputeGalleryRawUrl -OutFile $AvdAzureComputeGalleryOutputFile

##################################
# Connect to Azure and Azure AD #
##################################
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

######################
# Register Provider #
######################
Register-AzResourceProvider -ProviderNamespace Microsoft.KeyVault
Register-AzResourceProvider -ProviderNamespace Microsoft.Network
Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
Register-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
Register-AzResourceProvider -ProviderNamespace Microsoft.insights
Register-AzResourceProvider -ProviderNamespace Microsoft.DesktopVirtualization

#############################################
# Modify the Json Script with the Variable #
#############################################
$jsonContent = Get-Content -Path C:\AvdImage\AVD-Image-Custom-role.json | ConvertFrom-Json
$jsonContent.AssignableScopes = $jsonContent.AssignableScopes -replace "{subscriptionId}", $SubscriptionId
$jsonContent.Name = $NameoftheAvdImageCustomRole
$jsonContent | ConvertTo-Json | Set-Content -Path C:\AvdImage\AVD-Image-Custom-role.json

$jsonContent2 = Get-Content -Path C:\AvdImage\AVD-Image-User-Managed-identity.json | ConvertFrom-Json
$jsonContent2.resources[0].name = $UserManagedIdName
$jsonContent2.resources[0].location = $ResourceLocation

$jsonContent3 = Get-Content -Path C:\AvdImage\AVD-Azure-Compute-Gallery.json | ConvertFrom-Json
$jsonContent3.resources[0].name = $AvdAzureComputeGalleryName
$jsonContent3.resources[0].location = $ResourceLocation

######################################
# Creation of the Azure Custom Role #
######################################
New-AzRoleDefinition -InputFile C:\AVD-Image-Custom-role.json

##########################################
# Creation of the User managed identity #
##########################################
New-AzResourceGroup -Name $AVDImageResourceGroup -Location $ResourceLocation
New-AzResourceGroupDeployment -ResourceGroupName $AVDImageResourceGroup -TemplateFile C:\AVD-Image-User-Managed-identity.json

###############################################
# Assign the Custom Role the User Managed Id #
###############################################
Install-Module Az.ManagedServiceIdentity -Force
Import-Module Az.ManagedServiceIdentity -Force
$AvdImageCustomRole = Get-AzRoleDefinition $NameoftheAvdImageCustomRole
$userManagedIdentity = Get-AzUserAssignedIdentity -ResourceGroupName $AVDImageResourceGroup -Name $UserManagedIdName
$UserManagedIdentityId = $userManagedIdentity.Id
$AvdImageCustomRoleScope = "/subscriptions/$SubscriptionId/resourceGroups/$UserManagedIDResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$UserManagedIdName"
New-AzRoleAssignment -ObjectId $UserManagedIdentityId -RoleDefinitionName $AvdImageCustomRole.Name -Scope $AvdImageCustomRoleScope

##########################################
# Creation of the Azure Compute Gallery #
##########################################
New-AzResourceGroup -Name $AVDImageResourceGroup -Location $ResourceLocation
New-AzResourceGroupDeployment -ResourceGroupName $AVDImageResourceGroup -TemplateFile C:\AVD-Azure-Compute-Gallery
