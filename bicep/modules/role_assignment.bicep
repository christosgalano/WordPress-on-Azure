// Parameters

@description('The ID of the Principal (User, Group or Service Principal) to assign the Role Definition to')
param principal_id string

// Variables

@allowed([
  'Owner'
  'Contributor'
  'Reader'
  'AcrPush'
  'AcrPull'
  'NetworkContributor'
])
@description('Built-in role to assign')
param built_in_role_type string

var role = {
  Owner: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  Contributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  Reader: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'

  NetworkContributor: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'

  AcrPush: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/8311e382-0749-4cb8-b61a-304f252e45ec'
  AcrPull: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

// Resources

resource role_assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principal_id, role[built_in_role_type])
  properties: {
    principalId: principal_id
    roleDefinitionId: role[built_in_role_type]
  }
}
