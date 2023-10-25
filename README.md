Hi Everyone,

This repository is dedicated to the resource deployment requested to the Azure Virtual Deskopt Custom Image templates

find below the official link of the microsoft documentation
https://learn.microsoft.com/en-us/azure/virtual-desktop/create-custom-image-templates

The prerequisite are the following:

Specific Azure Provider need to be register on your subscription "Microsoft.KeyVault" and "Microsoft.VirtualMachineImages"

A custom role that need to be assigned to an User Managed Identity to grant the right to Azure Image Builder to create VM on your subscription and turn them into image

An User Managed Identity where the custom role will be assigned

An Azure Compute Gallery where you will host the image that Azure Image Builder will create

An VM Image Definition inside the Azure Compute Gallery to store the image inside the Azure Compute Gallery


In this repository you will find :

Json script for:

The deployment of a Custom role "AVD-Image-Custom-Role"

The deployment of an User Managed Identity "AVD-Image-User-Managed-identity-Parameters" and "AVD-Image-User-Managed-identity-Template"

The deployment of an Azure Compute Gallery "AVD-Azure-Compute-Gallery-Parameters" and "AVD-Azure-Compute-Gallery-Template"

The deployment of an VM Image Definition inside the Azure Compute Gallery created previously "AVD-Azure-VM-Image-Definition-Parameters" and "AVD-Azure-VM-Image-Definition-Parameters"

Powershell script for:

Set up the variable for the deployment 
Triger the Json script for the resource deployment
Register the providers required for the deployment 
Deploy a Resource Group 
Assign the Custom Role to User Managed Identity

