configuration Windows10v2r1
{
    param()
    Import-DscResource -ModuleName PowerSTIG -ModuleVersion 4.7.1
    Node localhost
    {
        WindowsClient BaseLine
        {
            OsVersion   = '10'
            StigVersion = '2.1'
            SkipRule    = 'V-220972','V-220957','V-220725' 
            Exception   = @{
                'V-220799' = @{
                    ValueData = '1' # Required for using Azure Image Builder access to creation
                }
                'V-220968' = @{
                    Identity = 'Guests' 
                }
            }
        }
        Chrome ChromeSettings
        {
            StigVersion = '2.1'
        }
        Office OfficeSystem
        {
            OfficeApp = 'System2016'
            Stigversion    = '1.1'
        }
    }
}
Windows10v2r1  -Output c:\imagebuilder