#######################################################################################################################
# Local Variables
#######################################################################################################################

locals {

  prefix = var.prefix != null ? (var.prefix != "" ? var.prefix : null) : null

  default_cos_region = var.cos_region != null ? var.cos_region : var.region

  cos_key_ring_name                       = try("${local.prefix}-${var.cos_key_ring_name}", var.cos_key_ring_name)
  cos_key_name                            = try("${local.prefix}-${var.cos_key_name}", var.cos_key_name)
  activity_tracker_cos_target_bucket_name = try("${local.prefix}-${var.activity_tracker_cos_target_bucket_name}", var.activity_tracker_cos_target_bucket_name)

  cos_instance_guid = try(module.cos_crn_parser[0].service_instance, null)

  use_kms_module    = var.kms_encryption_enabled_buckets && var.existing_cos_kms_key_crn == null
  existing_kms_guid = var.kms_encryption_enabled_buckets ? (var.existing_kms_instance_crn != null ? module.kms_instance_crn_parser[0].service_instance : module.existing_kms_key_crn_parser[0].service_instance) : null
  kms_service       = var.kms_encryption_enabled_buckets ? (var.existing_kms_instance_crn != null ? module.kms_instance_crn_parser[0].service_name : module.existing_kms_key_crn_parser[0].service_name) : null

  kms_region = var.kms_encryption_enabled_buckets && var.existing_kms_instance_crn != null ? module.kms_instance_crn_parser[0].region : null

  cos_kms_key_crn    = var.existing_cos_kms_key_crn != null ? var.existing_cos_kms_key_crn : length(coalesce(local.buckets_config, [])) != 0 && var.kms_encryption_enabled_buckets ? module.kms[0].keys[format("%s.%s", local.cos_key_ring_name, local.cos_key_name)].crn : null
  parsed_kms_key_crn = local.cos_kms_key_crn != null ? split(":", local.cos_kms_key_crn) : []
  cos_kms_key_id     = length(local.parsed_kms_key_crn) > 0 ? local.parsed_kms_key_crn[9] : null
  cos_kms_scope      = length(local.parsed_kms_key_crn) > 0 ? local.parsed_kms_key_crn[6] : null
  kms_account_id     = length(local.parsed_kms_key_crn) > 0 ? split("/", local.cos_kms_scope)[1] : null

  cos_target_bucket_name                 = var.existing_activity_tracker_cos_target_bucket_name != null ? var.existing_activity_tracker_cos_target_bucket_name : var.enable_activity_tracker_event_routing_to_cos_bucket ? module.cos_bucket[0].buckets[local.activity_tracker_cos_target_bucket_name].bucket_name : null
  cos_target_bucket_endpoint             = var.existing_activity_tracker_cos_target_bucket_endpoint != null ? var.existing_activity_tracker_cos_target_bucket_endpoint : var.enable_activity_tracker_event_routing_to_cos_bucket ? module.cos_bucket[0].buckets[local.activity_tracker_cos_target_bucket_name].s3_endpoint_private : null
  cos_target_name                        = var.cos_target_name != null ? var.cos_target_name : try("${local.prefix}-cos-target", "cos-target")
  cloud_logs_target_name                 = var.cloud_logs_target_name != null ? var.cloud_logs_target_name : try("${local.prefix}-cloud-logs-target", "cloud-logs-target")
  activity_tracker_cos_route_name        = var.activity_tracker_cos_route_name != null ? var.activity_tracker_cos_route_name : try("${local.prefix}-at-cos-route", "at-cos-route")
  activity_tracker_cloud_logs_route_name = var.activity_tracker_cloud_logs_route_name != null ? var.activity_tracker_cloud_logs_route_name : try("${local.prefix}-at-cloud-logs-route", "at-cloud-logs-route")



  activity_tracker_bucket_config = var.existing_activity_tracker_cos_target_bucket_name == null && var.enable_activity_tracker_event_routing_to_cos_bucket ? {
    class = var.activity_tracker_cos_target_bucket_class
    name  = local.activity_tracker_cos_target_bucket_name
    tag   = var.activity_tracker_cos_bucket_access_tags
  } : null


  bucket_retention_configs = local.activity_tracker_bucket_config != null ? { (local.activity_tracker_cos_target_bucket_name) = var.activity_tracker_cos_bucket_retention_policy } : null

  buckets_config = local.activity_tracker_bucket_config != null ? [local.activity_tracker_bucket_config] : []

  archive_rule = length(local.buckets_config) != 0 ? {
    enable = true
    days   = 90
    type   = "Glacier"
  } : null

  expire_rule = length(local.buckets_config) != 0 ? {
    enable = true
    days   = 366
  } : null

  activity_tracker_cos_route = var.enable_activity_tracker_event_routing_to_cos_bucket ? [{
    route_name = local.activity_tracker_cos_route_name
    locations  = ["*"]
    target_ids = [module.activity_tracker.activity_tracker_targets[local.cos_target_name].id]
  }] : []

  activity_tracker_cloud_logs_route = var.enable_activity_tracker_event_routing_to_cloud_logs && var.existing_cloud_logs_instance_crn != null ? [{
    route_name = local.activity_tracker_cloud_logs_route_name
    locations  = ["*"]
    target_ids = [module.activity_tracker.activity_tracker_targets[local.cloud_logs_target_name].id]
  }] : []

  create_cross_account_cos_kms_auth_policy      = !var.skip_cos_kms_auth_policy && var.ibmcloud_kms_api_key != null && var.existing_cos_instance_crn != null ? 1 : 0
  create_cross_account_atracker_cos_auth_policy = var.ibmcloud_cos_api_key != null && !var.skip_activity_tracker_cos_auth_policy && var.existing_cos_instance_crn != null ? 1 : 0
  activity_tracker_routes                       = concat(local.activity_tracker_cos_route, local.activity_tracker_cloud_logs_route)

}

#######################################################################################################################
# Activity Tracker
#######################################################################################################################

data "ibm_iam_account_settings" "iam_account_settings" {
}



module "activity_tracker" {
  depends_on = [time_sleep.wait_for_atracker_cos_authorization_policy]
  source     = "../../"

  cos_targets = var.enable_activity_tracker_event_routing_to_cos_bucket ? [
    {
      bucket_name                       = local.cos_target_bucket_name
      endpoint                          = local.cos_target_bucket_endpoint
      instance_id                       = var.existing_cos_instance_crn
      target_region                     = local.default_cos_region
      target_name                       = local.cos_target_name
      skip_atracker_cos_iam_auth_policy = var.ibmcloud_cos_api_key != null ? true : var.skip_activity_tracker_cos_auth_policy
      service_to_service_enabled        = true
    }
  ] : []

  cloud_logs_targets = var.enable_activity_tracker_event_routing_to_cloud_logs && var.existing_cloud_logs_instance_crn != null ? [
    {
      instance_id   = var.existing_cloud_logs_instance_crn
      target_region = var.region
      target_name   = local.cloud_logs_target_name
    }
  ] : []

  # Routes
  activity_tracker_routes = local.activity_tracker_routes
}

resource "time_sleep" "wait_for_atracker_cos_authorization_policy" {
  count           = var.ibmcloud_cos_api_key == null ? 0 : 1
  depends_on      = [ibm_iam_authorization_policy.atracker_cos]
  create_duration = "30s"
}

resource "ibm_iam_authorization_policy" "atracker_cos" {
  count                       = local.create_cross_account_atracker_cos_auth_policy
  provider                    = ibm.cos
  source_service_account      = data.ibm_iam_account_settings.iam_account_settings.account_id
  source_service_name         = "atracker"
  target_service_name         = "cloud-object-storage"
  target_resource_instance_id = regex(".*:(.*)::", var.existing_cos_instance_crn)[0]
  roles                       = ["Object Writer"]
  description                 = "Permit AT service Object Writer access to COS instance ${var.existing_cos_instance_crn}"
}

#######################################################################################################################
# KMS Key
#######################################################################################################################

# If existing KMS instance CRN passed, parse details from it
module "kms_instance_crn_parser" {
  count   = var.existing_kms_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.3.0"
  crn     = var.existing_kms_instance_crn
}

module "existing_kms_key_crn_parser" {
  count   = var.existing_cos_kms_key_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.3.0"
  crn     = var.existing_cos_kms_key_crn
}

module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = (local.use_kms_module && (length(coalesce(local.buckets_config, [])) != 0)) ? 1 : 0 # no need to create any KMS resources if `kms_encryption_enabled_buckets` is false or `existing_cos_kms_key_crn` is provided or `buckets_config` length is 0
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "5.5.0"
  create_key_protect_instance = false
  region                      = local.kms_region
  existing_kms_instance_crn   = var.existing_kms_instance_crn
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys = [
    {
      key_ring_name         = local.cos_key_ring_name
      existing_key_ring     = false
      force_delete_key_ring = true
      keys = [
        {
          key_name                 = local.cos_key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = true
        }
      ]
    }
  ]
}

#######################################################################################################################
# COS
#######################################################################################################################

module "cos_crn_parser" {
  count   = var.existing_cos_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.3.0"
  crn     = var.existing_cos_instance_crn
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_authorization_policy" {
  depends_on      = [ibm_iam_authorization_policy.policy]
  count           = var.skip_cos_kms_auth_policy ? 0 : 1
  create_duration = "30s"
}

# Data source to account settings for retrieving COS cross account id
data "ibm_iam_account_settings" "iam_cos_account_settings" {
  provider = ibm.cos
}


# Create IAM Authorization Policy to allow COS to access KMS for the encryption key
resource "ibm_iam_authorization_policy" "policy" {
  count = local.create_cross_account_cos_kms_auth_policy
  # Conditionals with providers aren't possible, using ibm.kms as provider incase cross account is enabled
  provider                    = ibm.kms
  source_service_account      = data.ibm_iam_account_settings.iam_cos_account_settings.account_id
  source_service_name         = "cloud-object-storage"
  source_resource_instance_id = local.cos_instance_guid
  roles                       = ["Reader"]
  description                 = "Allow the COS instance ${local.cos_instance_guid} to read the ${local.kms_service} key ${local.cos_kms_key_id} from the instance ${local.existing_kms_guid}"
  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = local.kms_service
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = local.kms_account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = local.existing_kms_guid
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "key"
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = local.cos_kms_key_id
  }
  # Scope of policy now includes the key, so ensure to create new policy before
  # destroying old one to prevent any disruption to every day services.
  lifecycle {
    create_before_destroy = true
  }
}


module "cos_bucket" {
  depends_on = [time_sleep.wait_for_authorization_policy]
  providers = {
    ibm = ibm.cos
  }
  count   = length(coalesce(local.buckets_config, [])) != 0 ? 1 : 0 # no need to call COS module if consumer is using existing COS bucket
  source  = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version = "10.7.0"
  bucket_configs = [
    for value in local.buckets_config :
    {
      access_tags                   = value.tag
      bucket_name                   = value.name
      add_bucket_name_suffix        = var.add_bucket_name_suffix
      kms_guid                      = local.existing_kms_guid
      kms_encryption_enabled        = var.kms_encryption_enabled_buckets
      kms_key_crn                   = local.cos_kms_key_crn
      skip_iam_authorization_policy = false
      management_endpoint_type      = var.management_endpoint_type_for_bucket
      storage_class                 = value.class
      resource_instance_id          = var.existing_cos_instance_crn
      region_location               = local.default_cos_region
      force_delete                  = true
      archive_rule                  = local.archive_rule
      expire_rule                   = local.expire_rule
      retention_rule                = lookup(local.bucket_retention_configs, value.name, null)
      metrics_monitoring = {
        usage_metrics_enabled   = true
        request_metrics_enabled = true
        # If `existing_monitoring_crn` is not passed, metrics are sent to the instance associated to the container's location unless otherwise specified in the Metrics Router service configuration.
        metrics_monitoring_crn = var.existing_monitoring_crn
      }
      activity_tracking = {
        read_data_events  = true
        write_data_events = true
        management_events = true
      }
    }
  ]
}
