// Parameters

@description('Name of the container registry')
param name string

@description('Location of the container registry')
param location string

@allowed([
  'Premium'
  'Standard'
])

@description('SKU of the container registry')
param sku string

@description('Specifies whether the admin user is enabled')
param admin_enabled bool

@allowed([
  'Enabled'
  'Disabled'
])
@description('Property to specify whether the registry will accept traffic from public internet')
param public_network_access string

@allowed([
  'Enabled'
  'Disabled'
])
@description('Specifies whether or not zone redundancy is enabled for this container registry')
param zone_redundancy string

@description('ID of the virtual network to which the private dns zone will be linked')
param vnet_id string

@description('Name of the container registry private endpoint')
param pep_name string

@description('Location of the container registry private endpoint')
param pep_location string

@description('ID of the subnet where the private endpoint will reside')
param pep_subnet_id string

// Variables

var name_cleaned = replace(name, '-', '')
var private_dns_zone_name = 'privatelink.azurecr.io'

// Resources

resource cr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: name_cleaned
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: admin_enabled
    publicNetworkAccess: public_network_access
    zoneRedundancy: zone_redundancy
  }
}

resource private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: private_dns_zone_name
  location: 'global'
}

resource private_dns_zone_vnet_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: private_dns_zone
  name: 'private-dns-vnet-link-${name}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet_id
    }
  }
}

resource pep_cr 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: pep_name
  location: pep_location
  properties: {
    privateLinkServiceConnections: [
      {
        name: pep_name
        properties: {
          groupIds: [
            'registry'
          ]
          privateLinkServiceId: cr.id
        }
      }
    ]
    subnet: {
      id: pep_subnet_id
    }
  }
}

resource private_dns_zone_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  parent: pep_cr
  name: 'registry-private-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'registry-private-dns-zone-config'
        properties: {
          privateDnsZoneId: private_dns_zone.id
        }
      }
    ]
  }
}

// Outputs

output registry_id string = cr.id
output registry_name string = cr.name
