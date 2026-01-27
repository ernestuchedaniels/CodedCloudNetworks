output "peering_attachment_id" {
  description = "TGW-CloudWAN peering attachment ID"
  value       = aws_networkmanager_transit_gateway_peering.main.id
}

output "peering_attachment_arn" {
  description = "TGW-CloudWAN peering attachment ARN"
  value       = aws_networkmanager_transit_gateway_peering.main.transit_gateway_peering_attachment_id
}
