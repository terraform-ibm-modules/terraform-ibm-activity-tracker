##############################################################################
# Outputs
##############################################################################


## COS Buckets

output "at_cos_target_bucket_name" {
  value       = var.existing_at_cos_target_bucket_name == null ? var.enable_at_event_routing_to_cos_bucket ? module.cos_bucket[0].buckets[local.at_cos_target_bucket_name].bucket_name : null : var.existing_at_cos_target_bucket_name
  description = "The name of the AT target COS bucket"
}


## Activity Tracker
output "at_targets" {
  value       = module.activity_tracker.activity_tracker_targets
  description = "The map of created activity_tracker targets"
}

output "at_routes" {
  value       = module.activity_tracker.activity_tracker_routes
  description = "The map of created activity_tracker routes"
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
