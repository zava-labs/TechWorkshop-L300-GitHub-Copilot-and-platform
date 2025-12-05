// Azure Container Registry module
// Creates an ACR instance for storing Docker container images
@description('The name of the Container Registry')
param name string

@description('The location for the Container Registry')
param location string = resourceGroup().location

@description('The SKU of the Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Tags to apply to the Container Registry')
param tags object = {}

@description('Enable admin user (not recommended for production)')
param adminUserEnabled bool = false

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
  }
}

@description('The resource ID of the Container Registry')
output id string = containerRegistry.id

@description('The name of the Container Registry')
output name string = containerRegistry.name

@description('The login server of the Container Registry')
output loginServer string = containerRegistry.properties.loginServer
