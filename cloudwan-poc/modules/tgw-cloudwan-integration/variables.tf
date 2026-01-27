variable "region" {
  description = "AWS region for the integration"
  type        = string
}

variable "tgw_arn" {
  description = "Transit Gateway ARN"
  type        = string
}

variable "tgw_id" {
  description = "Transit Gateway ID"
  type        = string
}

variable "cloudwan_core_id" {
  description = "CloudWAN Core Network ID"
  type        = string
}

variable "segment_route_tables" {
  description = "Map of segment names to TGW route table ARNs for Cloud WAN export (cw_export_rt)"
  type        = map(string)
  
  validation {
    condition     = length(var.segment_route_tables) > 0
    error_message = "At least one segment route table mapping is required."
  }
}

variable "spoke_route_table_ids" {
  description = "Map of segment names to TGW spoke route table IDs for Cloud WAN propagation"
  type        = map(string)
}
