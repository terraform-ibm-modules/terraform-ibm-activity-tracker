##############################################################################
# Outputs
##############################################################################

output "resource_group_name" {
  description = "Resource group name."
  value       = module.resource_group.resource_group_name
}

output "resource_group_id" {
  description = "Resource group ID."
  value       = module.resource_group.resource_group_id
}

output "cloud_logs_crn" {
  value       = module.cloud_logs.crn
  description = "The crn of the provisioned IBM Cloud Logs instance."
}

output "cos_crn" {
  value       = module.cos.cos_instance_crn
  description = "The crn of the provisioned object storage instance."
}

output "event_streams_crn" {
  value       = module.event_streams.crn
  description = "The crn of the provisioned event stream instance."
}

output "event_routing_targets" {
  value       = module.activity_tracker.activity_tracker_targets
  description = "The created AT event routing targets."
}

output "event_routing_routes" {
  value       = module.activity_tracker.activity_tracker_routes
  description = "The created AT event routing routes."
}

output "global_event_routing_settings" {
  value       = module.activity_tracker.activity_tracker_settings
  description = "The global event routing settings of the account."
}
