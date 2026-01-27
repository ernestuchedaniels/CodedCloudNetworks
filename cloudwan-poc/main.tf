terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "ap_southeast_1"
  region = "ap-southeast-1"
}

# TGW Modules - One per region
module "tgw_us_east_1" {
  source = "./modules/tgw"
  providers = {
    aws = aws.us_east_1
  }
  region = "us-east-1"
}

module "tgw_us_west_2" {
  source = "./modules/tgw"
  providers = {
    aws = aws.us_west_2
  }
  region = "us-west-2"
}

module "tgw_eu_west_1" {
  source = "./modules/tgw"
  providers = {
    aws = aws.eu_west_1
  }
  region = "eu-west-1"
}

module "tgw_ap_southeast_1" {
  source = "./modules/tgw"
  providers = {
    aws = aws.ap_southeast_1
  }
  region = "ap-southeast-1"
}

# TGW Peering - Full mesh peering between all regions
module "tgw_peering" {
  source = "./modules/tgw-peering"
  providers = {
    aws.us_east_1      = aws.us_east_1
    aws.us_west_2      = aws.us_west_2
    aws.eu_west_1      = aws.eu_west_1
    aws.ap_southeast_1 = aws.ap_southeast_1
  }
  tgw_ids = {
    "us-east-1"      = module.tgw_us_east_1.tgw_id
    "us-west-2"      = module.tgw_us_west_2.tgw_id
    "eu-west-1"      = module.tgw_eu_west_1.tgw_id
    "ap-southeast-1" = module.tgw_ap_southeast_1.tgw_id
  }
  route_table_ids = {
    "us-east-1" = {
      pe = {
        spoke_rt       = module.tgw_us_east_1.route_table_ids.pe
        peer_export_rt = module.tgw_us_east_1.peer_export_route_table_ids.pe
      }
      npe = {
        spoke_rt       = module.tgw_us_east_1.route_table_ids.npe
        peer_export_rt = module.tgw_us_east_1.peer_export_route_table_ids.npe
      }
      peer_ingress_rt = module.tgw_us_east_1.peer_ingress_route_table_id
    }
    "us-west-2" = {
      pe = {
        spoke_rt       = module.tgw_us_west_2.route_table_ids.pe
        peer_export_rt = module.tgw_us_west_2.peer_export_route_table_ids.pe
      }
      npe = {
        spoke_rt       = module.tgw_us_west_2.route_table_ids.npe
        peer_export_rt = module.tgw_us_west_2.peer_export_route_table_ids.npe
      }
      peer_ingress_rt = module.tgw_us_west_2.peer_ingress_route_table_id
    }
    "eu-west-1" = {
      pe = {
        spoke_rt       = module.tgw_eu_west_1.route_table_ids.pe
        peer_export_rt = module.tgw_eu_west_1.peer_export_route_table_ids.pe
      }
      npe = {
        spoke_rt       = module.tgw_eu_west_1.route_table_ids.npe
        peer_export_rt = module.tgw_eu_west_1.peer_export_route_table_ids.npe
      }
      peer_ingress_rt = module.tgw_eu_west_1.peer_ingress_route_table_id
    }
    "ap-southeast-1" = {
      pe = {
        spoke_rt       = module.tgw_ap_southeast_1.route_table_ids.pe
        peer_export_rt = module.tgw_ap_southeast_1.peer_export_route_table_ids.pe
      }
      npe = {
        spoke_rt       = module.tgw_ap_southeast_1.route_table_ids.npe
        peer_export_rt = module.tgw_ap_southeast_1.peer_export_route_table_ids.npe
      }
      peer_ingress_rt = module.tgw_ap_southeast_1.peer_ingress_route_table_id
    }
  }
  vpc_attachment_ids = {
    "us-east-1"      = { pe = module.vpc_pe_us_east_1.tgw_attachment_id, npe = module.vpc_npe_us_east_1.tgw_attachment_id }
    "us-west-2"      = { pe = module.vpc_pe_us_west_2.tgw_attachment_id, npe = module.vpc_npe_us_west_2.tgw_attachment_id }
    "eu-west-1"      = { pe = module.vpc_pe_eu_west_1.tgw_attachment_id, npe = module.vpc_npe_eu_west_1.tgw_attachment_id }
    "ap-southeast-1" = { pe = module.vpc_pe_ap_southeast_1.tgw_attachment_id, npe = module.vpc_npe_ap_southeast_1.tgw_attachment_id }
  }
  remote_cidrs = {
    "us-east-1"      = { pe = "10.1.0.0/16", npe = "10.101.0.0/16" }
    "us-west-2"      = { pe = "10.2.0.0/16", npe = "10.102.0.0/16" }
    "eu-west-1"      = { pe = "10.3.0.0/16", npe = "10.103.0.0/16" }
    "ap-southeast-1" = { pe = "10.4.0.0/16", npe = "10.104.0.0/16" }
  }
  depends_on = [
    module.tgw_us_east_1,
    module.tgw_us_west_2,
    module.tgw_eu_west_1,
    module.tgw_ap_southeast_1,
    module.vpc_pe_us_east_1,
    module.vpc_npe_us_east_1,
    module.vpc_pe_us_west_2,
    module.vpc_npe_us_west_2,
    module.vpc_pe_eu_west_1,
    module.vpc_npe_eu_west_1,
    module.vpc_pe_ap_southeast_1,
    module.vpc_npe_ap_southeast_1
  ]
}

# OLD TGW Routing Module - DISABLED (replaced by new per-region tgw-routing modules below)
# This old module was for managing TGW peering static routes.
# The NEW tgw-routing modules (see bottom of file) handle VPC attachment associations/propagations.
#
# module "tgw_routing" {
#   source = "./modules/tgw-routing"
#   providers = {
#     aws.us_east_1      = aws.us_east_1
#     aws.us_west_2      = aws.us_west_2
#     aws.eu_west_1      = aws.eu_west_1
#     aws.ap_southeast_1 = aws.ap_southeast_1
#   }
#   tgw_ids = {
#     "us-east-1"      = module.tgw_us_east_1.tgw_id
#     "us-west-2"      = module.tgw_us_west_2.tgw_id
#     "eu-west-1"      = module.tgw_eu_west_1.tgw_id
#     "ap-southeast-1" = module.tgw_ap_southeast_1.tgw_id
#   }
#   route_table_ids = {
#     "us-east-1"      = module.tgw_us_east_1.route_table_ids
#     "us-west-2"      = module.tgw_us_west_2.route_table_ids
#     "eu-west-1"      = module.tgw_eu_west_1.route_table_ids
#     "ap-southeast-1" = module.tgw_ap_southeast_1.route_table_ids
#   }
#   peering_attachment_ids = module.tgw_peering.peering_connections
#   depends_on             = [module.tgw_peering]
# }

# CloudWAN Module - Creates global network overlay
module "cloudwan" {
  source = "./modules/cloudwan"
  providers = {
    aws = aws.us_east_1
  }
  regions                 = var.regions
  segments                = var.cloudwan_segments
  network_function_groups = var.network_function_groups
}

# TGW-CloudWAN Integration - One peering per region with route table attachments for segment isolation
module "tgw_cloudwan_us_east_1" {
  source = "./modules/tgw-cloudwan-integration"
  providers = {
    aws = aws.us_east_1
  }
  region           = "us-east-1"
  tgw_id           = module.tgw_us_east_1.tgw_id
  tgw_arn          = module.tgw_us_east_1.tgw_arn
  cloudwan_core_id = module.cloudwan.core_network_id
  segment_route_tables = {
    pe  = module.tgw_us_east_1.cw_export_route_table_arns.pe
    npe = module.tgw_us_east_1.cw_export_route_table_arns.npe
  }
  spoke_route_table_ids = {
    pe  = module.tgw_us_east_1.route_table_ids.pe
    npe = module.tgw_us_east_1.route_table_ids.npe
  }
  depends_on = [module.cloudwan, module.tgw_us_east_1]
}

module "tgw_cloudwan_us_west_2" {
  source = "./modules/tgw-cloudwan-integration"
  providers = {
    aws = aws.us_west_2
  }
  region           = "us-west-2"
  tgw_id           = module.tgw_us_west_2.tgw_id
  tgw_arn          = module.tgw_us_west_2.tgw_arn
  cloudwan_core_id = module.cloudwan.core_network_id
  segment_route_tables = {
    pe  = module.tgw_us_west_2.cw_export_route_table_arns.pe
    npe = module.tgw_us_west_2.cw_export_route_table_arns.npe
  }
  spoke_route_table_ids = {
    pe  = module.tgw_us_west_2.route_table_ids.pe
    npe = module.tgw_us_west_2.route_table_ids.npe
  }
  depends_on = [module.cloudwan, module.tgw_us_west_2]
}

module "tgw_cloudwan_eu_west_1" {
  source = "./modules/tgw-cloudwan-integration"
  providers = {
    aws = aws.eu_west_1
  }
  region           = "eu-west-1"
  tgw_id           = module.tgw_eu_west_1.tgw_id
  tgw_arn          = module.tgw_eu_west_1.tgw_arn
  cloudwan_core_id = module.cloudwan.core_network_id
  segment_route_tables = {
    pe  = module.tgw_eu_west_1.cw_export_route_table_arns.pe
    npe = module.tgw_eu_west_1.cw_export_route_table_arns.npe
  }
  spoke_route_table_ids = {
    pe  = module.tgw_eu_west_1.route_table_ids.pe
    npe = module.tgw_eu_west_1.route_table_ids.npe
  }
  depends_on = [module.cloudwan, module.tgw_eu_west_1]
}

module "tgw_cloudwan_ap_southeast_1" {
  source = "./modules/tgw-cloudwan-integration"
  providers = {
    aws = aws.ap_southeast_1
  }
  region           = "ap-southeast-1"
  tgw_id           = module.tgw_ap_southeast_1.tgw_id
  tgw_arn          = module.tgw_ap_southeast_1.tgw_arn
  cloudwan_core_id = module.cloudwan.core_network_id
  segment_route_tables = {
    pe  = module.tgw_ap_southeast_1.cw_export_route_table_arns.pe
    npe = module.tgw_ap_southeast_1.cw_export_route_table_arns.npe
  }
  spoke_route_table_ids = {
    pe  = module.tgw_ap_southeast_1.route_table_ids.pe
    npe = module.tgw_ap_southeast_1.route_table_ids.npe
  }
  depends_on = [module.cloudwan, module.tgw_ap_southeast_1]
}

# VPC Modules - 4 PE + 4 NPE (one per region per environment)
module "vpc_pe_us_east_1" {
  source = "./modules/vpc"
  providers = {
    aws = aws.us_east_1
  }
  region            = "us-east-1"
  environment       = "pe"
  cidr_block        = "${var.regions["us-east-1"].cidr_base}.0.0/16"
  tgw_id            = module.tgw_us_east_1.tgw_id
  cloudwan_core_id  = module.cloudwan.core_network_id
  cloudwan_core_arn = module.cloudwan.core_network_arn
  use_cloudwan      = var.pe_use_cloudwan
  routed_cidrs      = ["10.0.0.0/13"]
  depends_on        = [module.cloudwan, module.tgw_us_east_1]
}

module "vpc_npe_us_east_1" {
  source = "./modules/vpc"
  providers = {
    aws = aws.us_east_1
  }
  region            = "us-east-1"
  environment       = "npe"
  cidr_block        = "10.101.0.0/16"
  tgw_id            = module.tgw_us_east_1.tgw_id
  cloudwan_core_id  = module.cloudwan.core_network_id
  cloudwan_core_arn = module.cloudwan.core_network_arn
  my_ip             = var.my_ip
  use_cloudwan      = var.npe_use_cloudwan
  routed_cidrs      = ["10.96.0.0/12"]
  depends_on        = [module.cloudwan, module.tgw_us_east_1]
}

module "vpc_pe_us_west_2" {
  source = "./modules/vpc"
  providers = {
    aws = aws.us_west_2
  }
  region            = "us-west-2"
  environment       = "pe"
  cidr_block        = "${var.regions["us-west-2"].cidr_base}.0.0/16"
  tgw_id            = module.tgw_us_west_2.tgw_id
  cloudwan_core_id  = module.cloudwan.core_network_id
  cloudwan_core_arn = module.cloudwan.core_network_arn
  my_ip             = var.my_ip
  use_cloudwan      = var.pe_use_cloudwan
  routed_cidrs      = ["10.0.0.0/13"]
  depends_on        = [module.cloudwan, module.tgw_us_west_2]
}

module "vpc_npe_us_west_2" {
  source = "./modules/vpc"
  providers = {
    aws = aws.us_west_2
  }
  region            = "us-west-2"
  environment       = "npe"
  cidr_block        = "10.102.0.0/16"
  tgw_id            = module.tgw_us_west_2.tgw_id
  cloudwan_core_id  = module.cloudwan.core_network_id
  cloudwan_core_arn = module.cloudwan.core_network_arn
  my_ip             = var.my_ip
  use_cloudwan      = var.npe_use_cloudwan
  routed_cidrs      = ["10.96.0.0/12"]
  depends_on        = [module.cloudwan, module.tgw_us_west_2]
}

module "vpc_pe_eu_west_1" {
  source = "./modules/vpc"
  providers = {
    aws = aws.eu_west_1
  }
  region            = "eu-west-1"
  environment       = "pe"
  cidr_block        = "${var.regions["eu-west-1"].cidr_base}.0.0/16"
  tgw_id            = module.tgw_eu_west_1.tgw_id
  cloudwan_core_id  = module.cloudwan.core_network_id
  cloudwan_core_arn = module.cloudwan.core_network_arn
  my_ip             = var.my_ip
  use_cloudwan      = var.pe_use_cloudwan
  routed_cidrs      = ["10.0.0.0/13"]
  depends_on        = [module.cloudwan, module.tgw_eu_west_1]
}

module "vpc_npe_eu_west_1" {
  source = "./modules/vpc"
  providers = {
    aws = aws.eu_west_1
  }
  region            = "eu-west-1"
  environment       = "npe"
  cidr_block        = "10.103.0.0/16"
  tgw_id            = module.tgw_eu_west_1.tgw_id
  cloudwan_core_id  = module.cloudwan.core_network_id
  cloudwan_core_arn = module.cloudwan.core_network_arn
  my_ip             = var.my_ip
  use_cloudwan      = var.npe_use_cloudwan
  routed_cidrs      = ["10.96.0.0/12"]
  depends_on        = [module.cloudwan, module.tgw_eu_west_1]
}

module "vpc_pe_ap_southeast_1" {
  source = "./modules/vpc"
  providers = {
    aws = aws.ap_southeast_1
  }
  region            = "ap-southeast-1"
  environment       = "pe"
  cidr_block        = "${var.regions["ap-southeast-1"].cidr_base}.0.0/16"
  tgw_id            = module.tgw_ap_southeast_1.tgw_id
  cloudwan_core_id  = module.cloudwan.core_network_id
  cloudwan_core_arn = module.cloudwan.core_network_arn
  my_ip             = var.my_ip
  use_cloudwan      = var.pe_use_cloudwan
  routed_cidrs      = ["10.0.0.0/13"]
  depends_on        = [module.cloudwan, module.tgw_ap_southeast_1]
}

module "vpc_npe_ap_southeast_1" {
  source = "./modules/vpc"
  providers = {
    aws = aws.ap_southeast_1
  }
  region            = "ap-southeast-1"
  environment       = "npe"
  cidr_block        = "10.104.0.0/16"
  tgw_id            = module.tgw_ap_southeast_1.tgw_id
  cloudwan_core_id  = module.cloudwan.core_network_id
  cloudwan_core_arn = module.cloudwan.core_network_arn
  my_ip             = var.my_ip
  use_cloudwan      = var.npe_use_cloudwan
  routed_cidrs      = ["10.96.0.0/12"]
  depends_on        = [module.cloudwan, module.tgw_ap_southeast_1]
}

# TGW Routing - VPC attachment associations and propagations
module "tgw_routing_us_east_1" {
  source = "./modules/tgw-routing"
  providers = {
    aws = aws.us_east_1
  }
  region = "us-east-1"
  vpc_attachments = {
    pe  = { attachment_id = module.vpc_pe_us_east_1.tgw_attachment_id, environment = "pe" }
    npe = { attachment_id = module.vpc_npe_us_east_1.tgw_attachment_id, environment = "npe" }
  }
  vpc_cidrs = {
    pe  = "10.1.0.0/16"
    npe = "10.101.0.0/16"
  }
  route_table_ids = {
    pe = {
      spoke_rt       = module.tgw_us_east_1.route_table_ids.pe
      cw_export_rt   = module.tgw_us_east_1.cw_export_route_table_ids.pe
      peer_export_rt = module.tgw_us_east_1.peer_export_route_table_ids.pe
    }
    npe = {
      spoke_rt       = module.tgw_us_east_1.route_table_ids.npe
      cw_export_rt   = module.tgw_us_east_1.cw_export_route_table_ids.npe
      peer_export_rt = module.tgw_us_east_1.peer_export_route_table_ids.npe
    }
  }
  depends_on = [module.vpc_pe_us_east_1, module.vpc_npe_us_east_1]
}

module "tgw_routing_us_west_2" {
  source = "./modules/tgw-routing"
  providers = {
    aws = aws.us_west_2
  }
  region = "us-west-2"
  vpc_attachments = {
    pe  = { attachment_id = module.vpc_pe_us_west_2.tgw_attachment_id, environment = "pe" }
    npe = { attachment_id = module.vpc_npe_us_west_2.tgw_attachment_id, environment = "npe" }
  }
  vpc_cidrs = {
    pe  = "10.2.0.0/16"
    npe = "10.102.0.0/16"
  }
  route_table_ids = {
    pe = {
      spoke_rt       = module.tgw_us_west_2.route_table_ids.pe
      cw_export_rt   = module.tgw_us_west_2.cw_export_route_table_ids.pe
      peer_export_rt = module.tgw_us_west_2.peer_export_route_table_ids.pe
    }
    npe = {
      spoke_rt       = module.tgw_us_west_2.route_table_ids.npe
      cw_export_rt   = module.tgw_us_west_2.cw_export_route_table_ids.npe
      peer_export_rt = module.tgw_us_west_2.peer_export_route_table_ids.npe
    }
  }
  depends_on = [module.vpc_pe_us_west_2, module.vpc_npe_us_west_2]
}

module "tgw_routing_eu_west_1" {
  source = "./modules/tgw-routing"
  providers = {
    aws = aws.eu_west_1
  }
  region = "eu-west-1"
  vpc_attachments = {
    pe  = { attachment_id = module.vpc_pe_eu_west_1.tgw_attachment_id, environment = "pe" }
    npe = { attachment_id = module.vpc_npe_eu_west_1.tgw_attachment_id, environment = "npe" }
  }
  vpc_cidrs = {
    pe  = "10.3.0.0/16"
    npe = "10.103.0.0/16"
  }
  route_table_ids = {
    pe = {
      spoke_rt       = module.tgw_eu_west_1.route_table_ids.pe
      cw_export_rt   = module.tgw_eu_west_1.cw_export_route_table_ids.pe
      peer_export_rt = module.tgw_eu_west_1.peer_export_route_table_ids.pe
    }
    npe = {
      spoke_rt       = module.tgw_eu_west_1.route_table_ids.npe
      cw_export_rt   = module.tgw_eu_west_1.cw_export_route_table_ids.npe
      peer_export_rt = module.tgw_eu_west_1.peer_export_route_table_ids.npe
    }
  }
  depends_on = [module.vpc_pe_eu_west_1, module.vpc_npe_eu_west_1]
}

module "tgw_routing_ap_southeast_1" {
  source = "./modules/tgw-routing"
  providers = {
    aws = aws.ap_southeast_1
  }
  region = "ap-southeast-1"
  vpc_attachments = {
    pe  = { attachment_id = module.vpc_pe_ap_southeast_1.tgw_attachment_id, environment = "pe" }
    npe = { attachment_id = module.vpc_npe_ap_southeast_1.tgw_attachment_id, environment = "npe" }
  }
  vpc_cidrs = {
    pe  = "10.4.0.0/16"
    npe = "10.104.0.0/16"
  }
  route_table_ids = {
    pe = {
      spoke_rt       = module.tgw_ap_southeast_1.route_table_ids.pe
      cw_export_rt   = module.tgw_ap_southeast_1.cw_export_route_table_ids.pe
      peer_export_rt = module.tgw_ap_southeast_1.peer_export_route_table_ids.pe
    }
    npe = {
      spoke_rt       = module.tgw_ap_southeast_1.route_table_ids.npe
      cw_export_rt   = module.tgw_ap_southeast_1.cw_export_route_table_ids.npe
      peer_export_rt = module.tgw_ap_southeast_1.peer_export_route_table_ids.npe
    }
  }
  depends_on = [module.vpc_pe_ap_southeast_1, module.vpc_npe_ap_southeast_1]
}
