// Application Insights module
// Creates an Application Insights instance for monitoring
@description('The name of the Application Insights instance')
param name string

@description('The location for Application Insights')
param location string = resourceGroup().location

@description('Tags to apply to Application Insights')
param tags object = {}

@description('The type of application being monitored')
@allowed([
  'web'
  'other'
])
param applicationType string = 'web'

// Log Analytics workspace for Application Insights
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${name}-logs'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: applicationType
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

@description('The resource ID of Application Insights')
output id string = appInsights.id

@description('The name of Application Insights')
output name string = appInsights.name

@description('The instrumentation key for Application Insights')
@secure()
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('The connection string for Application Insights')
@secure()
output connectionString string = appInsights.properties.ConnectionString
