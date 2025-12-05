// Main Bicep template
// Orchestrates deployment of ZavaStorefront infrastructure
targetScope = 'resourceGroup'

@description('The environment name (e.g., dev, staging, prod)')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environmentName string = 'dev'

@description('The Azure region for all resources')
param location string = 'westus3'

@description('The base name for all resources')
param applicationName string = 'zavastore'

@description('The Docker image and tag to deploy')
param dockerImageAndTag string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Container Registry SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param containerRegistrySku string = 'Basic'

@description('App Service Plan SKU')
@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
])
param appServicePlanSku string = 'B1'

// Generate consistent resource names
var resourceToken = uniqueString(resourceGroup().id)
var acrName = 'acr${applicationName}${environmentName}${resourceToken}'
var appServicePlanName = 'asp-${applicationName}-${environmentName}'
var webAppName = 'app-${applicationName}-${environmentName}'
var appInsightsName = 'appi-${applicationName}-${environmentName}'
var aiServicesName = 'ai-${applicationName}-${environmentName}'

// Common tags for all resources
var tags = {
  Environment: environmentName
  Application: applicationName
  ManagedBy: 'Bicep'
}

// AcrPull role definition ID
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

// Cognitive Services OpenAI User role definition ID
var cognitiveServicesOpenAIUserId = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'

// Deploy Container Registry
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'containerRegistry'
  params: {
    name: acrName
    location: location
    sku: containerRegistrySku
    tags: tags
    adminUserEnabled: false
  }
}

// Deploy App Service Plan
module appServicePlan 'modules/app-service-plan.bicep' = {
  name: 'appServicePlan'
  params: {
    name: appServicePlanName
    location: location
    skuName: appServicePlanSku
    tags: tags
  }
}

// Deploy Application Insights
module appInsights 'modules/app-insights.bicep' = {
  name: 'appInsights'
  params: {
    name: appInsightsName
    location: location
    tags: tags
    applicationType: 'web'
  }
}

// Deploy Web App
module webApp 'modules/web-app.bicep' = {
  name: 'webApp'
  params: {
    name: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    dockerImageAndTag: dockerImageAndTag
    appInsightsConnectionString: appInsights.outputs.connectionString
    tags: tags
    serviceName: 'web'
  }
}

// Assign AcrPull role to Web App's managed identity
module acrPullRoleAssignment 'modules/role-assignment.bicep' = {
  name: 'acrPullRoleAssignment'
  params: {
    principalId: webApp.outputs.principalId
    roleDefinitionId: acrPullRoleId
    principalType: 'ServicePrincipal'
    scope: containerRegistry.outputs.id
  }
}

// Deploy Azure AI Services with gpt-4o-mini model
module aiServices 'modules/ai-services.bicep' = {
  name: 'aiServices'
  params: {
    name: aiServicesName
    location: location
    tags: tags
    sku: 'S0'
    deployments: [
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
  }
}

// Assign Cognitive Services OpenAI User role to Web App for AI access
module aiServicesRoleAssignment 'modules/role-assignment.bicep' = {
  name: 'aiServicesRoleAssignment'
  params: {
    principalId: webApp.outputs.principalId
    roleDefinitionId: cognitiveServicesOpenAIUserId
    principalType: 'ServicePrincipal'
    scope: aiServices.outputs.id
  }
}

// Outputs for reference and CI/CD pipelines
@description('The name of the Container Registry')
output containerRegistryName string = containerRegistry.outputs.name

@description('The login server of the Container Registry')
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer

@description('The name of the Web App')
output webAppName string = webApp.outputs.name

@description('The URL of the Web App')
output webAppUrl string = 'https://${webApp.outputs.defaultHostname}'

@description('The name of Application Insights')
output appInsightsName string = appInsights.outputs.name

@description('The resource group name')
output resourceGroupName string = resourceGroup().name

@description('The name of the AI Services resource')
output aiServicesName string = aiServices.outputs.name

@description('The endpoint of the AI Services resource')
output aiServicesEndpoint string = aiServices.outputs.endpoint
