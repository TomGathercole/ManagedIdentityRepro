Param (
    [Parameter(Mandatory = $true)] $SubscriptionId,
    $Prefix = "managedidentityrepro"
)

$context = Set-AzContext -SubscriptionId $SubscriptionId

$resourceGroup = "$Prefix-rg"
$app = "$Prefix-app"
$baseUrl = "https://$app.azurewebsites.net"

foreach ($async in @($false, $true)) {
	foreach ($threads in @(1, 2, 4, 8, 16, 32)) {
		
		# Restart the app and wait for 1min to make sure it's really restarted
		Restart-AzWebApp -ResourceGroupName $resourceGroup -Name $app | Out-Null
		Start-Sleep -Seconds 60
		
		Write-Output (Invoke-RestMethod "${baseUrl}?async=$async&threads=$threads")
	}
}
