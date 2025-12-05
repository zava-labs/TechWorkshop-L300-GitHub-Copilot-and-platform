// Web App module
// Creates a Linux Web App for Containers with managed identity
@description('The name of the Web App')
param name string

@description('The location for the Web App')
param location string = resourceGroup().location

@description('The ID of the App Service Plan')
param appServicePlanId string

@description('The login server of the Container Registry')
param containerRegistryLoginServer string

@description('The Docker image and tag')
param dockerImageAndTag string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Application Insights connection string')
@secure()
param appInsightsConnectionString string = ''

@description('Tags to apply to the Web App')
param tags object = {}

@description('The service name for AZD deployment')
param serviceName string = 'web'

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  tags: union(tags, {
    'azd-service-name': serviceName
  })
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${dockerImageAndTag}'
      acrUseManagedIdentityCreds: true
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
      ]
    }
  }
}

@description('The resource ID of the Web App')
output id string = webApp.id

@description('The name of the Web App')
output name string = webApp.name

@description('The default hostname of the Web App')
output defaultHostname string = webApp.properties.defaultHostName

@description('The principal ID of the system-assigned managed identity')
output principalId string = webApp.identity.principalId
