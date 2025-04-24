########################################################################
# Activity Tracker Event Routing
#########################################################################

# Cloud Object Storage Targets
variable "cos_targets" {
  type = list(object({
    endpoint                          = string
    bucket_name                       = string
    instance_id                       = string
    api_key                           = optional(string)
    service_to_service_enabled        = optional(bool, true)
    target_region                     = optional(string)
    target_name                       = string
    skip_atracker_cos_iam_auth_policy = optional(bool, false)
  }))
  default     = []
  description = "List of Cloud Object Storage targets to be created"
  sensitive   = true

  validation {
    condition     = alltrue([for cos_target in var.cos_targets : (cos_target.service_to_service_enabled == true && cos_target.api_key == null) || (cos_target.service_to_service_enabled == false && cos_target.api_key != null)])
    error_message = "The value of `api_key` should not be provided if 'service_to_service_enabled' is set to true for object storage targets. If you want to use 'api_key', set 'service_to_service_enabled' to false."
  }
}

# Event Streams Targets
variable "eventstreams_targets" {
  type = list(object({
    instance_id                      = string
    brokers                          = list(string)
    topic                            = string
    api_key                          = optional(string)
    service_to_service_enabled       = optional(bool, true)
    target_region                    = optional(string)
    target_name                      = string
    skip_atracker_es_iam_auth_policy = optional(bool, false)
  }))
  default     = []
  description = "List of Event Streams targets to be created"
  sensitive   = true

  validation {
    condition     = alltrue([for es_target in var.eventstreams_targets : (es_target.service_to_service_enabled == true && es_target.api_key == null) || (es_target.service_to_service_enabled == false && es_target.api_key != null)])
    error_message = "The value of `api_key` should not be provided if 'service_to_service_enabled' is set to tru for event stream targets. If you want to use 'api_key', set 'service_to_service_enabled' to false."
  }
}

# Cloud Logs Targets
variable "cloud_logs_targets" {
  type = list(object({
    instance_id                              = string
    target_region                            = optional(string)
    target_name                              = string
    skip_atracker_cloud_logs_iam_auth_policy = optional(bool, false)
  }))
  default     = []
  description = "List of Cloud Logs targets to be created"
}

# Routes
variable "activity_tracker_routes" {
  type = list(object({
    locations  = list(string)
    target_ids = list(string)
    route_name = string
  }))
  description = "List of routes to be created, maximum four routes are allowed"
  default     = []

  validation {
    condition     = length(var.activity_tracker_routes) <= 4
    error_message = "The number of activity tracker event routing routes should be less than or equal to 4"
  }

  validation {
    condition     = alltrue([for activity_tracker_route in var.activity_tracker_routes : length(activity_tracker_route.locations) > 0])
    error_message = "The length of locations can not be zero for activity tracker event routing routes"
  }

  validation {
    condition     = alltrue([for activity_tracker_route in var.activity_tracker_routes : length(activity_tracker_route.target_ids) > 0])
    error_message = "The length of `target_ids` for activity tracker event routing can not be zero"
  }
}
# Event Routing Setting
variable "global_event_routing_settings" {
  type = object({
    default_targets           = optional(list(string), [])
    metadata_region_primary   = string
    metadata_region_backup    = optional(string)
    permitted_target_regions  = list(string)
    private_api_endpoint_only = optional(bool, false)
  })
  description = "Global account settings for event routing. [Learn more](https://cloud.ibm.com/docs/atracker?topic=atracker-settings&interface=ui)"
  default     = null

  # https://cloud.ibm.com/docs/atracker?topic=atracker-regions#regions-atracker
  validation {
    error_message = "Valid regions for `permitted_target_regions` to control where targets collecting audit events can be located are: us-south, eu-de, us-east, eu-es, eu-gb, au-syd, br-sao, ca-tor, eu-es, jp-tok, jp-osa, in-che, eu-fr2"
    condition = (var.global_event_routing_settings == null ?
      true :
      alltrue([
        for region in var.global_event_routing_settings.permitted_target_regions :
        contains(["us-south", "eu-de", "us-east", "eu-es", "eu-gb", "au-syd", "br-sao", "ca-tor", "eu-es", "jp-tok", "jp-osa", "in-che", "eu-fr2"], region)
      ])
    )
  }
}
