provider "azurerm" {
  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = false //Change to True for production
    }
    resource_group {
      prevent_deletion_if_contains_resources = false //Change to True for production
    }
    template_deployment {
      delete_nested_items_during_deletion = true //Change to False for production
    }
  }
}

module "modules" {
  source   = "./modules"
  prefix   = var.prefix
  location = var.location
  tags     = var.tags
  sub_id   = var.sub_id
  //api_root_url      = var.api_root_url
  //collection_id     = var.collection_id
}
