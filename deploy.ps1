# Register for image builder feature
# az feature register --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview
# Register-AzProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages

# az feature show --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview | grep state
# Get-AzProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages

$url = "https://raw.githubusercontent.com/shawngib/project-stig/master/azuredeploy.json"
$imageResourceGroup = "TestSubdeploy"
# Special notes:
# - workspace template include automation account and both have hard coded location. https://docs.microsoft.com/en-us/azure/automation/how-to/region-mappings#supported-mappings
New-AzSubscriptionDeployment `
  -Name demoSubDeployment `
  -Location eastus `
  -TemplateUri $url `
  -rgName $imageResourceGroup `
  -rgLocation eastus `
  -DeploymentDebugLogLevel All

$title    = 'Run action?'
$question = 'Would you like to run create image action:'
$choices  = '&Yes', '&No'

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if ($decision -eq 0) {
    Write-Host 'Running create image action.' -ForegroundColor Green
#    Invoke-AzResourceAction `
#      -ResourceName 'TestSubdeploy-image-ul2qw6' ` # Need to manually set this TODO: fix, answer no for now
#      -ResourceGroupName 'TestSubdeploy' `
#      -ResourceType Microsoft.VirtualMachineImages/imageTemplates `
#      -ApiVersion "2020-02-14" `
#      -Action Run
} else {
    Write-Host 'Skipping create image action.' -ForegroundColor Red
}

#az image builder list
#$resTemplateId = Get-AzResource -ResourceName $imageTemplateName -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2019-05-01-preview"