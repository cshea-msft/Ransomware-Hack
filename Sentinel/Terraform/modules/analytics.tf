/*

// Create a Resource Group Template Deployment for Alerts.JSON
resource "azurerm_resource_group_template_deployment" "rg_template_deployment" {
  name                = "rg_template_deployment"
  resource_group_name = azurerm_resource_group.rg_law.name
  deployment_mode     = "Incremental"
  parameters_content = jsonencode({
    "workspace" = {
      value = azurerm_log_analytics_workspace.law.id
    }
  })
  template_content = file("${path.module}/alerts.json")
}

*/