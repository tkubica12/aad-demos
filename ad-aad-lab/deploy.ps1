$resourceGroupName = "tomaskubica-domain-rg"

New-AzureRmResourceGroup -ResourceGroupName $resourceGroupName `
-Location westeurope

$storageAccountName = "tomaskubicadomain"
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName `
  -Name $storageAccountName `
  -Location westeurope `
  -SkuName Standard_LRS `
  | New-AzureStorageContainer -Name "windows-powershell-dsc" -Permission blob

Install-Module -Name xActiveDirectory,xNetworking,xPendingReboot,xPSDesiredStateConfiguration

Publish-AzureRmVMDscConfiguration -ResourceGroupName $resourceGroupName `
  -StorageAccountName $storageAccountName `
  -ConfigurationPath .\setupAD.ps1 `
  -Force
Publish-AzureRmVMDscConfiguration -ResourceGroupName $resourceGroupName `
  -StorageAccountName $storageAccountName `
  -ConfigurationPath .\installJoinedNode.ps1 `
  -Force
Publish-AzureRmVMDscConfiguration -ResourceGroupName $resourceGroupName `
  -StorageAccountName $storageAccountName `
  -ConfigurationPath .\installStandaloneNode.ps1 `
  -Force

New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName `
-TemplateFile dc.json `
-TemplateParameterFile dc.parameters.json

Remove-AzureRmResourceGroup -Name $resourceGroupName -Force -AsJob