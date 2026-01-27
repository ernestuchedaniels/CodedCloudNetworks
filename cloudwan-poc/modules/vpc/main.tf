data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_ec2_managed_prefix_list" "instance_connect" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.${var.region}.ec2-instance-connect"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc-${var.region}"
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes  = []
  }
}

resource "aws_subnet" "attachment" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 1)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.environment}-attachment-${var.region}"
    Type = "attachment"
  }

  lifecycle {
    create_before_destroy = false
    ignore_changes        = [cidr_block, availability_zone]
  }
}

resource "aws_subnet" "workload" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 2)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.environment}-workload-${var.region}"
    Type = "workload"
  }

  lifecycle {
    create_before_destroy = false
    ignore_changes        = [cidr_block, availability_zone]
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw-${var.region}"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-rt-${var.region}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "workload" {
  subnet_id      = aws_subnet.workload.id
  route_table_id = aws_route_table.main.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  subnet_ids         = [aws_subnet.attachment.id]
  transit_gateway_id = var.tgw_id
  vpc_id             = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-tgw-attachment-${var.region}"
    Environment = var.environment
  }
}

resource "aws_networkmanager_vpc_attachment" "main" {
  core_network_id = var.cloudwan_core_id
  subnet_arns     = [aws_subnet.attachment.arn]
  vpc_arn         = aws_vpc.main.arn

  tags = {
    Name        = "${var.environment}-cloudwan-attachment-${var.region}"
    Environment = var.environment
  }
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Migration switch: Route environment CIDRs to TGW (default) or Cloud WAN
resource "aws_route" "backbone_routes" {
  for_each               = var.routed_cidrs
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = each.value

  transit_gateway_id = var.use_cloudwan ? null : var.tgw_id
  core_network_arn   = var.use_cloudwan ? var.cloudwan_core_arn : null

  depends_on = [aws_networkmanager_vpc_attachment.main, aws_ec2_transit_gateway_vpc_attachment.main]
}

resource "aws_security_group" "test" {
  name        = "${var.environment}-test-${var.region}"
  description = "Allow SSH and ICMP for connectivity testing"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.instance_connect.id]
    description     = "SSH from EC2 Instance Connect"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from anywhere"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "ICMP from 10.0.0.0/8"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "SSH from 10.0.0.0/8"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-test-sg-${var.region}"
  }
}

resource "aws_instance" "test" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.workload.id
  vpc_security_group_ids      = [aws_security_group.test.id]
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nc
              echo "${var.environment}-${var.region}" > /etc/hostname
              hostname ${var.environment}-${var.region}
              EOF

  tags = {
    Name        = "${var.environment}-test-${var.region}"
    Environment = var.environment
  }
}
