configuration WindowsServer2019v12r3
{
    param()
    Import-DscResource -ModuleName PowerSTIG -ModuleVersion 4.11.0
    Node localhost
    {
        WindowsServer BaseLine
        {
            OsVersion   = '2019'
            OsRole      = 'MS'
            SkipRule    = 'V-205850', 'V-214936', 'V-205810', 'V-205737.b','V-205648.a', 'V-205648.b', 'V-205648.c', 'V-205648.d', 'V-205649.a', 'V-205649.b', 'V-205650.d', 'V-205650.b'
            StigVersion = '2.3'
            Exception   = @{
                'V-205715' = @{
                    ValueData = '1' # Required for using Azure Image Builder access to creation
                }
                'V-205733' = @{
                    Identity = 'Guests' 
                }
                'V-205672' = @{
                    Identity = 'Guests'
                }
                'V-205673' = @{
                    Identity = 'Guests'
                }
                'V-205675' = @{
                    Identity = 'Guests'
                }
            }
        }

        Chrome ChromeSettings
        {
            StigVersion = '2.3'
        }
    }
}
WindowsServer2019v12r3 -Output c:\imagebuilder
