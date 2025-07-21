########################################################################################################################
# Common variables
########################################################################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key with access to configure Activity Tracker Event Routing account settings."
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
########################################################################################################################
# IBM Cloud Activity Tracker Event Routing
########################################################################################################################

variable "default_targets" {
  description = "Where activity events that are not explicitly managed in the account's routing rules are routed.You can define up to 2 default targets per account. Consider defining a second default target when you want to collect the data in a backup location."
  type        = list(string)
  default     = []
}

variable "metadata_region_primary" {
  description = "Storage location for target, route, and settings metadata in your IBM Cloud account. To store all configuration metadata in a single region, set this value explicitly. For new accounts, creating targets and routes will fail until `metadata_region_primary` is set. If set to `null`, no change is made to the current value."
  type        = string
  default     = null
}

variable "metadata_region_backup" {
  description = "You can also configure a backup location where the metadata is stored for recovery purposes. The `metadata_region_backup` can't be the same as `metadata_region_primary`."
  type        = string
  default     = null
}

variable "permitted_target_regions" {
  description = "Control where targets collecting audit events can be located.  To allow targets in any region (i.e., No restrictions), configure this field as an empty list `[]`."
  type        = list(string)
  default     = []
}

variable "private_api_endpoint_only" {
  description = "Public endpoints can be disabled for managing Activity Tracker Event Routing configuration via the CLI or REST API. When public endpoints are disabled, the Activity Tracker Event Routing UI will be inaccessible."
  type        = bool
  default     = false
}
