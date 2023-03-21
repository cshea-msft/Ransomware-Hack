//Create Log Analytics Workspace and Log Analytics Solution for Sentinel

param lawName string
param location string


//Create Log Analytics Workspace
resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: lawName
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}


//Create resource to onboard Sentinel to Log Analytics Workspace
resource sentinel 'Microsoft.SecurityInsights/onboardingStates@2023-02-01-preview' = {
  name: 'default'
  scope: law
  dependsOn: [
    law
  ]
}


//Outputs
output resourceId string = law.id
