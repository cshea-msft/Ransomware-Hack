provider "azurerm" {
  features {}
}

module "modules" {
  source            = "./modules"
  prefix            = var.prefix
  resource_location = var.resource_location
  resource_tags     = var.resource_tags
  sub_id            = var.sub_id
  /* api_root_url      = var.api_root_url
  collection_id     = var.collection_id */
}
