// Parameters

@description('Name of the WebApp')
param name string

@description('Location of the WebApp')
param location string

@description('Subnet of the WebApp for vnet integration')
param subnet_id string

@description('Name of the registry in which the container image resides')
param registry_name string

@description('Name of the container image that is going to be deployed through the Webapp')
param image_name string

@description('App Service Plan ID of the WebApp')
param app_service_plan_id string

@description('Instrumentation key for the Application Insights to be linked to')
param app_insights_key string

@description('Specifies whether always on is enabled')
param always_on bool

@description('Host name for MySQL server')
param mysql_host_name string

@description('Admin username for MySQL server')
param mysql_admin_username string

@description('Database name for wordpress')
param wordpress_db_name string = 'wordpress'

@description('Secret name for MySQL server admin password')
#disable-next-line secure-secrets-in-params
param mysql_admin_password_secret_name string

@description('Keyvault name')
param kv_name string

// Resources

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

// Outputs

output webapp_id string = webapp.id
output webapp_name string = webapp.name
output webapp_url string = webapp.properties.hostNames[0]
output webapp_identity_principal_id string = webapp.identity.principalId
