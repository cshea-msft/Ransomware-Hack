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
    lawId: law.outputs.resourceId
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


//Create Analytics
module analytics './Modules/analytics.bicep' = {
  name: 'analyticsDeployment'
  params: {
    lawName: lawName
    resourceGroupName: resourceGroupName
    tags: tags
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    alerts
  ]
}


//Outputs
output lawId string = law.outputs.resourceId

