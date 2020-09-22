# Register for image builder feature
# az feature register --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview
# Register-AzProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages

# az feature show --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview | grep state
# Get-AzProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages

$url = "https://raw.githubusercontent.com/shawngib/project-stig/master/azuredeploy.json"

New-AzSubscriptionDeployment `
  -Name demoSubDeployment `
  -Location eastus `
  -TemplateUri $url `
  -rgName TestSubdeploy `
  -rgLocation eastus
