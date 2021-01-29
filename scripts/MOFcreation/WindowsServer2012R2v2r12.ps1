configuration WindowsServer2012R2v2r12
{
    param()
    Import-DscResource -ModuleName PowerSTIG -ModuleVersion 4.5.1
    Node localhost
    {
        WindowsClient BaseLine
        {
            OsVersion   = '2012R2'
            OsRole      = 'MS'
            StigVersion = '2.12'
            SkipRule    = 'V-63879','V-63845','V-63403' # TODO: set for 2012 R2
            Exception   = @{
                'V-63597' = @{
                    ValueData = '1' # Required for using Azure Image Builder access to creation
                }
                'V-' = @{
                    Identity = 'Guests' 
                }
                'V-63871' = @{
                    Identity = 'Guests' 
                }
            }
        }
    }
}
WindowsServer2012R2v2r12  -Output c:\imagebuilder