configuration setupAD
{
   param
   (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName xActiveDirectory, xNetworking, PSDesiredStateConfiguration, xPendingReboot, xPSDesiredStateConfiguration
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Interface=Get-NetAdapter|Where Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature DNS
        {
            Ensure = "Present"
            Name = "DNS"
        }

        Script EnableDNSDiags
        {
      	    SetScript = {
                Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics"
            }
            GetScript =  { @{} }
            TestScript = { $false }
            DependsOn = "[WindowsFeature]DNS"
        }

        WindowsFeature DnsTools
        {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
        }

        xDnsServerAddress DnsServerAddress
        {
            Address        = '127.0.0.1'
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn = "[WindowsFeature]DNS"
        }

        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
            DependsOn="[WindowsFeature]DNS"
        }

        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter
        {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSTools"
        }

        xADDomain FirstDS
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "C:\NTDS"
            LogPath = "C:\NTDS"
            SysvolPath = "C:\SYSVOL"
            DependsOn = @("[WindowsFeature]ADDSInstall")
        }

        xPendingReboot RebootAfterPromotion{
            Name = "RebootAfterPromotion"
            DependsOn = "[xADDomain]FirstDS"
        }

        xADUser aduser01
        {
            UserName = "aduser01"
            Password = (New-Object System.Management.Automation.PSCredential("aduser01@$DomainName",('Azure12345678' | ConvertTo-SecureString -AsPlainText -Force)) )
            UserPrincipalName = "aduser01@$DomainName"
            DomainName = $DomainName
            PasswordNeverExpires = $true
            DependsOn = "[xPendingReboot]RebootAfterPromotion"
        }

        xADUser admanager01
        {
            UserName = "admanager01"
            Password = (New-Object System.Management.Automation.PSCredential("admanager01@$DomainName",('Azure12345678' | ConvertTo-SecureString -AsPlainText -Force)) )
            UserPrincipalName = "admanager01@$DomainName"
            DomainName = $DomainName
            PasswordNeverExpires = $true
            DependsOn = "[xPendingReboot]RebootAfterPromotion"
        }

        xADGroup adusers
        {
            GroupName = "adusers"
            Members = "aduser01"
            DependsOn = "[xADUser]aduser01"
        }

        xADGroup admanagers
        {
            GroupName = "admanagers"
            Members = "admanager01"
            DependsOn = "[xADUser]admanager01"
        }
        
        xADGroup cloudusers
        {
            GroupName = "cloudusers"
            Members = @("adusers", "admanagers", "aduser01", "admanager01")
            DependsOn = @("[xADGroup]adusers","[xADGroup]adusers","[xADUser]aduser01","[xADUser]admanager01")
        }

        xRemoteFile DownloadPackage        
        {            	
            Uri ="http://dl.google.com/chrome/install/375.126/chrome_installer.exe"            	
            DestinationPath = "C:\packages"
        }
        
        Package Chorme
        {
            Ensure = 'Present'
            Name = 'Google Chrome'
            Path = 'C:\packages\chrome_installer.exe'
            ProductId = ''
            Arguments = '/silent /install'
            DependsOn = "[xRemoteFile]DownloadPackage"
        }
   }
}