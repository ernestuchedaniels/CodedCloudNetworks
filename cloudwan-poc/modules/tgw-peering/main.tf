terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.us_east_1, aws.us_west_2, aws.eu_west_1, aws.ap_southeast_1]
    }
  }
}

# ============================================================================
# TGW PEERING ATTACHMENTS
# ============================================================================

# us-east-1 <-> us-west-2
resource "aws_ec2_transit_gateway_peering_attachment" "use1_to_usw2" {
  provider                = aws.us_east_1
  transit_gateway_id      = var.tgw_ids["us-east-1"]
  peer_transit_gateway_id = var.tgw_ids["us-west-2"]
  peer_region             = "us-west-2"
  tags                    = { Name = "tgw-peering-use1-usw2" }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "usw2_accept" {
  provider                      = aws.us_west_2
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.use1_to_usw2.id
  tags                          = { Name = "tgw-peering-usw2-accept" }
}

# us-east-1 <-> eu-west-1
resource "aws_ec2_transit_gateway_peering_attachment" "use1_to_euw1" {
  provider                = aws.us_east_1
  transit_gateway_id      = var.tgw_ids["us-east-1"]
  peer_transit_gateway_id = var.tgw_ids["eu-west-1"]
  peer_region             = "eu-west-1"
  tags                    = { Name = "tgw-peering-use1-euw1" }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "euw1_accept" {
  provider                      = aws.eu_west_1
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.use1_to_euw1.id
  tags                          = { Name = "tgw-peering-euw1-accept" }
}

# us-east-1 <-> ap-southeast-1
resource "aws_ec2_transit_gateway_peering_attachment" "use1_to_apse1" {
  provider                = aws.us_east_1
  transit_gateway_id      = var.tgw_ids["us-east-1"]
  peer_transit_gateway_id = var.tgw_ids["ap-southeast-1"]
  peer_region             = "ap-southeast-1"
  tags                    = { Name = "tgw-peering-use1-apse1" }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "apse1_accept" {
  provider                      = aws.ap_southeast_1
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.use1_to_apse1.id
  tags                          = { Name = "tgw-peering-apse1-accept" }
}

# us-west-2 <-> eu-west-1
resource "aws_ec2_transit_gateway_peering_attachment" "usw2_to_euw1" {
  provider                = aws.us_west_2
  transit_gateway_id      = var.tgw_ids["us-west-2"]
  peer_transit_gateway_id = var.tgw_ids["eu-west-1"]
  peer_region             = "eu-west-1"
  tags                    = { Name = "tgw-peering-usw2-euw1" }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "euw1_accept_usw2" {
  provider                      = aws.eu_west_1
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.usw2_to_euw1.id
  tags                          = { Name = "tgw-peering-euw1-accept-usw2" }
}

# us-west-2 <-> ap-southeast-1
resource "aws_ec2_transit_gateway_peering_attachment" "usw2_to_apse1" {
  provider                = aws.us_west_2
  transit_gateway_id      = var.tgw_ids["us-west-2"]
  peer_transit_gateway_id = var.tgw_ids["ap-southeast-1"]
  peer_region             = "ap-southeast-1"
  tags                    = { Name = "tgw-peering-usw2-apse1" }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "apse1_accept_usw2" {
  provider                      = aws.ap_southeast_1
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.usw2_to_apse1.id
  tags                          = { Name = "tgw-peering-apse1-accept-usw2" }
}

# eu-west-1 <-> ap-southeast-1
resource "aws_ec2_transit_gateway_peering_attachment" "euw1_to_apse1" {
  provider                = aws.eu_west_1
  transit_gateway_id      = var.tgw_ids["eu-west-1"]
  peer_transit_gateway_id = var.tgw_ids["ap-southeast-1"]
  peer_region             = "ap-southeast-1"
  tags                    = { Name = "tgw-peering-euw1-apse1" }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "apse1_accept_euw1" {
  provider                      = aws.ap_southeast_1
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.euw1_to_apse1.id
  tags                          = { Name = "tgw-peering-apse1-accept-euw1" }
}

# ============================================================================
# PEERING ATTACHMENT ASSOCIATIONS TO peer_ingress_rt
# ============================================================================

# us-east-1 <-> us-west-2
resource "aws_ec2_transit_gateway_route_table_association" "use1_usw2_ingress_use1" {
  provider                       = aws.us_east_1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_usw2.id
  transit_gateway_route_table_id = var.route_table_ids["us-east-1"].peer_ingress_rt
  replace_existing_association   = true
}

resource "aws_ec2_transit_gateway_route_table_association" "use1_usw2_ingress_usw2" {
  provider                       = aws.us_west_2
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_usw2.id
  transit_gateway_route_table_id = var.route_table_ids["us-west-2"].peer_ingress_rt
  replace_existing_association   = true
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.usw2_accept]
}

# us-east-1 <-> eu-west-1
resource "aws_ec2_transit_gateway_route_table_association" "use1_euw1_ingress_use1" {
  provider                       = aws.us_east_1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_euw1.id
  transit_gateway_route_table_id = var.route_table_ids["us-east-1"].peer_ingress_rt
  replace_existing_association   = true
}

resource "aws_ec2_transit_gateway_route_table_association" "use1_euw1_ingress_euw1" {
  provider                       = aws.eu_west_1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_euw1.id
  transit_gateway_route_table_id = var.route_table_ids["eu-west-1"].peer_ingress_rt
  replace_existing_association   = true
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.euw1_accept]
}

# us-east-1 <-> ap-southeast-1
resource "aws_ec2_transit_gateway_route_table_association" "use1_apse1_ingress_use1" {
  provider                       = aws.us_east_1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["us-east-1"].peer_ingress_rt
  replace_existing_association   = true
}

resource "aws_ec2_transit_gateway_route_table_association" "use1_apse1_ingress_apse1" {
  provider                       = aws.ap_southeast_1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["ap-southeast-1"].peer_ingress_rt
  replace_existing_association   = true
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.apse1_accept]
}

# us-west-2 <-> eu-west-1
resource "aws_ec2_transit_gateway_route_table_association" "usw2_euw1_ingress_usw2" {
  provider                       = aws.us_west_2
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.usw2_to_euw1.id
  transit_gateway_route_table_id = var.route_table_ids["us-west-2"].peer_ingress_rt
  replace_existing_association   = true
}

resource "aws_ec2_transit_gateway_route_table_association" "usw2_euw1_ingress_euw1" {
  provider                       = aws.eu_west_1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.usw2_to_euw1.id
  transit_gateway_route_table_id = var.route_table_ids["eu-west-1"].peer_ingress_rt
  replace_existing_association   = true
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.euw1_accept_usw2]
}

# us-west-2 <-> ap-southeast-1
resource "aws_ec2_transit_gateway_route_table_association" "usw2_apse1_ingress_usw2" {
  provider                       = aws.us_west_2
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.usw2_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["us-west-2"].peer_ingress_rt
  replace_existing_association   = true
}

resource "aws_ec2_transit_gateway_route_table_association" "usw2_apse1_ingress_apse1" {
  provider                       = aws.ap_southeast_1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.usw2_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["ap-southeast-1"].peer_ingress_rt
  replace_existing_association   = true
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.apse1_accept_usw2]
}

# eu-west-1 <-> ap-southeast-1
resource "aws_ec2_transit_gateway_route_table_association" "euw1_apse1_ingress_euw1" {
  provider                       = aws.eu_west_1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.euw1_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["eu-west-1"].peer_ingress_rt
  replace_existing_association   = true
}

resource "aws_ec2_transit_gateway_route_table_association" "euw1_apse1_ingress_apse1" {
  provider                       = aws.ap_southeast_1
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.euw1_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["ap-southeast-1"].peer_ingress_rt
  replace_existing_association   = true
  depends_on                     = [aws_ec2_transit_gateway_peering_attachment_accepter.apse1_accept_euw1]
}

# ============================================================================
# STATIC ROUTES IN peer_ingress_rt (LOCAL VPC CIDRS)
# ============================================================================

# us-east-1
resource "aws_ec2_transit_gateway_route" "use1_ingress_pe" {
  provider                       = aws.us_east_1
  destination_cidr_block         = var.remote_cidrs["us-east-1"].pe
  transit_gateway_attachment_id  = var.vpc_attachment_ids["us-east-1"].pe
  transit_gateway_route_table_id = var.route_table_ids["us-east-1"].peer_ingress_rt
}

resource "aws_ec2_transit_gateway_route" "use1_ingress_npe" {
  provider                       = aws.us_east_1
  destination_cidr_block         = var.remote_cidrs["us-east-1"].npe
  transit_gateway_attachment_id  = var.vpc_attachment_ids["us-east-1"].npe
  transit_gateway_route_table_id = var.route_table_ids["us-east-1"].peer_ingress_rt
}

# us-west-2
resource "aws_ec2_transit_gateway_route" "usw2_ingress_pe" {
  provider                       = aws.us_west_2
  destination_cidr_block         = var.remote_cidrs["us-west-2"].pe
  transit_gateway_attachment_id  = var.vpc_attachment_ids["us-west-2"].pe
  transit_gateway_route_table_id = var.route_table_ids["us-west-2"].peer_ingress_rt
}

resource "aws_ec2_transit_gateway_route" "usw2_ingress_npe" {
  provider                       = aws.us_west_2
  destination_cidr_block         = var.remote_cidrs["us-west-2"].npe
  transit_gateway_attachment_id  = var.vpc_attachment_ids["us-west-2"].npe
  transit_gateway_route_table_id = var.route_table_ids["us-west-2"].peer_ingress_rt
}

# eu-west-1
resource "aws_ec2_transit_gateway_route" "euw1_ingress_pe" {
  provider                       = aws.eu_west_1
  destination_cidr_block         = var.remote_cidrs["eu-west-1"].pe
  transit_gateway_attachment_id  = var.vpc_attachment_ids["eu-west-1"].pe
  transit_gateway_route_table_id = var.route_table_ids["eu-west-1"].peer_ingress_rt
}

resource "aws_ec2_transit_gateway_route" "euw1_ingress_npe" {
  provider                       = aws.eu_west_1
  destination_cidr_block         = var.remote_cidrs["eu-west-1"].npe
  transit_gateway_attachment_id  = var.vpc_attachment_ids["eu-west-1"].npe
  transit_gateway_route_table_id = var.route_table_ids["eu-west-1"].peer_ingress_rt
}

# ap-southeast-1
resource "aws_ec2_transit_gateway_route" "apse1_ingress_pe" {
  provider                       = aws.ap_southeast_1
  destination_cidr_block         = var.remote_cidrs["ap-southeast-1"].pe
  transit_gateway_attachment_id  = var.vpc_attachment_ids["ap-southeast-1"].pe
  transit_gateway_route_table_id = var.route_table_ids["ap-southeast-1"].peer_ingress_rt
}

resource "aws_ec2_transit_gateway_route" "apse1_ingress_npe" {
  provider                       = aws.ap_southeast_1
  destination_cidr_block         = var.remote_cidrs["ap-southeast-1"].npe
  transit_gateway_attachment_id  = var.vpc_attachment_ids["ap-southeast-1"].npe
  transit_gateway_route_table_id = var.route_table_ids["ap-southeast-1"].peer_ingress_rt
}

# ============================================================================
# STATIC ROUTES IN SPOKE RTs (OUTBOUND TO REMOTE REGIONS)
# ============================================================================

# PE Static Routes
resource "aws_ec2_transit_gateway_route" "pe_use1_to_usw2" {
  provider                       = aws.us_east_1
  destination_cidr_block         = var.remote_cidrs["us-west-2"].pe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_usw2.id
  transit_gateway_route_table_id = var.route_table_ids["us-east-1"].pe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "pe_use1_to_euw1" {
  provider                       = aws.us_east_1
  destination_cidr_block         = var.remote_cidrs["eu-west-1"].pe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_euw1.id
  transit_gateway_route_table_id = var.route_table_ids["us-east-1"].pe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "pe_use1_to_apse1" {
  provider                       = aws.us_east_1
  destination_cidr_block         = var.remote_cidrs["ap-southeast-1"].pe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["us-east-1"].pe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "pe_usw2_to_use1" {
  provider                       = aws.us_west_2
  destination_cidr_block         = var.remote_cidrs["us-east-1"].pe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_usw2.id
  transit_gateway_route_table_id = var.route_table_ids["us-west-2"].pe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "pe_usw2_to_euw1" {
  provider                       = aws.us_west_2
  destination_cidr_block         = var.remote_cidrs["eu-west-1"].pe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.usw2_to_euw1.id
  transit_gateway_route_table_id = var.route_table_ids["us-west-2"].pe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "pe_usw2_to_apse1" {
  provider                       = aws.us_west_2
  destination_cidr_block         = var.remote_cidrs["ap-southeast-1"].pe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.usw2_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["us-west-2"].pe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "pe_euw1_to_use1" {
  provider                       = aws.eu_west_1
  destination_cidr_block         = var.remote_cidrs["us-east-1"].pe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_euw1.id
  transit_gateway_route_table_id = var.route_table_ids["eu-west-1"].pe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "pe_euw1_to_usw2" {
  provider                       = aws.eu_west_1
  destination_cidr_block         = var.remote_cidrs["us-west-2"].pe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.usw2_to_euw1.id
  transit_gateway_route_table_id = var.route_table_ids["eu-west-1"].pe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "pe_euw1_to_apse1" {
  provider                       = aws.eu_west_1
  destination_cidr_block         = var.remote_cidrs["ap-southeast-1"].pe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.euw1_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["eu-west-1"].pe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "pe_apse1_to_use1" {
  provider                       = aws.ap_southeast_1
  destination_cidr_block         = var.remote_cidrs["us-east-1"].pe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["ap-southeast-1"].pe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "pe_apse1_to_usw2" {
  provider                       = aws.ap_southeast_1
  destination_cidr_block         = var.remote_cidrs["us-west-2"].pe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.usw2_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["ap-southeast-1"].pe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "pe_apse1_to_euw1" {
  provider                       = aws.ap_southeast_1
  destination_cidr_block         = var.remote_cidrs["eu-west-1"].pe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.euw1_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["ap-southeast-1"].pe.spoke_rt
}

# NPE Static Routes
resource "aws_ec2_transit_gateway_route" "npe_use1_to_usw2" {
  provider                       = aws.us_east_1
  destination_cidr_block         = var.remote_cidrs["us-west-2"].npe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_usw2.id
  transit_gateway_route_table_id = var.route_table_ids["us-east-1"].npe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "npe_use1_to_euw1" {
  provider                       = aws.us_east_1
  destination_cidr_block         = var.remote_cidrs["eu-west-1"].npe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_euw1.id
  transit_gateway_route_table_id = var.route_table_ids["us-east-1"].npe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "npe_use1_to_apse1" {
  provider                       = aws.us_east_1
  destination_cidr_block         = var.remote_cidrs["ap-southeast-1"].npe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["us-east-1"].npe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "npe_usw2_to_use1" {
  provider                       = aws.us_west_2
  destination_cidr_block         = var.remote_cidrs["us-east-1"].npe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_usw2.id
  transit_gateway_route_table_id = var.route_table_ids["us-west-2"].npe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "npe_usw2_to_euw1" {
  provider                       = aws.us_west_2
  destination_cidr_block         = var.remote_cidrs["eu-west-1"].npe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.usw2_to_euw1.id
  transit_gateway_route_table_id = var.route_table_ids["us-west-2"].npe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "npe_usw2_to_apse1" {
  provider                       = aws.us_west_2
  destination_cidr_block         = var.remote_cidrs["ap-southeast-1"].npe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.usw2_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["us-west-2"].npe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "npe_euw1_to_use1" {
  provider                       = aws.eu_west_1
  destination_cidr_block         = var.remote_cidrs["us-east-1"].npe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_euw1.id
  transit_gateway_route_table_id = var.route_table_ids["eu-west-1"].npe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "npe_euw1_to_usw2" {
  provider                       = aws.eu_west_1
  destination_cidr_block         = var.remote_cidrs["us-west-2"].npe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.usw2_to_euw1.id
  transit_gateway_route_table_id = var.route_table_ids["eu-west-1"].npe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "npe_euw1_to_apse1" {
  provider                       = aws.eu_west_1
  destination_cidr_block         = var.remote_cidrs["ap-southeast-1"].npe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.euw1_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["eu-west-1"].npe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "npe_apse1_to_use1" {
  provider                       = aws.ap_southeast_1
  destination_cidr_block         = var.remote_cidrs["us-east-1"].npe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.use1_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["ap-southeast-1"].npe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "npe_apse1_to_usw2" {
  provider                       = aws.ap_southeast_1
  destination_cidr_block         = var.remote_cidrs["us-west-2"].npe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.usw2_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["ap-southeast-1"].npe.spoke_rt
}

resource "aws_ec2_transit_gateway_route" "npe_apse1_to_euw1" {
  provider                       = aws.ap_southeast_1
  destination_cidr_block         = var.remote_cidrs["eu-west-1"].npe
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.euw1_to_apse1.id
  transit_gateway_route_table_id = var.route_table_ids["ap-southeast-1"].npe.spoke_rt
}
