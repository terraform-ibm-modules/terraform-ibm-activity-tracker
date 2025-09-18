########################################################################################################################
# Outputs
########################################################################################################################

output "resource_group_name" {
  description = "Resource group name."
  value       = module.resource_group.resource_group_name
}

output "resource_group_id" {
  description = "Resource group ID."
  value       = module.resource_group.resource_group_id
}

output "event_routing_targets" {
  value       = module.activity_tracker.activity_tracker_targets
  description = "The created AT event routing target."
}

output "event_routing_routes" {
  value       = module.activity_tracker.activity_tracker_routes
  description = "The created AT event routing route."
}
