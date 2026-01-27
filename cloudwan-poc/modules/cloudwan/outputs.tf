output "core_network_id" {
  description = "CloudWAN Core Network ID"
  value       = aws_networkmanager_core_network.main.id
}

output "core_network_arn" {
  description = "CloudWAN Core Network ARN"
  value       = aws_networkmanager_core_network.main.arn
}

output "global_network_id" {
  description = "CloudWAN Global Network ID"
  value       = aws_networkmanager_global_network.main.id
}

output "policy_document" {
  description = "CloudWAN Core Network Policy Document (JSON)"
  value       = data.aws_networkmanager_core_network_policy_document.main.json
}

output "segments" {
  description = "List of CloudWAN segments"
  value       = keys(var.segments)
}

output "edge_locations" {
  description = "List of CloudWAN edge locations"
  value       = keys(var.regions)
}
