variable "regions" {
  description = "Map of regions with CIDR base and ASN configuration"
  type = map(object({
    cidr_base = string
    asn       = number
  }))
}

variable "environments" {
  description = "Map of environments with CIDR suffix configuration"
  type = map(object({
    cidr_suffix = string
  }))
  default = {
    pe = {
      cidr_suffix = "0.0/16"
    }
    npe = {
      cidr_suffix = "16.0/20"
    }
  }
}

variable "cloudwan_asn_ranges" {
  description = "ASN ranges for CloudWAN core network"
  type        = list(string)
  default     = ["64512-64555"]
}

variable "cloudwan_segments" {
  description = "CloudWAN network segments configuration"
  type = map(object({
    description                   = string
    require_attachment_acceptance = bool
    isolate_attachments           = bool
    send_via_nfg                  = list(string)
    send_via_conditions           = list(string)
  }))
}

variable "network_function_groups" {
  description = "Network function groups for traffic inspection"
  type = map(object({
    description = string
  }))
}

variable "my_ip" {
  description = "Your public IP for SSH access to test instances"
  type        = string
  default     = "0.0.0.0/0"
}

variable "pe_use_cloudwan" {
  description = "Migration switch for PE: false = TGW (default), true = Cloud WAN"
  type        = bool
  default     = false
}

variable "npe_use_cloudwan" {
  description = "Migration switch for NPE: false = TGW (default), true = Cloud WAN"
  type        = bool
  default     = false
}
