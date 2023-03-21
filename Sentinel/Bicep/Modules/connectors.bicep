param lawName string

var getTenantId = subscription().tenantId


resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: lawName
}

//Create Data Connector for office 365
resource o365 'Microsoft.SecurityInsights/dataConnectors@2023-02-01-preview' = {
  name: 'office_365'
  scope: law
  kind: 'Office365'
  properties: {
    dataTypes: {
      exchange: {
        state: 'Enabled'
      }
      sharePoint: {
        state: 'Enabled'
      }
      teams: {
        state: 'Enabled'
      }
    }
    tenantId: getTenantId
  }
}


