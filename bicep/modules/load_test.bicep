// Parameters

@description('Name of the Load Test')
param name string

@description('Location of the Load Test')
param location string

@description('Description of the Load Test')
param test_description string

// Resource

resource load_test 'Microsoft.LoadTestService/loadTests@2022-12-01' = {
  name: name
  location: location
  properties: {
    description: test_description
  }
}

// Outputs

output load_test_id string = load_test.id
