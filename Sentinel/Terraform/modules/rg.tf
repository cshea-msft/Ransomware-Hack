// Create Azure Resource Group for Sentinel

resource "azurerm_resource_group" "rg_law" {
  name     = "rg-law-${var.prefix}-${var.resource_location}"
  location = var.resource_location
  tags     = var.resource_tags
}