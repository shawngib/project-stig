$url = "https://raw.githubusercontent.com/shawngib/project-stig/master/azuredeploy.json"

New-AzSubscriptionDeployment `
  -Name demoSubDeployment `
  -Location eastus `
  -TemplateUri $url `
  -rgName TestSubdeploy `
  -rgLocation eastus
