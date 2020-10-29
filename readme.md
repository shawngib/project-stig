# Create Custom STIG Images

The purpose of this project to test the ability to automate STIG compliance and reporting using Azure services. 

## STIG Automation POC Primary Goals
- Microsoft Azure 1st party services
- Some level of ongoing reporting
- As hands free as possible
- Some level of ongoing maintenance

### Current Architecture
![](./images/architecture.jpg)

The overall architecture is to use a set of resources deployed via nested ARM templates from this repo. The result is an automated VM image creation via Azure Image Builer and final STIG'd images stored in the resource groups Shared Image Gallery for use in that subscription.

Basic resources used:

1. Shared Image Gallery
2. Image Definitions
3. Image Builder Templates
4. Github
5. Log Analytics Workspace
6. Azure Automation (for future use)
7. Managed Identity

Resources used in the Image building and STIG process:

1. PowerSTIG DSC - STIG and AUdit STIG
2. Custom scripts  
a. setPowerStig.ps1 = enables DSC and PowerSTIG requirements and creates scheduled task to audit  
b. audit.ps1 = Audits current state and parses state values to log

### Current supported OSes
See [Azure Image Builder](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-overview "Azure Image Builder") for more support information on locations and customization services.
* Windows 10 RS5 Enterprise/Enterprise multi-session/Professional
* Windows 2016
* Windows 2019

Not yet supported by this project are:
* Ubuntu 18.04
* Ubuntu 16.04
* RHEL 7.6, 7.7
* CentOS 7.6, 7.7
* SLES 12 SP4
* SLES 15, SLES 15 SP1

### Getting Started

To deploy the correct resources that enable a base of STIG'd images be created in you subscription run the following:

```    
    $url = "https://raw.githubusercontent.com/shawngib/project-stig/master/azuredeploy.json"
    $imageResourceGroup = "<add the resource group name to create>" 
    $deploymentName = "<Add a name of deployment>" + (Get-Random)
    New-AzSubscriptionDeployment `
      -Name $deploymentName `
      -Location eastus `
      -TemplateUri $url `
      -rgName $imageResourceGroup `
      -rgLocation eastus `
      -DeploymentDebugLogLevel All
```

At this point you should have the needed resources to create STIG'd images. Run the following for image template created that you wish an image be created in the shared image gallery.

```
    Invoke-AzResourceAction `
      -ResourceName '<name of image>' ` # Eample: Win2019_STIG
      -ResourceGroupName '<name of resource group where templates are>' `
      -ResourceType Microsoft.VirtualMachineImages/imageTemplates `
      -ApiVersion "2020-02-14" `
      -Action Run `
      -Force
```
### Current Roadmap

As of 10/28/2020 this project is beta but in working order. You can find updates here as they are published.

##Copyright

Copyright (c) 2020 Microsoft Corporation. All rights reserved