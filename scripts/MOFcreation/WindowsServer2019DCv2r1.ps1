configuration WindowsServer2019DCv1r5
{
    param()
    Import-DscResource -ModuleName PowerSTIG -ModuleVersion 4.5.1
    Node localhost
    {
        WindowsServer BaseLine
        {
            OsVersion   = '2019'
            OsRole      = 'DC'
            SkipRule    = 'V-93217', 'V-93571', 'V-93335', 'V-93429' 
            StigVersion = '1.5'
            Exception   = @{
                'V-93519' = @{
                    ValueData = '1' # Required for using Azure Image Builder access to creation
                }
                'V-92965' = @{
                    Identity = 'Guests' 
                }
                'V-93009' = @{
                    Identity = 'Guests'
                }
                'V-93011' = @{
                    Identity = 'Guests'
                }
                'V-93015' = @{
                    Identity = 'Guests'
                }
            }
        }
    }
}
WindowsServer2019DCv1r5  -Output c:\imagebuilder