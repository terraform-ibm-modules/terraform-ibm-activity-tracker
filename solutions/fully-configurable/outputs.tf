##############################################################################
# Outputs
##############################################################################


## COS Buckets

output "activity_tracker_cos_target_bucket_name" {
  value       = var.existing_activity_tracker_cos_target_bucket_name == null ? var.enable_activity_tracker_event_routing_to_cos_bucket ? module.cos_bucket[0].buckets[local.activity_tracker_cos_target_bucket_name].bucket_name : null : var.existing_activity_tracker_cos_target_bucket_name
  description = "he name of the object storage bucket which is set as activity tracker event routing target to collect audit events."
}


## Activity Tracker Event Routing
output "activity_tracker_targets" {
  value       = module.activity_tracker.activity_tracker_targets
  description = "The map of created Activity Tracker Event Routing targets"
}

output "activity_tracker_routes" {
  value       = module.activity_tracker.activity_tracker_routes
  description = "The map of created Activity Tracker Event Routing routes"
}

## KMS
output "kms_key_rings" {
  description = "IDs of new KMS Key Rings created"
  value       = length(module.kms) > 0 ? module.kms[0].key_rings : null
}

output "kms_keys" {
  description = "IDs of new KMS Keys created"
  value       = length(module.kms) > 0 ? module.kms[0].keys : null
}
