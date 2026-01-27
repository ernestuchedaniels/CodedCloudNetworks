variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_attachments" {
  description = "Map of VPC attachments by segment"
  type = map(object({
    attachment_id = string
    environment   = string
  }))
}

variable "route_table_ids" {
  description = "TGW route table IDs"
  type = object({
    pe = object({
      spoke_rt        = string
      cw_export_rt    = string
      peer_export_rt  = string
    })
    npe = object({
      spoke_rt        = string
      cw_export_rt    = string
      peer_export_rt  = string
    })
  })
}

variable "vpc_cidrs" {
  description = "VPC CIDR blocks for static routes"
  type = object({
    pe  = string
    npe = string
  })
}
