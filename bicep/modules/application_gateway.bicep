// Parameters

@description('Name of the Application Gateway')
param name string

@description('Location of the Application Gateway')
param location string

@allowed([
  'WAF_v2'
  'Standard_v2'
])
@description('SKU name of the Application Gateway')
param sku_name string

@allowed([
  'WAF'
  'WAF_v2'
  'Standard'
  'Standard_v2'
])
@description('SKU tier of the Application Gateway')
param sku_tier string

@description('Subnet of the Application Gateway')
param subnet_id string

@description('Name of WebApp which will be added as backend pool')
param webapp_name string

@description('Name of Application Gateways public ip')
param pip_name string

@description('Location of Application Gateways public ip')
param pip_location string

@allowed([
  'Basic'
  'Standard'
])
@description('SKU name of Application Gateways public ip')
param pip_sku_name string

@allowed([
  'Static'
  'Dynamic'
])
@description('SKU of Application Gateways public ip')
param pip_allocation_method string

@description('Minimum instances of Application Gateway')
param min_instances int

@description('Maximum instances of Application Gateway')
param max_instances int

// Variables

var frontend_port = 80
var frontend_port_name = 'port_80'

var public_frontend_ip_config_name = 'app-gateway-public-ip-config'
var private_frontend_ip_config_name = 'app-gateway-private-ip-config'
var frontend_private_ip = '10.0.1.24'

var public_http_listener_name = 'public-http-listener'

var bp_name = 'bp-webapp'
var bp_settings_name = 'http-setting-to-webapp-override-hostname'

var rule_priority = 200
var rule_name = 'public-http-to-webapp-https'

var gateway_id = resourceId('Microsoft.Network/applicationGateways', '${name}')

// Resources

resource pip_gateway 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: pip_name
  location: pip_location
  sku: {
    name: pip_sku_name
  }
  properties: {
    publicIPAllocationMethod: pip_allocation_method
  }
}

resource gateway 'Microsoft.Network/applicationGateways@2022-01-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: sku_name
      tier: sku_tier
    }
    gatewayIPConfigurations: [
      {
        name: 'app-gateway-ip-config'
        properties: {
          subnet: {
            id: subnet_id
          }
        }
      }
    ]
    sslCertificates: []
    trustedRootCertificates: []
    trustedClientCertificates: []
    sslProfiles: []
    frontendIPConfigurations: [
      {
        name: public_frontend_ip_config_name
        properties: {
          publicIPAddress: {
            id: pip_gateway.id
          }
        }
      }
      {
        name: private_frontend_ip_config_name
        properties: {
          privateIPAddress: frontend_private_ip
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnet_id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: frontend_port_name
        properties: {
          port: frontend_port
        }
      }
    ]
    backendAddressPools: [
      {
        name: bp_name
        properties: {
          backendAddresses: [
            {
              fqdn: '${webapp_name}.azurewebsites.net'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: bp_settings_name
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: public_http_listener_name
        properties: {
          frontendIPConfiguration: {
            id: '${gateway_id}/frontendIPConfigurations/${public_frontend_ip_config_name}'
          }
          frontendPort: {
            id: '${gateway_id}/frontendPorts/${frontend_port_name}'
          }
          protocol: 'Http'
          hostNames: []
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: rule_name
        properties: {
          ruleType: 'Basic'
          priority: rule_priority
          httpListener: {
            id: '${gateway_id}/httpListeners/${public_http_listener_name}'
          }
          backendAddressPool: {
            id: '${gateway_id}/backendAddressPools/${bp_name}'
          }
          backendHttpSettings: {
            id: '${gateway_id}/backendHttpSettingsCollection/${bp_settings_name}'
          }
        }
      }
    ]
    probes: []
    rewriteRuleSets: []
    redirectConfigurations: []
    enableHttp2: false
    autoscaleConfiguration: {
      minCapacity: min_instances
      maxCapacity: max_instances
    }
  }
}
