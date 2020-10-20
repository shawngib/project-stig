# Create Custom STIG Images

The purpose of this project to test the ability to automate STIG compliance and reporting using Azure services. 

## STIG Automation POC Primary Goals
- Microsoft 1st party services
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

Resources used in the Image building process:

1. PowerSTIG DSC
2. Custom scripts

