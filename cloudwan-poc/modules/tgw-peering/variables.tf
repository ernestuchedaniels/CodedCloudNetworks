variable "tgw_ids" {
  description = "Map of region to Transit Gateway ID"
  type        = map(string)
}

variable "route_table_ids" {
  description = "Map of region to route table IDs"
  type = map(object({
    pe = object({
      spoke_rt       = string
      peer_export_rt = string
    })
    npe = object({
      spoke_rt       = string
      peer_export_rt = string
    })
    peer_ingress_rt = string
  }))
}

variable "remote_cidrs" {
  description = "Map of region to CIDR blocks"
  type = map(object({
    pe  = string
    npe = string
  }))
}

variable "vpc_attachment_ids" {
  description = "Map of region to VPC attachment IDs for peer_ingress_rt static routes"
  type = map(object({
    pe  = string
    npe = string
  }))
}
