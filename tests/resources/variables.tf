##############################################################################
# Input variables
##############################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key."
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "The prefix to add to all resources."
}

variable "resource_group" {
  type        = string
  description = "The name of an existing resource group to provision resources in. If not specified, a new resource group is created with the `prefix` variable."
  default     = null
}

variable "region" {
  type        = string
  description = "The IBM Cloud region."
  default     = "us-east"
}

variable "resource_tags" {
  type        = list(string)
  description = "Add user resource tags to the Activity Tracker instance to organize, track, and manage costs. [Learn more](https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#tag-types)."
  default     = []
}
