##############
# Variables #
##############
$AzureSubscriptionName = "MSDN FR 2"
$ResourceLocation = "westeurope"
$NameoftheAvdImageCustomRole = "Azure Virtual Desktop Image Custom Role4"
$UserManagedIdName = "MyManagedIdentity"
$AVDImageResourceGroup = "My_AVD_Images"
$AvdAzureComputeGalleryName = "My_AVD_Azure_Compute_Gallery"

########################################################
# Github repository where the script will be download #
########################################################
$AvdImageCustomRolegithubRawUrl = "https://raw.githubusercontent.com/AlexandreMoreaux/Azure-Virtual-Desktop-Image/main/AVD-Image-Custom-role-Template.json"
$AvdImageUserManagedIdentityTemplategithubRawUrl = "https://raw.githubusercontent.com/AlexandreMoreaux/Azure-Virtual-Desktop-Image/main/AVD-Image-User-Managed-identity-Template.json"
$AvdImageUserManagedIdentityParametersgithubRawUrl = "https://raw.githubusercontent.com/AlexandreMoreaux/Azure-Virtual-Desktop-Image/main/AVD-Image-User-Managed-identity-Parameters.json"
$AvdAzureComputeGalleryTemplateRawUrl = "https://raw.githubusercontent.com/AlexandreMoreaux/Azure-Virtual-Desktop-Image/main/AVD-Azure-Compute-Gallery-Template.json"
$AvdAzureComputeGalleryParamettersRawUrl = "https://raw.githubusercontent.com/AlexandreMoreaux/Azure-Virtual-Desktop-Image/main/AVD-Azure-Compute-Gallery-Parameters.json"
$AvdImageCustomRoleOutputFile = "C:\AvdImage\AVD-Image-Custom-role.json"
$AvdImageUserManagedIdentityTemplateOutputFile = "C:\AvdImage\AVD-Image-User-Managed-identity-Template.json"
$AvdImageUserManagedIdentityParametersOutputFile = "C:\AvdImage\AVD-Image-User-Managed-identity-Parameters.json"
$AvdAzureComputeGalleryTemplateOutputFile = "C:\AvdImage\AVD-Azure-Compute-Gallery-Template.json"
$AvdAzureComputeGalleryParametersOutputFile = "C:\AvdImage\AVD-Azure-Compute-Gallery-Parameters.json"

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
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
Invoke-WebRequest -Uri $AvdImageCustomRolegithubRawUrl -OutFile $AvdImageCustomRoleOutputFile
Invoke-WebRequest -Uri $AvdImageUserManagedIdentityTemplategithubRawUrl -OutFile $AvdImageUserManagedIdentityTemplateOutputFile
Invoke-WebRequest -Uri $AvdImageUserManagedIdentityParametersgithubRawUrl -OutFile $AvdImageUserManagedIdentityParametersOutputFile
Invoke-WebRequest -Uri $AvdAzureComputeGalleryTemplateRawUrl -OutFile $AvdAzureComputeGalleryTemplateOutputFile
Invoke-WebRequest -Uri $AvdAzureComputeGalleryParamettersRawUrl -OutFile $AvdAzureComputeGalleryParametersOutputFile

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
$jsonContent = Get-Content -Path $AvdImageCustomRoleOutputFile | ConvertFrom-Json
$jsonContent.AssignableScopes = $jsonContent.AssignableScopes -replace "{subscriptionId}", $SubscriptionId
$jsonContent.Name = $NameoftheAvdImageCustomRole
$jsonContent | ConvertTo-Json | Set-Content -Path $AvdImageCustomRoleOutputFile

$jsonContent2 = Get-Content -Path $AvdImageUserManagedIdentityParametersOutputFile | ConvertFrom-Json
$jsonContent2.resources[0].name = $UserManagedIdName
$jsonContent2.resources[0].location = $ResourceLocation
$jsonContent2 | ConvertTo-Json | Set-Content -Path $AvdImageUserManagedIdentityParametersOutputFile

$jsonContent3 = Get-Content -Path $AvdAzureComputeGalleryParametersOutputFile | ConvertFrom-Json
$jsonContent3.resources[0].name = $AvdAzureComputeGalleryName
$jsonContent3.resources[0].location = $ResourceLocation
$jsonContent3 | ConvertTo-Json | Set-Content -Path $AvdAzureComputeGalleryParametersOutputFile

######################################
# Creation of the Azure Custom Role #
######################################
New-AzRoleDefinition -InputFile $AvdImageCustomRoleOutputFile

##########################################
# Creation of the User managed identity #
##########################################
New-AzResourceGroup -Name $AVDImageResourceGroup -Location $ResourceLocation
New-AzResourceGroupDeployment -ResourceGroupName $AVDImageResourceGroup -TemplateFile $AvdImageUserManagedIdentityOutputFile

###############################################
# Assign the Custom Role the User Managed Id #
###############################################
$AvdImageCustomRole = Get-AzRoleDefinition $NameoftheAvdImageCustomRole
$userManagedIdentity = Get-AzUserAssignedIdentity -ResourceGroupName $AVDImageResourceGroup -Name $UserManagedIdName
$UserManagedIdentityId = $userManagedIdentity.PrincipalId
$AvdImageCustomRoleScope = "/subscriptions/$SubscriptionId/resourceGroups/$AVDImageResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$UserManagedIdName"
New-AzRoleAssignment -ObjectId $UserManagedIdentityId -RoleDefinitionName $AvdImageCustomRole.Name -Scope $AvdImageCustomRoleScope

##########################################
# Creation of the Azure Compute Gallery #
##########################################
New-AzResourceGroupDeployment -ResourceGroupName $AVDImageResourceGroup -TemplateFile $AvdAzureComputeGalleryOutputFile
