param lawName string


resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: lawName
}


// Create Sentinel Fusion Alert Rule
/*
resource fusion_alert 'Microsoft.SecurityInsights/alertRules@2023-02-01-preview' = {
  name: 'fusion_alert_rule_fusion'
  kind: 'Fusion'
  scope: law
  properties: {
    alertRuleTemplateName: 'f71aba3d-28fb-450b-b192-4e76a83015c8'
    enabled: true
  }
}
*/


// Create Sentinel MS Security Incident Alert Rule
resource AAD_IP_alerts 'Microsoft.SecurityInsights/alertRules@2023-02-01-preview' = {
  name: 'ms_security_incident_alert_rule_aad_ip'
  kind: 'MicrosoftSecurityIncidentCreation'
  scope: law
  properties: {
    displayName: 'MS Security Incident Alert Rule - AAD IP'
    productFilter: 'Azure Active Directory Identity Protection'
    severitiesFilter: ['High']
    enabled: true
  }
}


// Create Sentinel MS Security Incident Alert Rule for Defender for Cloud
resource DFC_alerts 'Microsoft.SecurityInsights/alertRules@2023-02-01-preview' = {
  name: 'ms_security_incident_alert_rule_dfc'
  kind: 'MicrosoftSecurityIncidentCreation'
  scope: law
  properties: {
    displayName: 'MS Security Incident Alert Rule - DFC'
    productFilter: 'Azure Security Center'
    severitiesFilter: ['High']
    alertRuleTemplateName: '90586451-7ba8-4c1e-9904-7d1b7c3cc4d6'
    enabled: true
  }
}


// Create Sentinel MS Security Incident Alert Rule for Azure Advanced Threat Protection
resource AATP 'Microsoft.SecurityInsights/alertRules@2023-02-01-preview' = {
  name: 'ms_security_incident_alert_rule_aatp'
  kind: 'MicrosoftSecurityIncidentCreation'
  scope: law
  properties: {
    displayName: 'MS Security Incident Alert Rule - AATP'
    productFilter: 'Azure Advanced Threat Protection'
    severitiesFilter: ['High']
    enabled: true
  }
}


// Create Sentinel MS Security Incident Alert Rule for Cloud App Security
resource CAS 'Microsoft.SecurityInsights/alertRules@2023-02-01-preview' = {
  name: 'ms_security_incident_alert_rule_cas'
  kind: 'MicrosoftSecurityIncidentCreation'
  scope: law
  properties: {
    displayName: 'MS Security Incident Alert Rule - CAS'
    productFilter: 'Microsoft Cloud App Security'
    severitiesFilter: ['High']
    enabled: true
  }
}


// Create Sentinel MS Security Incident Alert Rule for Office 365 Advanced Threat Protection
resource O365_ATP 'Microsoft.SecurityInsights/alertRules@2023-02-01-preview' = {
  name: 'ms_security_incident_alert_rule_o365_oatp'
  kind: 'MicrosoftSecurityIncidentCreation'
  scope: law
  properties: {
    displayName: 'MS Security Incident Alert Rule - O365'
    productFilter: 'Office 365 Advanced Threat Protection'
    severitiesFilter: ['High']
    enabled: true
  }
}


// Create Sentinel MS Security Incident Alert Rule for Defender Advanced Threat Protection
resource DATP 'Microsoft.SecurityInsights/alertRules@2023-02-01-preview' = {
  name: 'ms_security_incident_alert_rule_datp'
  kind: 'MicrosoftSecurityIncidentCreation'
  scope: law
  properties: {
    displayName: 'MS Security Incident Alert Rule - DATP'
    productFilter: 'Microsoft Defender Advanced Threat Protection'
    severitiesFilter: ['High']
    enabled: true
  }
}


// Create Sentinel Machine Learning Behavior Analytics Alert Rule
resource mlba_alert_rule 'Microsoft.SecurityInsights/alertRules@2023-02-01-preview' = {
  name: 'mlbeavior_analytics_alert_rule_mlba'
  kind: 'MLBehaviorAnalytics'
  scope: law
  properties: {
    alertRuleTemplateName: '737a2ce1-70a3-4968-9e90-3e6aca836abf'
    enabled: true
  }
}


// Create Sentinel Machine Learning Anomalous SSH Login Detection ALert Rule
resource mlad_alert_rule 'Microsoft.SecurityInsights/alertRules@2023-02-01-preview' = {
  name: 'mlanomalous_ssh_login_detection_alert_rule_mlad'
  kind: 'MLBehaviorAnalytics'
  scope: law
  properties: {
    alertRuleTemplateName: 'fa118b98-de46-4e94-87f9-8e6d5060b60b'
    enabled: true
  }
}

