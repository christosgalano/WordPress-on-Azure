targetScope = 'subscription'

// Parameters

@description('Name of the resource group')
param name string

@description('Location of the resource group')
param location string

// Resources

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: name
  location: location
}

// Outputs

output rg_id string = rg.id
output rg_name string = rg.name
