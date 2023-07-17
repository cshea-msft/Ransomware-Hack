// Create Azure Resource Group for Sentinel
resource "azurerm_resource_group" "rg_law" {
  name     = "rg-law-${var.prefix}-${var.location}"
  location = var.location
  tags     = var.tags
}