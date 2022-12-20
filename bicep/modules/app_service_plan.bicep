// Parameters

@description('Name of the App Service Plan')
param name string

@description('Location of the App Service Plan')
param location string

@description('SKU name of the App Service Plan')
param sku_name string

@allowed([
  'Basic'
  'Standard'
  'Premium'
  'Isolated'
])
@description('SKU tier of the App Service Plan')
param sku_tier string

@description('Kind of the App Service Plan')
param kind string

@description('Specifies whether the App Service Plan will perform availability zone balancing')
param zone_redundant bool

@description('Specifies whether the App Service Plan will be Linux (true) or Windows (false)')
param reserved bool

// Resources

resource app_service_plan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: name
  location: location
  sku: {
    name: sku_name
    tier: sku_tier
  }
  properties: {
    reserved: reserved
    zoneRedundant: zone_redundant
  }
  kind: kind
}

// Outputs

output app_service_plan_id string = app_service_plan.id
