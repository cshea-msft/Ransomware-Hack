// Create Log Analytics Workspace and Log Analytics Solution for Sentinel

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.prefix}-${var.resource_location}-1"
  location            = azurerm_resource_group.rg_law.location
  resource_group_name = azurerm_resource_group.rg_law.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

// Create resource to onboard Sentinel to Log Analytics Workspace
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "law_onboarding" {
  resource_group_name = azurerm_resource_group.rg_law.name
  workspace_name      = azurerm_log_analytics_workspace.law.name
}

// Call the alerts.json template to create the alerts
resource "azurerm_resource_group_template_deployment" "alerts" {
  name                = "jsondeploy"
  resource_group_name = azurerm_resource_group.rg_law.name
  deployment_mode     = "Incremental"
  parameters_content  = jsonencode({})
  template_content    = file("alerts.json")
}