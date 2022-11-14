// Parameters

@minLength(3)
@maxLength(24)
@description('Name of the key vault')
param name string

@description('Location of the key vault')
param location string

@allowed([
  'premium'
  'standard'
])
@description('SKU name of the key vault')
param sku_name string

@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from this key vault')
param enabled_for_template_deployment bool

@description('Specifies whether Purge Protection is enabled for this key vault')
param purge_protection_enabled bool

@description('Property to specify whether the soft delete functionality is enabled for this key vault')
param soft_delete_enabled bool

@description('Object id of the jumpbox identity')
param jumpbox_identity_object_id string

@description('Object id of the github runner service principal')
param github_runner_object_id string

@description('Object id of the webapp identity')
param webapp_identity_object_id string

@description('ID of the virtual network to which the private dns zone will be linked')
param vnet_id string

@description('Name of the key vault private endpoint')
param pep_name string

@description('Location of the key vault private endpoint')
param pep_location string

@description('ID of the subnet where the private endpoint will reside')
param pep_subnet_id string

@secure()
@description('Password of jumpbox admin')
param jumpbox_admin_password_secret_value string

@description('Secret name for password of jumpbox admin')
#disable-next-line secure-secrets-in-params
param jumpbox_admin_password_secret_name string

@secure()
@description('Password of mysql admin')
param mysql_admin_password_secret_value string

@description('Secret name for password of mysql admin')
#disable-next-line secure-secrets-in-params
param mysql_admin_password_secret_name string

// Variables

var private_dns_zone_name = 'privatelink.vaultcore.azure.net'

// Resources

resource keyvault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  properties: {
    sku: {
      family: 'A'
      name: sku_name
    }
    tenantId: subscription().tenantId

    enabledForTemplateDeployment: enabled_for_template_deployment
    enablePurgeProtection: purge_protection_enabled

    enableSoftDelete: soft_delete_enabled

    networkAcls: {
      bypass: enabled_for_template_deployment ? 'AzureServices' : 'None'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }

    accessPolicies: [
      {
        objectId: jumpbox_identity_object_id
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
          ]
        }
      }
      {
        objectId: github_runner_object_id
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
          ]
        }
      }
      {
        objectId: webapp_identity_object_id
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

resource secret_jumpbox_admin_password 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyvault
  name: jumpbox_admin_password_secret_name
  properties: {
    value: jumpbox_admin_password_secret_value
  }
}

resource secret_mysql_admin_password 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyvault
  name: mysql_admin_password_secret_name
  properties: {
    value: mysql_admin_password_secret_value
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

resource pep_kv 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: pep_name
  location: pep_location
  properties: {
    privateLinkServiceConnections: [
      {
        name: pep_name
        properties: {
          groupIds: [
            'vault'
          ]
          privateLinkServiceId: keyvault.id
        }
      }
    ]
    subnet: {
      id: pep_subnet_id
    }
  }
}

resource private_dns_zone_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  parent: pep_kv
  name: 'vault-private-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'vault-private-dns-zone-config'
        properties: {
          privateDnsZoneId: private_dns_zone.id
        }
      }
    ]
  }
}
