// Parameters

@description('Name of MySQL server')
param name string

@description('Location of MySQL server')
param location string

@description('SKU name of MySQL server')
param sku_name string

@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
@description('SKU tier of MySQL server')
param sku_tier string

@description('Admin username of MySQL server')
param admin_username string

@secure()
@description('Admin password of MySQL server')
param admin_password string

@allowed([
  '5.7'
  '8.0.21'
])
@description('Version of MySQL server')
param version string

@description('Backup retention days for the server')
param backup_retention_days int

@allowed([
  'Enabled'
  'Disabled'
])
@description('Specifies whether or not geo redundant backup is enabled')
param geo_redundant_backup string

@description('Delegated subnet resource id used to setup vnet for a server')
param subnet_id string

@description('ID of the virtual network to which the private dns zone will be linked')
param vnet_id string

@minLength(1)
@maxLength(63)
@description('Name of the database')
param database_name string

@description('Charset of the database')
param database_charset string

@description('Collation of the database')
param database_collation string

// Variables

var private_dns_zone_name = '${name}.private.mysql.database.azure.com'

// Resources

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

resource mysql 'Microsoft.DBforMySQL/flexibleServers@2021-12-01-preview' = {
  name: name
  location: location
  sku: {
    name: sku_name
    tier: sku_tier
  }
  properties: {
    administratorLogin: admin_username
    administratorLoginPassword: admin_password
    version: version
    backup: {
      backupRetentionDays: backup_retention_days
      geoRedundantBackup: geo_redundant_backup
    }
    network: {
      delegatedSubnetResourceId: subnet_id
      privateDnsZoneResourceId: private_dns_zone.id
    }
  }

  resource database 'databases' = {
    name: database_name
    properties: {
      charset: database_charset
      collation: database_collation
    }
  }

  dependsOn: [
    private_dns_zone_vnet_link
  ]
}

// Outputs

output mysql_name string = mysql.name
output mysql_server_name string = mysql.properties.fullyQualifiedDomainName
output mysql_server_admin_username string = mysql.properties.administratorLogin
