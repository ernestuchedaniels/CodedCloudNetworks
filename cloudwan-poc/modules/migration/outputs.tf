output "vpc_attachments" {
  description = "CloudWAN VPC attachments and routing mode"
  value = {
    pe_cloudwan_attachment  = aws_networkmanager_vpc_attachment.pe.id
    npe_cloudwan_attachment = aws_networkmanager_vpc_attachment.npe.id
    routing_mode            = var.use_cloudwan ? "CloudWAN" : "Transit Gateway"
  }
}

output "migration_status" {
  description = "Migration status information"
  value = {
    region           = var.region
    using_cloudwan   = var.use_cloudwan
    pe_route_table   = data.aws_route_table.pe_main.id
    npe_route_table  = data.aws_route_table.npe_main.id
  }
}
