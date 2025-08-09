##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.3.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Event Streams
##############################################################################

locals {
  topic_name = "${var.prefix}-topic"
}

module "event_streams" {
  source            = "terraform-ibm-modules/event-streams/ibm"
  version           = "4.0.18"
  es_name           = "${var.prefix}-eventsteams"
  tags              = var.resource_tags
  region            = var.region
  resource_group_id = module.resource_group.resource_group_id
  plan              = "standard"
  topics = [{
    name       = local.topic_name
    partitions = 1
    config = {
      "cleanup.policy"  = "delete"
      "retention.ms"    = "86400000"  # 1 Day
      "retention.bytes" = "10485760"  # 10 MB
      "segment.bytes"   = "536870912" # 512 MB
    }
  }, ]
}

##############################################################################
# - Activity Tracker Event Routing config:
#   - Event Streams AT target
#   - AT route event stream target
##############################################################################

locals {
  es_target_name = "${var.prefix}-es-at-target"
}

module "activity_tracker" {
  source = "../../"
  # delete line above and use below syntax to pull module source from hashicorp when consuming this module
  # source    = "terraform-ibm-modules/activity-tracker/ibm"
  # version   = "X.Y.Z" # Replace "X.X.X" with a release version to lock into a specific release

  # Activity Tracker target
  eventstreams_targets = [
    {
      instance_id                      = module.event_streams.id
      brokers                          = [module.event_streams.kafka_brokers_sasl[0]]
      topic                            = local.topic_name
      target_region                    = var.region
      target_name                      = local.es_target_name
      service_to_service_enabled       = true
      skip_atracker_es_iam_auth_policy = false
    }
  ]

  # Activity Tracker route
  activity_tracker_routes = [
    {
      locations  = ["*", "global"]
      target_ids = [module.activity_tracker.activity_tracker_targets[local.es_target_name].id]
      route_name = "${var.prefix}-at-route"
    }
  ]
}
