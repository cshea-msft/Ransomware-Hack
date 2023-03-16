// Create Azure Resource Group variables 

variable "resource_location" {
  description = "The location of the resource group."
  type        = string
}

variable "resource_tags" {
  description = "The tags of the resource up."
  type        = map(string)
}

variable "prefix" {
  description = "The prefix of the resource group."
  type        = string
}

variable "sub_id" {
  description = "The subscription id of the resource group."
  type        = string
}
/*
// Threat Intelligence Taxii Variables
variable "api_root_url" {
  description = "The root url of the api."
  type        = string
}
variable "collection_id" {
  description = "The collection id of the api."
  type        = string
}
*/
