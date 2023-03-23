param resourceGroupName string
param tags object
param lawName string


resource rg_template_deployment 'Microsoft.Resources/deployments@2022-09-01' = {
  name: 'rg_template_deployment'
  tags: tags
  properties: {
    mode: 'Incremental'
    parameters: {
      workspace: {
          value: lawName
      }
    }
    templateLink: {
      contentVersion: '1.0.0.0'
      uri: 'https://raw.githubusercontent.com/cshea15/Ransomware-Hack/main/Sentinel/Terraform/alerts.json'
    }
  }
  resourceGroup: resourceGroupName
}

