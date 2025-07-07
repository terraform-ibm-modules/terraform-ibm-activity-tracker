#######################################################################################################################
# IBM Cloud Activity Tracker Event Routing
#######################################################################################################################

module "account_routing_settings" {
  source = "../.."

  global_event_routing_settings = {
    default_targets           = var.default_targets
    metadata_region_primary   = var.metadata_region_primary
    metadata_region_backup    = var.metadata_region_backup
    permitted_target_regions  = var.permitted_target_regions
    private_api_endpoint_only = var.private_api_endpoint_only
  }
}
