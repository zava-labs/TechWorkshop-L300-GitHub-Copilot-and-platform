// Parameters file for ZavaStorefront dev environment
using './main.bicep'

param environmentName = 'dev'
param location = 'westus3'
param applicationName = 'zavastore'
param containerRegistrySku = 'Basic'
param appServicePlanSku = 'B1'
param dockerImageAndTag = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
