# TGW-CloudWAN Integration (SECONDARY BACKBONE)
# Creates TGW peering to Cloud WAN and enables route propagation into spoke RTs

resource "aws_networkmanager_transit_gateway_peering" "main" {
  core_network_id     = var.cloudwan_core_id
  transit_gateway_arn = var.tgw_arn

  tags = {
    Name   = "tgw-cloudwan-peering-${var.region}"
    Region = var.region
  }
}

resource "aws_ec2_transit_gateway_policy_table" "main" {
  transit_gateway_id = split("/", var.tgw_arn)[1]

  tags = {
    Name = "tgw-policy-table-${var.region}"
  }
}

resource "aws_ec2_transit_gateway_policy_table_association" "main" {
  transit_gateway_attachment_id   = aws_networkmanager_transit_gateway_peering.main.transit_gateway_peering_attachment_id
  transit_gateway_policy_table_id = aws_ec2_transit_gateway_policy_table.main.id
}

# Route Table Attachments - Map TGW export RTs to Cloud WAN segments
# These attachments feed LOCAL VPC routes from TGW to Cloud WAN
resource "aws_networkmanager_transit_gateway_route_table_attachment" "segment" {
  for_each = var.segment_route_tables

  peering_id                      = aws_networkmanager_transit_gateway_peering.main.id
  transit_gateway_route_table_arn = each.value

  tags = {
    Name        = "tgw-rt-attachment-${var.region}-${each.key}"
    Environment = each.key
    Segment     = each.key
  }

  depends_on = [
    aws_ec2_transit_gateway_policy_table_association.main
  ]
}

# NOTE: Cannot propagate peering attachments to TGW route tables per AWS limitations
# Remote routes from Cloud WAN must be added as static routes instead
# This is handled by the TGW peering module or manually configured
