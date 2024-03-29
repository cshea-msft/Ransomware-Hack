// Create Azure Resource Group for Sentinel
resource "azurerm_resource_group" "rg_law" {
  name     = "rg-law-${var.prefix}-${var.location}"
  location = var.location
  tags     = var.tags
}

// Create Log Analytics Workspace and Log Analytics Solution for Sentinel

resource "azurerm_log_analytics_workspace" "law" {
  name                = "sentinel-law-${var.prefix}-${var.location}"
  location            = azurerm_resource_group.rg_law.location
  resource_group_name = azurerm_resource_group.rg_law.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

// Create resource to onboard Sentinel to Log Analytics Workspace
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "law_onboarding" {
  workspace_id = azurerm_log_analytics_workspace.law.id
}
