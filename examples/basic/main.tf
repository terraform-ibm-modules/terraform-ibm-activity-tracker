##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.6.1"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# COS instance and bucket
##############################################################################

module "cos" {
  source                 = "terraform-ibm-modules/cos/ibm"
  version                = "10.16.4"
  resource_group_id      = module.resource_group.resource_group_id
  region                 = var.region
  cos_instance_name      = "${var.prefix}-cos"
  resource_tags          = var.resource_tags
  bucket_name            = "${var.prefix}-bucket"
  kms_encryption_enabled = false
}

##############################################################################
# - Activity Tracker Event Routing config:
#   - COS bucket AT target
#   - AT route to COS bucket target
##############################################################################

locals {
  bucket_target_name = "${var.prefix}-cos-at-target"
}

module "activity_tracker" {
  source = "../../"
  # delete line above and use below syntax to pull module source from HashiCorp when consuming this module
  # source    = "terraform-ibm-modules/activity-tracker/ibm"
  # version   = "X.Y.Z" # Replace "X.X.X" with a release version to lock into a specific release

  # COS bucket target
  cos_targets = [
    {
      bucket_name   = module.cos.bucket_name
      endpoint      = module.cos.s3_endpoint_direct
      instance_id   = module.cos.cos_instance_id
      target_region = var.region
      target_name   = local.bucket_target_name
    }
  ]

  # Activity Tracker route to COS bucket
  activity_tracker_routes = [
    {
      locations  = ["*"]
      target_ids = [module.activity_tracker.activity_tracker_targets[local.bucket_target_name].id]
      route_name = "${var.prefix}-cos-route"
    }
  ]
}
