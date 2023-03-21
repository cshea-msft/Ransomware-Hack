param resourceGroupName string
param location string
param tags object


targetScope = 'subscription'


resource rg_law 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
} 
