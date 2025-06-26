##############################################################################
# Resource group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Cloud Logs
##############################################################################

module "cloud_logs" {
  source               = "terraform-ibm-modules/observability-instances/ibm//modules/cloud_logs"
  version              = "3.4.2"
  instance_name        = var.prefix
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  resource_tags        = var.resource_tags
  enable_platform_logs = false
  data_storage = {
    logs_data = {
      enabled         = true
      bucket_crn      = module.buckets.buckets[local.logs_bucket_name].bucket_crn
      bucket_endpoint = module.buckets.buckets[local.logs_bucket_name].s3_endpoint_direct
    }
  }
}
