// Parameters

@description('Name of the vm')
param name string

@description('Location of the vm')
param location string

@description('Size of the vm')
param size string

@description('Publisher of the image')
param image_publisher string

@description('Specifies the offer of the platform image or marketplace image used to create the vm')
param image_offer string

@description('SKU of the image')
param image_sku string

@description('Specifies the version of the platform image or marketplace image used to create the vm')
param image_version string = 'latest'

@description('Username for vm admin')
param admin_username string

@description('Password for vm admin')
@secure()
param admin_password string

@description('Name of the vm nic')
param nic_name string

@description('Location of the vm nic')
param nic_location string

@description('ID of the jumpbox subnet')
param jumpbox_subnet_id string

// Resources

resource nic 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: nic_name
  location: nic_location
  properties: {
    ipConfigurations: [
      {
        name: 'nic-vm-ip-configuration'
        properties: {
          subnet: {
            id: jumpbox_subnet_id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: size
    }

    storageProfile: {
      osDisk: {
        osType: 'Linux'
        name: '${name}_OsDisk_1'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        deleteOption: 'Delete'
        diskSizeGB: 100
      }
      dataDisks: []
      imageReference: {
        publisher: image_publisher
        offer: image_offer
        sku: image_sku
        version: image_version
      }
    }

    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }

    osProfile: {
      computerName: name
      adminUsername: admin_username
      adminPassword: admin_password

      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
      allowExtensionOperations: true

      customData: loadFileAsBase64('../../.github/scripts/setup_jumpbox.tpl')
    }

    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// Outputs

output vm_id string = vm.id
output vm_identity_principal_id string = vm.identity.principalId
