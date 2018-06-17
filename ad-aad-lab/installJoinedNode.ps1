configuration installJoinedNode
{
   param
   (
        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration, xPSDesiredStateConfiguration 

    Node localhost
    {
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

        Group aduser01
        {
            GroupName = "Remote Desktop Users"
            MembersToInclude = "tomaskubica\aduser01"
        }
   }
}