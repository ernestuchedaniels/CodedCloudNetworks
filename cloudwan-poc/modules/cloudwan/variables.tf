variable "regions" {
  description = "Map of regions with CIDR base and ASN configuration"
  type = map(object({
    cidr_base = string
    asn       = number
  }))
}

variable "segments" {
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
