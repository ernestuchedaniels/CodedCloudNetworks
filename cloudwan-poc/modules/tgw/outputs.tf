output "tgw_id" {
  description = "Transit Gateway ID"
  value       = aws_ec2_transit_gateway.main.id
}

output "tgw_arn" {
  description = "Transit Gateway ARN"
  value       = aws_ec2_transit_gateway.main.arn
}

output "route_table_ids" {
  description = "Transit Gateway spoke route table IDs (forwarding domain)"
  value = {
    pe  = aws_ec2_transit_gateway_route_table.pe_spoke.id
    npe = aws_ec2_transit_gateway_route_table.npe_spoke.id
  }
}

output "cw_export_route_table_arns" {
  description = "Transit Gateway Cloud WAN export route table ARNs (export-only domain)"
  value = {
    pe  = aws_ec2_transit_gateway_route_table.pe_cw_export.arn
    npe = aws_ec2_transit_gateway_route_table.npe_cw_export.arn
  }
}

output "cw_export_route_table_ids" {
  description = "Transit Gateway Cloud WAN export route table IDs"
  value = {
    pe  = aws_ec2_transit_gateway_route_table.pe_cw_export.id
    npe = aws_ec2_transit_gateway_route_table.npe_cw_export.id
  }
}

output "peer_export_route_table_ids" {
  description = "Transit Gateway peer export route table IDs (same as spoke for this design)"
  value = {
    pe  = aws_ec2_transit_gateway_route_table.pe_spoke.id
    npe = aws_ec2_transit_gateway_route_table.npe_spoke.id
  }
}

output "peer_ingress_route_table_id" {
  description = "Transit Gateway peer ingress route table ID for peering attachment associations"
  value       = aws_ec2_transit_gateway_route_table.peer_ingress.id
}
