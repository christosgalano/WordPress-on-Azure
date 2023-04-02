// Parameters

@description('Name of the WebTest')
param name string

@description('Location of the WebTest')
param location string

@description('Kind of the WebTest')
@allowed([
  'standard'
])
param kind string

@description('Url location to test')
param app_url string

@description('Seconds until this WebTest will timeout and fail')
param timeout int = 30

@description('Is the test actively being monitored')
param enabled bool

@description('Interval in seconds between test runs for this WebTest')
param frequency int = 300

@description('Checks to see if the SSL cert is still valid')
param ssl_check bool

@description('A list of where to physically run the tests from to give global coverage for accessibility of your application')
param location_ids array

@description('Allow for retries should this WebTest fail')
param retry_enabled bool

@description('Description of the WebTest')
param test_description string

@description('When set, validation will ignore the status code')
param ignore_http_status_code bool

@description('ID of the subscription where the Application Insights resource resides')
param subscription_id string

@description('Name of the resource group where the Application Insights resource resides')
param rg_name string

@description('Name of the Application Insights resource')
param app_insights_name string

// Resource

resource web_test 'Microsoft.Insights/webtests@2022-06-15' = {
  name: name
  location: location
  kind: kind
  tags: {
    'hidden-link:/subscriptions/${subscription_id}/resourceGroups/${rg_name}/providers/microsoft.insights/components/${app_insights_name}': 'Resource'
  }
  properties: {
    Kind: kind
    Name: name

    Timeout: timeout
    Enabled: enabled
    Frequency: frequency
    Description: test_description
    RetryEnabled: retry_enabled
    SyntheticMonitorId: '${name}-id'

    Locations: [for id in location_ids: {
      Id: id
    }]

    Request: {
      RequestUrl: app_url
      HttpVerb: 'GET'
    }
    ValidationRules: {
      ExpectedHttpStatusCode: 200
      IgnoreHttpStatusCode: ignore_http_status_code
      SSLCheck: ssl_check
    }
  }
}

// Outputs

output web_test_id string = web_test.id
