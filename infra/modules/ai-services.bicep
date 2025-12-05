// Azure AI Services module for deploying AI models
// Includes Azure OpenAI/AI Services with model deployments

@description('The name of the Azure AI Services resource')
param name string

@description('The Azure region for the resource')
param location string

@description('Tags for the resource')
param tags object = {}

@description('The SKU for the AI Services resource')
@allowed([
  'S0'
])
param sku string = 'S0'

@description('The model deployments to create')
param deployments array = [
  {
    name: 'gpt-4o-mini'
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: '2024-07-18'
    }
    sku: {
      name: 'Standard'
      capacity: 8
    }
  }
]

// Azure AI Services resource
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// Model deployments
@batchSize(1)
resource modelDeployments 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = [for deployment in deployments: {
  parent: aiServices
  name: deployment.name
  sku: deployment.sku
  properties: {
    model: deployment.model
    raiPolicyName: 'Microsoft.DefaultV2'
  }
}]

@description('The endpoint URL of the AI Services resource')
output endpoint string = aiServices.properties.endpoint

@description('The name of the AI Services resource')
output name string = aiServices.name

@description('The resource ID of the AI Services resource')
output id string = aiServices.id

@description('The principal ID for managed identity')
output principalId string = ''
