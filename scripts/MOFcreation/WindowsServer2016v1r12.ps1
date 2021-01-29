configuration WindowsServer2016v1r12
{
    param()
    Import-DscResource -ModuleName PowerSTIG -ModuleVersion 4.5.1
    Node localhost
    {
        WindowsServer BaseLine
        {
            OsVersion   = '2016'
            OsRole      = 'MS'
            SkipRule    = 'V-73241', 'V-73279', 'V-73603' # must use an anti-virus program, host-based firewall,  'V-93335' Exploit Protection mitigations must be configured for iexplore.exe, The Windows Remote Management (WinRM) service must not store RunAs credentials
            StigVersion = '1.12'
            Exception   = @{
                'V-73495' = @{
                    ValueData = '1' # Required for using Azure Image Builder access to creation
                }
                'V-73775' = @{
                    Identity = 'Guests' 
                }
                'V-73759' = @{
                    Identity = 'Guests'
                }
                'V-73763' = @{
                    Identity = 'Guests'
                }
                'V-73771' = @{
                    Identity = 'Guests'
                }
            }
        }
    }
}
WindowsServer2016v1r12  -Output c:\imagebuilder