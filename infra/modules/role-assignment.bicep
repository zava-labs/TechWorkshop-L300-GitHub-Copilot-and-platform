// Role Assignment module
// Assigns RBAC roles to managed identities
@description('The principal ID to assign the role to')
param principalId string

@description('The role definition ID (GUID) to assign')
param roleDefinitionId string

@description('The principal type')
@allowed([
  'ServicePrincipal'
  'User'
  'Group'
])
param principalType string = 'ServicePrincipal'

// Use existing resource for role assignment scope
// The parent resource (e.g., Container Registry) should be passed from main template
@description('The scope at which to assign the role')
param scope string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, roleDefinitionId, scope)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}

@description('The resource ID of the role assignment')
output id string = roleAssignment.id
