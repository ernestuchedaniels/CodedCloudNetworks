data "aws_caller_identity" "current" {}

resource "aws_networkmanager_vpc_attachment" "pe" {
  core_network_id = var.cloudwan_core_id
  subnet_arns     = [var.subnet_arns.pe]
  vpc_arn         = var.vpc_arns.pe

  tags = {
    Name        = "pe-cloudwan-${var.region}"
    Environment = "pe"
  }
}

resource "aws_networkmanager_vpc_attachment" "npe" {
  core_network_id = var.cloudwan_core_id
  subnet_arns     = [var.subnet_arns.npe]
  vpc_arn         = var.vpc_arns.npe

  tags = {
    Name        = "npe-cloudwan-${var.region}"
    Environment = "npe"
  }
}

data "aws_route_table" "pe_main" {
  vpc_id = var.vpc_ids.pe

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

data "aws_route_table" "npe_main" {
  vpc_id = var.vpc_ids.npe

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

resource "aws_route" "pe_tgw" {
  count = var.use_cloudwan ? 0 : 1

  route_table_id         = data.aws_route_table.pe_main.id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = var.tgw_id
}

resource "aws_route" "pe_cloudwan" {
  count = var.use_cloudwan ? 1 : 0

  route_table_id         = data.aws_route_table.pe_main.id
  destination_cidr_block = "10.0.0.0/8"
  core_network_arn       = var.cloudwan_core_id

  depends_on = [aws_networkmanager_vpc_attachment.pe]
}

resource "aws_route" "npe_tgw" {
  count = var.use_cloudwan ? 0 : 1

  route_table_id         = data.aws_route_table.npe_main.id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = var.tgw_id
}

resource "aws_route" "npe_cloudwan" {
  count = var.use_cloudwan ? 1 : 0

  route_table_id         = data.aws_route_table.npe_main.id
  destination_cidr_block = "10.0.0.0/8"
  core_network_arn       = var.cloudwan_core_id

  depends_on = [aws_networkmanager_vpc_attachment.npe]
}
