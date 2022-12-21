targetScope = 'subscription'

/// Parameters ///

@description('ID of the subscription')
param subscription_id string

@description('Azure region used for the deployment of all resources')
param location string

@description('Abbreviation fo the location')
param location_abbreviation string

@description('Name of the workload that will be deployed')
param workload string

@description('Name of the workloads environment')
param environment string

@description('Tags to be applied on the resource group')
param rg_tags object = {}

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

/// Variables ///

var tags = union({
    workload: workload
    environment: environment
  }, rg_tags)

/// Modules & Resources ///

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${workload}-${environment}-${location_abbreviation}'
  location: location
  tags: tags
}

// AzNames module deployment - this will generate all the names of the resources at deployment time.
module aznames 'modules/aznames.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aznames-deployment'
  params: {
    suffixes: [
      workload
      environment
      location_abbreviation
    ]
    uniquifierLength: 3
    uniquifier: rg.id
    useDashes: true
  }
}

// Main module deployment
module main 'main.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'workload-deployment'
  params: {
    subscription_id: subscription_id
    aznames: aznames.outputs.names
    rg_name: rg.name

    location: location
    location_abbreviation: location_abbreviation

    workload: workload
    environment: environment

    github_runner_object_id: github_runner_object_id

    jumpbox_admin_username: jumpbox_admin_username
    jumpbox_admin_password: jumpbox_admin_password

    mysql_admin_username: mysql_admin_username
    mysql_admin_password: mysql_admin_password
  }
}
