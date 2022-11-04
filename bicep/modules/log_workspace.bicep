// Parameters

@description('Name of the log analytics workspace')
param name string

@description('Location of the log analytics workspace')
param location string

@description('SKU of the log analytics workspace')
param sku string

// Resources

resource log_workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: sku
    }
  }
}

// Outputs

output log_workspace_id string = log_workspace.id
