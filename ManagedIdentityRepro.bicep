param prefix string
param adminId string
param adminUserPrincipalName string

param location string = resourceGroup().location

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
    name: '${prefix}-asp'
    location: location
}

resource appService 'Microsoft.Web/sites@2022-09-01' = {
    name: '${prefix}-app'
    location: location
    identity: {
        type: 'SystemAssigned'
    }
    properties: {
        serverFarmId: appServicePlan.id
        siteConfig: {
            localMySqlEnabled: false
            netFrameworkVersion: 'v8.0'
            metadata: [
                { name: 'CURRENT_STACK', value: 'dotnet' }
            ]
        }
    }
}

resource sqlServer 'Microsoft.Sql/servers@2023-02-01-preview' = {
    name: '${prefix}-sql'
    location: location
    properties: {
        minimalTlsVersion: '1.2'
        administrators: {
            principalType: 'Group'
            administratorType: 'ActiveDirectory'
            login: adminUserPrincipalName
            sid: adminId
            tenantId: tenant().tenantId
            azureADOnlyAuthentication: true
        }
    }
}

resource sqlServerAllowAzureRule 'Microsoft.Sql/servers/firewallRules@2020-11-01-preview' = {
    name: 'AllowAllWindowsAzureIps'
    parent: sqlServer
    properties: {
        startIpAddress: '0.0.0.0'
        endIpAddress: '255.255.255.255'
    }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
    parent: sqlServer
    name: '${prefix}-sqldb'
    location: location
}

output appServicePrincipalId string = appService.identity.principalId
