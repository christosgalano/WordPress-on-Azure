// Parameters

@description('Name of the Application Insights')
param name string

@description('Location of the Application Insights')
param location string

@allowed([
  'web'
  'ios'
  'other'
  'store'
  'java'
  'phone'
])
@description('The kind of application that this component refers to, used to customize UI')
param kind string

@allowed([
  'web'
  'other'
])
@description('Type of application being monitored')
param application_type string

@description('Resource Id of the log analytics workspace which the data will be ingested to')
param log_workspace_id string

// Resources

resource application_insights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  kind: kind
  properties: {
    Application_Type: application_type
    WorkspaceResourceId: log_workspace_id
  }
}

// Outputs

output app_insights_id string = application_insights.id
output app_insights_name string = application_insights.name
output app_insights_key string = application_insights.properties.InstrumentationKey
