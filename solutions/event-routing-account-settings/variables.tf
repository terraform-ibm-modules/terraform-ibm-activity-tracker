########################################################################################################################
# Common variables
########################################################################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key to deploy resources."
  sensitive   = true
}

variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are 'public', 'private', or 'public-and-private'."
  }
}

variable "region" {
  description = "The region to provision all resources in. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/region) about how to select different regions for different services."
  type        = string
  default     = "us-south"
}

########################################################################################################################
# IBM Cloud Activity Tracker Event Routing
########################################################################################################################

variable "default_targets" {
  description = "The default target per account to configure where auditing events that are not explicitly managed in the accounts routing rules are routed."
  type        = list(string)
  default     = []
}

variable "metadata_region_primary" {
  description = "The location in your IBM Cloud account where the Activity Tracker Event Routing account configuration metadata is stored. If you do not configure a metadata location before you create a target, the location where the first target is created is automatically configured as the metadata location."
  type        = string
  default     = null
}

variable "metadata_region_backup" {
  description = "You can also configure a backup location where the metadata is stored for recovery purposes."
  type        = string
  default     = null
}

variable "permitted_target_regions" {
  description = "The locations where an account administrator can configure targets to collect auditing events. You can choose any of the supported locations where Activity Tracker Event Routing is available - https://cloud.ibm.com/docs/atracker?topic=atracker-regions&interface=cli."
  type        = list(string)
  default     = []
}

variable "private_api_endpoint_only" {
  description = "The type of endpoints that are allowed to manage the Activity Tracker Event Routing account configuration in the account. If you set this true then you cannot access api through public network."
  type        = bool
  default     = false
}
