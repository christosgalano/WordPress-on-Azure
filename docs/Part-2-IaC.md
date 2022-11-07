# WordPress on Azure: Part 2 - IaC

Hello, fellow Azure-enthusiasts! In today’s blog post we examine the code that will be used to deploy our [infrastructure](Part-1-Architecture.md).

Bicep is being used for the IaC; all the templates/modules are available in the **bicep/** folder.

We are not going to delve into every single one of the modules; instead, we are going to focus on some important and noteworthy aspects.

## WebApp

<details>
  <summary>Code</summary>

```bicep
resource webapp 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    virtualNetworkSubnetId: subnet_id
    vnetRouteAllEnabled: true
    vnetImagePullEnabled: true
    vnetContentShareEnabled: true
    siteConfig: {
      acrUseManagedIdentityCreds: true
      alwaysOn: always_on
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'WEBSITE_PULL_IMAGE_OVER_VNET'
          value: 'true'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: 'true'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: app_insights_key
        }
        {
          name: 'WORDPRESS_DB_NAME'
          value: wordpress_db_name
        }
        {
          name: 'WORDPRESS_DB_HOST'
          value: mysql_host_name
        }
        {
          name: 'WORDPRESS_DB_USER'
          value: mysql_admin_username
        }
        {
          name: 'WORDPRESS_DB_PASSWORD'
          value: '@Microsoft.KeyVault(SecretUri=https://${kv_name}.vault.azure.net/secrets/${mysql_admin_password_secret_name}/)'
        }
        {
          name: 'MYSQL_SSL_CA'
          value: '/home/site/wwwroot/bin/DigiCertGlobalRootCA.crt.pem'
        }
        {
          name: 'WORDPRESS_CONFIG_EXTRA'
          value: 'define( \'MYSQL_CLIENT_FLAGS\', MYSQLI_CLIENT_SSL | MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT ); define(\'MYSQL_SSL_CA\', getenv(\'MYSQL_SSL_CA\') );'
        }
      ]
      linuxFxVersion: 'DOCKER|${registry_name}.azurecr.io/${image_name}:latest'
    }
    serverFarmId: app_service_plan_id
  }
}
```

</details>

Here we need to be careful in enabling some options.

First, setting **vnetRouteAllEnabled** to **true** assures that the WebApp's outbound traffic will flow through the virtual network.

Next, both the **vnetImagePullEnabled** and the **acrUseManagedIdentityCreds** options must be set to **true**. By doing this, we allow our WebApp to pull the WordPress  image from the ACR using its system-assigned identity.

Lastly, we need to create the necessary configuration settings regarding the database:

* WORDPRESS_DB_NAME, WORDPRESS_DB_HOST, WORDPRESS_DB_USER
* WORDPRESS_DB_PASSWORD (keyvault reference using system-assigned identity)
* MYSQL_SSL_CA is the path to the DB certificate (the steps to download and store the certificate will be in Part 3)
* WORDPRESS_CONFIG_EXTRA with some extra options in order to use the certificate and enforce SSL

## MySQL Server

<details>
  <summary>Code</summary>

```bicep
var private_dns_zone_name = '${name}.private.mysql.database.azure.com'

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
```

</details>

We create a private DNS zone and link it to the vnet.

Afterwards, we create the flexible server, which has a delegated subnet (vnet integration).

Because the application expects a pre-existing database with the name *wordpress*, we create it.

## Private DNS Zone and Private Endpoint for the ACR

<details>
<summary>Code</summary>

```bicep
var private_dns_zone_name = 'privatelink.azurecr.io'

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

resource ple_cr 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: ple_name
  location: ple_location
  properties: {
    privateLinkServiceConnections: [
      {
        name: ple_name
        properties: {
          groupIds: [
            'registry'
          ]
          privateLinkServiceId: cr.id
        }
      }
    ]
    subnet: {
      id: ple_subnet_id
    }
  }
}

resource private_dns_zone_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  parent: ple_cr
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
```

</details>

Firstly, we create a private DNS zone and then link it to the vnet.

Then we create the private endpoint and create the appropriate zone group in the newly created DNS zone.

I strongly suggest that you use the **parent** element in order to avoid [resolve errors](https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/error-parent-resource?tabs=bicep).

## Identity

<details>
  <summary>Code</summary>

```bicep
resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: name
  location: location
}

output identity_resource_id string = identity.id
output identity_client_id string = identity.properties.clientId
output identity_principal_id string = identity.properties.principalId
```

</details>

The important thing here is to export all the values that are necessary to perform a role assignment later on.

## Role assignment

<details>
  <summary>Code</summary>

```bicep
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

resource role_assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principal_id, role[built_in_role_type])
  properties: {
    principalId: principal_id
    roleDefinitionId: role[built_in_role_type]
  }
}
```

</details>

Here, we only allow a certain list of roles to be assigned.

We use the friendly role name and then reference the role id using the variable *role*.

## Summary

That about sums up the code modules. In the following part, we will deploy our infrastructure and execute some post-configuration tasks.

**Next part:**

* [**Part 3: Deployment**](Part-3-Deployment.md)

**Previous parts:**

* [**Part 0: Introduction**](Part-0-Introduction.md)

* [**Part 1: Architecture**](Part-1-Architecture.md)
