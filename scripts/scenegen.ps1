$uri = "https://aoereleases.blob.core.windows.net/aoe-component-builds/release_AOE-M1_20210220.2/scenegen/aoe-scenegen_AOE-M1_20210218.1.zip?sp=r&st=2021-02-24T16:05:26Z&se=2021-02-25T00:05:26Z&spr=https&sv=2020-02-10&sr=b&sig=xi5uivyAMUVAd5T3pv%2FQBx%2BUpzC4nW4jyFXXUpxTWfg%3D"
Invoke-WebRequest -Uri $uri -Method Get -OutFile 'scenegen.zip'
Expand-Archive -LiteralPath 'C:\temp\SceneGen.zip' -DestinationPath 'C:\Program Files'
