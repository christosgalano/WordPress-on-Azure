targetScope = 'subscription'

// Parameters

@description('ID of the subscription')
param subscription_id string

@minLength(2)
@maxLength(5)
@description('Project identifier that is going to be included in every resource name')
param project_id string

@description('Azure region used for the deployment of all resources')
param location string

@description('Username of the jumpbox admin')
param jumpbox_admin_username string

@description('Password of the jumpbox admin')
@secure()
param jumpbox_admin_password string

@description('Username of the mysql admin')
param mysql_admin_username string

@description('Password of the mysql admin')
@secure()
param mysql_admin_password string

@description('Object id of the github runner service principal')
param github_runner_object_id string

// Variables

var rg_name = 'rg-${project_id}'
var kv_name = 'kv-${project_id}'
var mysql_admin_password_secret_name = 'mysql-admin-password'

// Modules

module rg 'modules/resource_group.bicep' = {
  name: 'rg-${project_id}-deployment'
  params: {
    name: rg_name
    location: location
  }
}

module network 'modules/network.bicep' = {
  scope: resourceGroup(rg_name)
  name: 'network-${project_id}-deployment'
  params: {
    vnet_name: 'vnet-${project_id}'
    vnet_location: location
    vnet_address_space: [ '10.0.0.0/23' ]

    snet_ple_name: 'snet-ple-${project_id}'
    snet_ple_address_prefix: '10.0.0.0/27'

    snet_jumpbox_name: 'snet-jumpbox-${project_id}'
    snet_jumpbox_address_prefix: '10.0.0.32/27'

    snet_bastion_name: 'AzureBastionSubnet'
    snet_bastion_address_prefix: '10.0.0.64/27'

    snet_webapp_name: 'snet-webapp-${project_id}'
    snet_webapp_address_prefix: '10.0.0.96/27'

    snet_mysql_name: 'snet-mysql-${project_id}'
    snet_mysql_address_prefix: '10.0.0.128/27'
  }
  dependsOn: [
    rg
  ]
}

module log_workspace 'modules/log_workspace.bicep' = {
  scope: resourceGroup(rg_name)
  name: 'log-${project_id}-deployment'
  params: {
    name: 'log-${project_id}'
    location: location
    sku: 'PerGB2018'
  }
  dependsOn: [
    rg
  ]
}

module registry 'modules/registry.bicep' = {
  scope: resourceGroup(rg_name)
  name: 'cr-${project_id}-deployment'
  params: {
    name: 'cr${project_id}'
    location: location
    sku: 'Premium'

    admin_enabled: true
    public_network_access: 'Disabled'
    zone_redundancy: 'Disabled'

    ple_name: 'ple-cr-${project_id}'
    ple_location: location
    ple_subnet_id: network.outputs.snet_ple_id

    vnet_id: network.outputs.vnet_id
  }
}

module jumpbox 'modules/jumpbox.bicep' = {
  scope: resourceGroup(rg_name)
  name: 'jumpbox-${project_id}-deployment'
  params: {
    name: 'vm-jumpbox-${project_id}'
    location: location
    size: 'Standard_D2_v2'

    admin_username: jumpbox_admin_username
    admin_password: jumpbox_admin_password

    image_publisher: 'Canonical'
    image_offer: 'UbuntuServer'
    image_sku: '18.04-LTS'
    image_version: 'latest'

    nic_name: 'nic-vm-jumpbox-${project_id}'
    nic_location: location

    jumpbox_subnet_id: network.outputs.snet_jumpbox_id
  }
}

module contributor_role_assignment 'modules/role_assignment.bicep' = {
  scope: resourceGroup(rg_name)
  name: 'contributor-role-assignment-${project_id}-deployment'
  params: {
    built_in_role_type: 'Contributor'
    principal_id: jumpbox.outputs.vm_identity_principal_id
  }
}

module acrpush_role_assignment 'modules/role_assignment.bicep' = {
  scope: resourceGroup(rg_name)
  name: 'acrpush-role-assignment-${project_id}-deployment'
  params: {
    built_in_role_type: 'AcrPush'
    principal_id: jumpbox.outputs.vm_identity_principal_id
  }
}

module app_insights 'modules/application_insights.bicep' = {
  scope: resourceGroup(rg_name)
  name: 'appi-${project_id}-deployment'
  params: {
    name: 'appi-${project_id}'
    location: location
    kind: 'web'
    application_type: 'web'
    log_workspace_id: log_workspace.outputs.log_workspace_id
  }
}

module app_service_plan 'modules/app_service_plan.bicep' = {
  scope: resourceGroup(rg_name)
  name: 'plan-${project_id}-deployment'
  params: {
    name: 'plan-${project_id}'
    location: location

    kind: 'linux'

    sku_name: 'P1v2'
    sku_tier: 'Premium'

    reserved: true
    zone_redundant: false
  }
  dependsOn: [
    rg
  ]
}

module keyvault 'modules/keyvault.bicep' = {
  scope: resourceGroup(rg_name)
  name: 'kv-${project_id}-deployment'
  params: {
    name: kv_name
    location: location
    sku_name: 'standard'

    soft_delete_enabled: true
    purge_protection_enabled: true
    enabled_for_template_deployment: true

    jumpbox_admin_password_secret_name: 'jumpbox-admin-password'
    jumpbox_admin_password_secret_value: jumpbox_admin_password

    mysql_admin_password_secret_name: mysql_admin_password_secret_name
    mysql_admin_password_secret_value: mysql_admin_password

    github_runner_object_id: github_runner_object_id
    jumpbox_identity_object_id: jumpbox.outputs.vm_identity_principal_id
    webapp_identity_object_id: webapp.outputs.webapp_identity_principal_id

    ple_name: 'ple-kv-${project_id}'
    ple_location: location
    ple_subnet_id: network.outputs.snet_ple_id

    vnet_id: network.outputs.vnet_id
  }
}

module bastion 'modules/bastion.bicep' = {
  scope: resourceGroup(rg_name)
  name: 'bastion-${project_id}-deployment'
  params: {
    name: 'bastion-${project_id}'
    location: location
    sku: 'Standard'

    pip_name: 'pip-bastion-${project_id}'
    pip_location: location
    pip_sku_name: 'Standard'
    pip_allocation_method: 'Static'

    subnet_id: network.outputs.snet_bastion_id
  }
}

module mysql 'modules/mysql.bicep' = {
  scope: resourceGroup(rg_name)
  name: 'mysql-${project_id}-deployment'
  params: {
    name: 'mysql-${project_id}'
    location: location

    sku_name: 'Standard_D8ds_v4'
    sku_tier: 'GeneralPurpose'

    version: '8.0.21'

    admin_username: mysql_admin_username
    admin_password: mysql_admin_password

    backup_retention_days: 7
    geo_redundant_backup: 'Disabled'

    database_name: 'wordpress'
    database_charset: 'utf8mb4'
    database_collation: 'utf8mb4_0900_ai_ci'

    subnet_id: network.outputs.snet_mysql_id
    vnet_id: network.outputs.vnet_id
  }
}

module webapp 'modules/webapp.bicep' = {
  scope: resourceGroup(rg_name)
  name: 'app-${project_id}-deployment'
  params: {
    name: 'app-${project_id}'
    location: location

    subnet_id: network.outputs.snet_webapp_id

    always_on: true
    app_insights_key: app_insights.outputs.app_insights_key
    app_service_plan_id: app_service_plan.outputs.app_service_plan_id

    mysql_host_name: mysql.outputs.mysql_server_name
    mysql_admin_username: mysql_admin_username
    wordpress_db_name: 'wordpress'

    kv_name: kv_name
    mysql_admin_password_secret_name: mysql_admin_password_secret_name

    image_name: 'wordpress'
    registry_name: registry.outputs.registry_name
  }
}

module acrpull_role_assignment 'modules/role_assignment.bicep' = {
  scope: resourceGroup(rg_name)
  name: 'acrpull-role-assignment-${project_id}-deployment'
  params: {
    built_in_role_type: 'AcrPull'
    principal_id: webapp.outputs.webapp_identity_principal_id
  }
}

module web_test 'modules/web_test.bicep' = {
  scope: resourceGroup(rg_name)
  name: 'web-test-${project_id}-deployment'
  params: {
    name: 'test-wordpress-${app_insights.outputs.app_insights_name}'
    location: location
    kind: 'standard'
    test_description: 'Test the WordPress application'

    rg_name: rg_name
    subscription_id: subscription_id
    app_insights_name: app_insights.outputs.app_insights_name

    app_url: 'https://${webapp.outputs.webapp_url}'
    timeout: 30
    frequency: 300
    retry_enabled: true

    enabled: false
    ssl_check: true
    ignore_https_status_code: false

    location_ids: [
      'us-fl-mia-edge' // Central US
      'emea-nl-ams-azr' // West Europe
      'emea-gb-db3-azr' // North Europe
      'apac-sg-sin-azr' // Southeast Asia
      'emea-fr-pra-edge' // France Central
      'apac-jp-kaw-edge' // Japan East
      'emea-se-sto-edge' // UK West4
    ]
  }
}

module load_test 'modules/load_test.bicep' = {
  scope: resourceGroup(rg_name)
  name: 'load-test-${project_id}-deployment'
  params: {
    name: 'lt-${project_id}'
    location: location
    test_description: 'Load test the WordPress application'
  }
  dependsOn: [
    rg
  ]
}
