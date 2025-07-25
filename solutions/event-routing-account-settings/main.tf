#######################################################################################################################
# IBM Cloud Activity Tracker Event Routing
#######################################################################################################################

module "account_routing_settings" {
  source = "../.."

  global_event_routing_settings = {
    default_targets           = var.default_targets
    metadata_region_primary   = var.primary_metadata_region
    metadata_region_backup    = var.backup_metadata_region
    permitted_target_regions  = var.permitted_target_regions
    private_api_endpoint_only = var.private_api_endpoint_only
  }
}
