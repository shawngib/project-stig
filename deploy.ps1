$url = "https://raw.githubusercontent.com/shawngib/project-stig/master/azuredeploy.json"

New-AzSubscriptionDeployment -Name "demoSubDeployment" -Location "usgovarizona" -rgName "TestSubdeploy" -rgLocation "usgovarizona" -TemplateUri ($url)