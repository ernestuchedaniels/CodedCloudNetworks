resource "aws_ec2_transit_gateway" "main" {
  description                     = "CloudWAN POC TGW - ${var.region}"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  amazon_side_asn                 = 64512

  tags = {
    Name        = "tgw-poc-${var.region}"
    Environment = "poc"
  }
}

# PE Spoke RT - Forwarding domain (VPC associations, static TGW peering routes, Cloud WAN propagated routes)
resource "aws_ec2_transit_gateway_route_table" "pe_spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags = {
    Name        = "pe-spoke-${var.region}"
    Environment = "pe"
    Purpose     = "Forwarding domain - VPC associations + static routes (PRIMARY) + Cloud WAN routes (SECONDARY)"
  }
}

# PE Cloud WAN Export RT - Export-only domain (ONLY local VPC routes, feeds Cloud WAN pe segment)
resource "aws_ec2_transit_gateway_route_table" "pe_cw_export" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags = {
    Name        = "pe-cw-export-${var.region}"
    Environment = "pe"
    Purpose     = "Export-only - Local VPC routes to Cloud WAN pe segment"
  }
}

# NPE Spoke RT - Forwarding domain (VPC associations, static TGW peering routes, Cloud WAN propagated routes)
resource "aws_ec2_transit_gateway_route_table" "npe_spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags = {
    Name        = "npe-spoke-${var.region}"
    Environment = "npe"
    Purpose     = "Forwarding domain - VPC associations + static routes (PRIMARY) + Cloud WAN routes (SECONDARY)"
  }
}

# NPE Cloud WAN Export RT - Export-only domain (ONLY local VPC routes, feeds Cloud WAN npe segment)
resource "aws_ec2_transit_gateway_route_table" "npe_cw_export" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags = {
    Name        = "npe-cw-export-${var.region}"
    Environment = "npe"
    Purpose     = "Export-only - Local VPC routes to Cloud WAN npe segment"
  }
}

# Peer Ingress RT - Handles INBOUND traffic from TGW peering attachments
resource "aws_ec2_transit_gateway_route_table" "peer_ingress" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags = {
    Name    = "peer-ingress-${var.region}"
    Purpose = "Ingress-only - Routes inbound peering traffic to local VPC attachments"
  }
}
