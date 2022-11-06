// Parameters

@description('Name of the Bastion host')
param name string

@description('Location of the Bastion host')
param location string

@allowed([
  'Basic'
  'Standard'
])
@description('SKU of the Bastion host')
param sku string

@description('ID of the Bastions subnet')
param subnet_id string

@description('Name of Bastions public ip')
param pip_name string

@description('Location of Bastions public ip')
param pip_location string

@allowed([
  'Basic'
  'Standard'
])
@description('SKU name of Bastions public ip')
param pip_sku_name string

@allowed([
  'Static'
  'Dynamic'
])
@description('SKU of Bastions public ip')
param pip_allocation_method string

// Resources

resource pip_bastion 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: pip_name
  location: pip_location
  sku: {
    name: pip_sku_name
  }
  properties: {
    publicIPAllocationMethod: pip_allocation_method
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ip-configuration'
        properties: {
          subnet: {
            id: subnet_id
          }
          publicIPAddress: {
            id: pip_bastion.id
          }
        }
      }
    ]
  }
}

// Outputs

output bastion_id string = bastion.id
