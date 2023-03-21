var sharedNamePrefixes = loadJsonContent('./shared-prefixes.json')
var resourceGroupName = 'rg-law-${sharedNamePrefixes.prefix}-${sharedNamePrefixes.resourceLocation}'
var location = '${sharedNamePrefixes.resourceLocation}'
var tags = loadJsonContent('./shared-prefixes.json', 'tags')

var lawName = 'law-${sharedNamePrefixes.prefix}-${sharedNamePrefixes.resourceLocation}-1'

targetScope = 'subscription'

// Create resource group
module rg_law './Modules/resourceGroup.bicep' = {
  name: 'rgDeploy'
  params: {
    resourceGroupName: resourceGroupName
    location: location
    tags: tags
  }
}

// Create Log Analytics Workspace
module law './Modules/logAnalytics.bicep' = {
  name: 'lawDeployment'
  params: {
    lawName: lawName
    location: location
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    rg_law
  ]
}

//Create Data Connectors
module dataConnectors './Modules/connectors.bicep' = {
  name: 'dataConnectorsDeployment'
  params: {
    lawName: lawName
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    law
  ]
}


//Create Alerts
module alerts './Modules/alerts.bicep' = {
  name: 'alertsDeployment'
  params: {
    lawName: lawName
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    dataConnectors
  ]
}



//Outputs
output lawId string = law.outputs.resourceId

