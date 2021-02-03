configuration WindowsServer2019v2r1
{
    param()
    Import-DscResource -ModuleName PowerSTIG -ModuleVersion 4.7.1
    Node localhost
    {
        WindowsServer BaseLine
        {
            OsVersion   = '2019'
            OsRole      = 'MS'
            SkipRule    = 'V-205850', 'V-214936', 'V-205889', 'V-205810', 'V-205737.b'
            StigVersion = '2.1'
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
            StigVersion = '2.1'
        }
    }
}
WindowsServer2019v2r1 -Output c:\imagebuilder