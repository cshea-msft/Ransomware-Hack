variable "prefix" {
  description = "The prefix of the resource."
  type        = string
}

variable "location" {
  description = "The location of the resource."
  type        = string
}

variable "tags" {
  description = "The tags of the resource."
  type        = map(string)
}

variable "sub_id" {
  description = "The subscription id of the resource."
  type        = string
}

variable "tenant_id" {
  description = "The tenant id of the resource."
  type        = string
}

/*
variable "api_root_url" {
  description = "The root url of the api."
  type        = string
}

variable "collection_id" {
  description = "The collection id of the api."
  type        = string
}
*/


