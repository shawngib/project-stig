configuration Windows10v1r23
{
    param
    (
        [parameter()]
        [string]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName PowerStig

    Node $NodeName
    {
        WindowsClient BaseLine
        {
            OsVersion   = '10'
            StigVersion = '1.23'
            SkipRule    = 'V-63879','V-63845','V-63403'
            # 63879  Allow remote us (medium)
            # 63347 WinRM = no basic authentication??? (medium)
            # 63335 WinRM = no plain text???? (medium)
            # 71769 Restrict SAM???? (medium)
            # 63845 'Access to computer from network." ????" (medium)
            # 63339 WinRM unecryoted????? \SOFTWARE\Policies\Microsoft\Windows\WinRM\Client\ (medium)
            # 63369 WinRM unecryoted????? \SOFTWARE\Policies\Microsoft\Windows\WinRM\Service\ (medium)
            # 63741 WinRM unecryoted????? \SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\ (medium)
            # 63403 Inbound Firewall Exceptions for Remote - inbound rules require scoping to IP

        }
    }
}
Windows10v1r23