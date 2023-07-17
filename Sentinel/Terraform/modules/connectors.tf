
// Create data connector for Azure Active Directory
resource "azurerm_sentinel_data_connector_azure_active_directory" "aad" {
  name                       = "azure_active_directory"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create data connector for Azure Advanced Threat protection
// E5 License is required for this connector
resource "azurerm_sentinel_data_connector_azure_advanced_threat_protection" "aad_advanced_threat_protection" {
  name                       = "azure_advanced_threat_protection"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create data connector for Defender for Cloud
resource "azurerm_sentinel_data_connector_azure_security_center" "dfc" {
  name                       = "azure_security_center"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  subscription_id            = var.sub_id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}
// Create a data connector for Dynamics 365
resource "azurerm_sentinel_data_connector_dynamics_365" "d365" {
  name                       = "dynamics_365"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create a data connector for IoT
resource "azurerm_sentinel_data_connector_iot" "iot" {
  name                       = "iot"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create data connector for Microsoft Cloud App Security
// E5 license is required for this connector
resource "azurerm_sentinel_data_connector_microsoft_cloud_app_security" "microsoft_cloud_app_security" {
  name                       = "microsoft_cloud_app_security"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create data connector for Microsoft Defender for Endpoint
resource "azurerm_sentinel_data_connector_microsoft_defender_advanced_threat_protection" "microsoft_defender_advanced_threat_protection" {
  name                       = "microsoft_defender_advanced_threat_protection"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create data connector for Microsoft Threat Intelligence
resource "azurerm_sentinel_data_connector_microsoft_threat_intelligence" "microsoft_threat_intelligence" {
  name                       = "microsoft_threat_intelligence"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  microsoft_emerging_threat_feed_lookback_date = "2023-01-01T00:00:00Z"
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}
// Create a data connector for Microsoft Threat Protection
resource "azurerm_sentinel_data_connector_microsoft_threat_protection" "microsoft_threat_protection" {
  name                       = "microsoft_threat_protection"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create a data connector for Threat Intelligence
resource "azurerm_sentinel_data_connector_threat_intelligence" "threat_intelligence" {
  name                       = "threat_intelligence"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

/*
// Create data connector for Threat Intelligence Taxii
// Need api_root_url and collection_id
resource "azurerm_sentinel_data_connector_threat_intelligence_taxii" "threat_intelligence_taxii" {
  name                       = "threat_intelligence_taxii"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  display_name               = "Threat Intelligence Taxii"
  api_root_url               = var.api_root_url
  collection_id              = var.collection_id
}
*/

# Data Connectors for Microsoft 365

// Create data connector for office 365
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

// Create data connector for Office 365 Project
resource "azurerm_sentinel_data_connector_office_365_project" "o365_project" {
  name                       = "office_365_project"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create data connector for Office 365 ATP
resource "azurerm_sentinel_data_connector_office_atp" "o365_advanced_threat_protection" {
  name                       = "office_365_advanced_threat_protection"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create a data connector for Office 365 IRM
resource "azurerm_sentinel_data_connector_office_irm" "o365_information_rights_management" {
  name                       = "office_365_information_rights_management"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}

// Create a data connector for Office 365 Power BI
resource "azurerm_sentinel_data_connector_office_power_bi" "o365_power_bi" {
  name                       = "office_365_power_bi"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_sentinel_log_analytics_workspace_onboarding.law_onboarding
  ]
}
