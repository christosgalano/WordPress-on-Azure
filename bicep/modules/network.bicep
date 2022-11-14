// Parameters

@description('Name of the virtual network')
param vnet_name string

@description('Location of the virtual network')
param vnet_location string

@description('Address space of the virtual network')
param vnet_address_space array

@description('Name of the subnet where the private endpoints will reside')
param snet_pep_name string

@description('Address space of the subnet where the private endpoints will reside')
param snet_pep_address_prefix string

@description('Name of the subnet where the Bastion host will reside')
param snet_bastion_name string = 'AzureBastionSubnet'

@description('Address space of the subnet where the Bastion host will reside')
param snet_bastion_address_prefix string

@description('Name of the subnet where the jumpbox vm will reside')
param snet_jumpbox_name string

@description('Address space of the subnet where the jumpbox vm will reside')
param snet_jumpbox_address_prefix string

@description('Name of the subnet where the WebApp integration will take place')
param snet_webapp_name string

@description('Address space of the subnet where the WebApp integration will take place')
param snet_webapp_address_prefix string

@description('Name of the subnet where the MySQL server integration will take place')
param snet_mysql_name string

@description('Address space of the subnet where the MySQL server integration will take place')
param snet_mysql_address_prefix string

// Resources

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnet_name
  location: vnet_location
  properties: {
    addressSpace: {
      addressPrefixes: vnet_address_space
    }
    subnets: [
      {
        name: snet_pep_name
        properties: {
          addressPrefix: snet_pep_address_prefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: snet_bastion_name
        properties: {
          addressPrefix: snet_bastion_address_prefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: snet_jumpbox_name
        properties: {
          addressPrefix: snet_jumpbox_address_prefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: snet_webapp_name
        properties: {
          addressPrefix: snet_webapp_address_prefix
          privateEndpointNetworkPolicies: 'Disabled'
          delegations: [
            {
              name: 'Microsoft.Web.serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: snet_mysql_name
        properties: {
          addressPrefix: snet_mysql_address_prefix
          privateEndpointNetworkPolicies: 'Disabled'
          delegations: [
            {
              name: 'dlg-Microsoft.DBforMySQL-flexibleServers'
              properties: {
                serviceName: 'Microsoft.DBforMySQL/flexibleServers'
              }
            }
          ]
        }
      }
    ]
  }
}

// Outputs

output vnet_id string = vnet.id
output snet_pep_id string = vnet.properties.subnets[0].id
output snet_bastion_id string = vnet.properties.subnets[1].id
output snet_jumpbox_id string = vnet.properties.subnets[2].id
output snet_webapp_id string = vnet.properties.subnets[3].id
output snet_mysql_id string = vnet.properties.subnets[4].id
