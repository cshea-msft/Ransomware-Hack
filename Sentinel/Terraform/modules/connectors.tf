

// Create Data Connector for office 365
resource "azurerm_sentinel_data_connector_office_365" "o365" {
  name                       = "office_365"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  exchange_enabled           = true
  teams_enabled              = true
  sharepoint_enabled         = true
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create Data Connector for Azure Advanced Threat protection
// E5 License is required for this connector
resource "azurerm_sentinel_data_connector_azure_advanced_threat_protection" "aad_advanced_threat_protection" {
  name                       = "azure_advanced_threat_protection"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create Data Connector for Defender for Cloud
resource "azurerm_sentinel_data_connector_azure_security_center" "dfc" {
  name                       = "azure_security_center"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  subscription_id            = var.sub_id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create Data Connector for Azure Active Directory
resource "azurerm_sentinel_data_connector_azure_active_directory" "aad" {
  name                       = "azure_active_directory"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create Data Connector for Microsoft Cloud App Security
// E5 license is required for this connector
resource "azurerm_sentinel_data_connector_microsoft_cloud_app_security" "microsoft_cloud_app_security" {
  name                       = "microsoft_cloud_app_security"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

/*
// Create Data Connector for Microsoft Defender for Endpoint
resource "azurerm_sentinel_data_connector_microsoft_defender_advanced_threat_protection" "microsoft_defender_advanced_threat_protection" {
  name                       = "microsoft_defender_advanced_threat_protection"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}
*/
/*
// Create Data Connector for Threat Intelligence Taxii
resource "azurerm_sentinel_data_connector_threat_intelligence_taxii" "threat_intelligence_taxii" {
  name                       = "threat_intelligence_taxii"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  display_name               = "Threat Intelligence Taxii"
  api_root_url               = var.api_root_url
  collection_id              = var.collection_id
}
*/