# May need to run:
#  winget install -e --id Microsoft.Bicep

Param (
    [Parameter(Mandatory = $true)] $SubscriptionId,
    $Prefix = "managedidentityrepro",
    [switch]$Delete = $false
)

$context = Set-AzContext -SubscriptionId $SubscriptionId

$resourceGroup = "$Prefix-rg"
$app = "$Prefix-app"

If ($Delete) {
	Remove-AzResourceGroup -Name $resourceGroup
	return
}

$admin = Get-AzADUser -UserPrincipalName $context.Account

New-AzResourceGroup -Name $resourceGroup -Location uksouth -Force
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroup -TemplateFile "ManagedIdentityRepro.bicep" -prefix $Prefix -adminId $admin.id -adminUserPrincipalName $admin.userPrincipalName

$accessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -ServerInstance "managedidentityrepro-sql.database.windows.net" -Database "managedidentityrepro-sqldb" -AccessToken $accessToken -Query @"
DROP USER IF EXISTS [$app]
CREATE USER [$app] FROM EXTERNAL PROVIDER
ALTER ROLE db_datareader ADD MEMBER [$app]
ALTER ROLE db_datawriter ADD MEMBER [$app]
"@

dotnet publish "ManagedIdentityRepro.Api" -c Release

$zipPath = "$PSScriptRoot\ManagedIdentityRepro.Api\bin\Release\net8.0\publish.zip"
Compress-Archive -Path "$PSScriptRoot\ManagedIdentityRepro.Api\bin\Release\net8.0\publish\*" $zipPath -Force

Publish-AzWebApp -ArchivePath $zipPath -ResourceGroupName $resourceGroup -Name $app -Force
