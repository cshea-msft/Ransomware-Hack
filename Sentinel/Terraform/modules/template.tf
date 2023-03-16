/*
resource "azurerm_resource_group_template_deployment" "alerts" {
  name                = "jsondeploy"
  resource_group_name = azurerm_resource_group.rg_law.name
  deployment_mode     = "Incremental"
  parameters_content  = jsonencode({})
  template_content    = file("alerts.json")
}
*/
