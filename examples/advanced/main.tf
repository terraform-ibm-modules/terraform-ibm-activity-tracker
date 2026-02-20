##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.7"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Cloud Logs
##############################################################################

module "cloud_logs" {
  source            = "terraform-ibm-modules/cloud-logs/ibm"
  version           = "1.10.35"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  data_storage = {
    logs_data = {
      enabled = false
    },
    metrics_data = {
      enabled = false
    }
  }
}

##############################################################################
# Event Streams
##############################################################################

locals {
  topic_name = "${var.prefix}-topic"
}

module "event_streams" {
  source            = "terraform-ibm-modules/event-streams/ibm"
  version           = "4.6.24"
  es_name           = "${var.prefix}-eventsteams-instance"
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
# Key Protect Instance + Key (used to encrypt bucket)
##############################################################################

locals {
  key_ring_name = "at"
  key_name      = "at-key"
}

module "key_protect" {
  source            = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version           = "5.5.27"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  resource_tags     = var.resource_tags
  keys = [
    {
      key_ring_name = local.key_ring_name
      keys = [
        {
          key_name = local.key_name
        }
      ]
    }
  ]
  key_protect_instance_name = "${var.prefix}-kp"
}

##############################################################################
# COS instance (used for AT target)
##############################################################################

module "cos" {
  source            = "terraform-ibm-modules/cos/ibm"
  version           = "10.9.9"
  resource_group_id = module.resource_group.resource_group_id
  cos_instance_name = "${var.prefix}-cos"
  cos_tags          = var.resource_tags
  create_cos_bucket = false
}

locals {
  at_bucket_name = "${var.prefix}-at-data"
}

module "buckets" {
  source  = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version = "10.9.9"
  bucket_configs = [
    {
      bucket_name                   = local.at_bucket_name
      kms_encryption_enabled        = true
      region_location               = var.region
      resource_instance_id          = module.cos.cos_instance_id
      kms_guid                      = module.key_protect.kms_guid
      kms_key_crn                   = module.key_protect.keys["${local.key_ring_name}.${local.key_name}"].crn
      skip_iam_authorization_policy = false # Auth policy created in first bucket
    }
  ]
}

##############################################################################
# - Activity Tracker Event Routing config:
#   - COS AT target
#   - Cloud Logs AT target
#   - Event Streams AT target
#   - AT route to all above targets
# - Global Event Routing configuration
##############################################################################

locals {
  icl_target_name = "${var.prefix}-icl-target"
  es_target_name  = "${var.prefix}-es-target"
  cos_target_name = "${var.prefix}-cos-target"
  target_ids = [
    module.activity_tracker.activity_tracker_targets[local.cos_target_name].id,
    module.activity_tracker.activity_tracker_targets[local.es_target_name].id,
    module.activity_tracker.activity_tracker_targets[local.icl_target_name].id
  ]
}

module "activity_tracker" {
  source = "../../"
  # delete line above and use below syntax to pull module source from hashicorp when consuming this module
  # source    = "terraform-ibm-modules/activity-tracker/ibm"
  # version   = "X.Y.Z" # Replace "X.X.X" with a release version to lock into a specific release

  # Activity Tracker targets
  cloud_logs_targets = [
    {
      instance_id   = module.cloud_logs.crn
      target_region = var.region
      target_name   = local.icl_target_name
    }
  ]
  cos_targets = [
    {
      bucket_name                       = module.buckets.buckets[local.at_bucket_name].bucket_name
      endpoint                          = module.buckets.buckets[local.at_bucket_name].s3_endpoint_direct
      instance_id                       = module.cos.cos_instance_id
      target_region                     = var.region
      target_name                       = local.cos_target_name
      skip_atracker_cos_iam_auth_policy = false
      service_to_service_enabled        = true
    }
  ]
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
      locations  = ["*"]
      target_ids = local.target_ids
      route_name = "${var.prefix}-route"
    }
  ]

  # Global Event Routing Settings
  # default_targets           - The default target per account to configure where auditing events that are not explicitly managed in the accounts routing rules are routed.
  # metadata_region_primary   - The location in your IBM Cloud account where the Activity Tracker Event Routing account configuration metadata is stored. If you do not configure a metadata location before you create a target, the location where the first target is created is automatically configured as the metadata location.
  # metadata_region_backup    - To store all your metadata in a backup region.
  # permitted_target_regions  - The locations where an account administrator can configure targets to collect auditing events. You can choose any of the supported locations where Activity Tracker Event Routing is available - https://cloud.ibm.com/docs/atracker?topic=atracker-regions&interface=cli.
  # private_api_endpoint_only - The type of endpoints that are allowed to manage the Activity Tracker Event Routing account configuration in the account. If you set this true then you cannot access api through public network.

  # Uncomment below to configure global event routing settings.

  /*
  global_event_routing_settings = {
    default_targets           = local.target_ids
    permitted_target_regions  = ["us-south", "eu-de", "us-east", "eu-es", "eu-gb", "au-syd", "br-sao", "ca-tor", "eu-es", "jp-tok", "jp-osa", "in-che", "eu-fr2"]
    metadata_region_primary   = "us-south"
    private_api_endpoint_only = false
  }
  */
}
