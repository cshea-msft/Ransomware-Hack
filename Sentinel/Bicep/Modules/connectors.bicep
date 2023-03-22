param lawName string
param lawId string

var getTenantId = subscription().tenantId
var getSubscriptionId = subscription().subscriptionId


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

// Create Data Connector for Azure Advanced Threat protection
// E5 License is required for this connector
/*
resource aad_advanced_threat_protection 'Microsoft.SecurityInsights/dataConnectors@2023-02-01-preview' = {
  name: 'azure_advanced_threat_protection'
  scope: law
  kind: 'AzureAdvancedThreatProtection'
  properties: {
     dataTypes: {
      alerts: {
        state: 'Enabled'
      }
    }
    tenantId: getTenantId
  }
}
*/


// Create Data Connector for Defender for Cloud
resource dfc 'Microsoft.SecurityInsights/dataConnectors@2023-02-01-preview' = {
  name: 'azure_security_center'
  scope: law
  kind: 'AzureSecurityCenter'
  properties: {
    dataTypes: {
      alerts: {
        state: 'Enabled'
      }
    }
    subscriptionId: getSubscriptionId
  }
}

// Create Data Connector for Azure Active Directory
resource aad 'Microsoft.SecurityInsights/dataConnectors@2023-02-01-preview' = {
  name: 'azure_active_directory'
  scope: law
  kind: 'AzureActiveDirectory'
  properties: {
    dataTypes: {
      alerts: {
        state: 'Enabled'
      }
    }
    tenantId: getTenantId
  }
}


/*
// Create Data Connector for Microsoft Cloud App Security
// E5 license is required for this connector
resource microsoft_cloud_app_security 'Microsoft.SecurityInsights/dataConnectors@2023-02-01-preview' = {
  name: 'microsoft_cloud_app_security'
  scope: law
  kind: 'MicrosoftCloudAppSecurity'
  properties: {
     dataTypes: {
      alerts: {
        state: 'Enabled'
      }
    }
    tenantId: getTenantId
  }
}
*/




// Create Data Connector for Microsoft Defender for Endpoint
resource microsoft_defender_advanced_threat_protection 'Microsoft.SecurityInsights/dataConnectors@2023-02-01-preview' = {
  name: 'microsoft_defender_advanced_threat_protection'
  scope: law
  kind: 'MicrosoftDefenderAdvancedThreatProtection'
  properties: {
     dataTypes: {
      alerts: {
        state: 'Enabled'
      }
    }
    tenantId: getTenantId
  }
}


/*
// Create Data Connector for Threat Intelligence Taxii
resource threat_intelligence_taxii 'Microsoft.SecurityInsights/dataConnectors@2023-02-01-preview' = {
  name: 'threat_intelligence_taxii'
  scope: law
  kind: 'ThreatIntelligenceTaxii'
  properties: {
    collectionId: 'string'
    dataTypes: {
      taxiiClient: {
        state: 'Enabled'
      }
    }
    friendlyName: 'Threat Intelligence Taxii'
    userName: 'string'
    password: 'string'
    pollingFrequency: 'OnceAnHour'
    taxiiLookbackPeriod: 'string'
    taxiiServer: 'string' //API root URL
    tenantId: getTenantId
    workspaceId: lawId
  }
}
*/
