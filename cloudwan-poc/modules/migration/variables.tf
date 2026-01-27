variable "region" {
  description = "AWS region for the migration"
  type        = string
}

variable "use_cloudwan" {
  description = "Migration control flag - set to true to route through CloudWAN"
  type        = bool
  default     = false
}

variable "tgw_id" {
  description = "Transit Gateway ID"
  type        = string
}

variable "cloudwan_core_id" {
  description = "CloudWAN Core Network ID"
  type        = string
}

variable "vpc_arns" {
  description = "Map of VPC ARNs for pe and npe"
  type        = map(string)
}

variable "subnet_arns" {
  description = "Map of subnet ARNs for pe and npe"
  type        = map(string)
}

variable "vpc_ids" {
  description = "Map of VPC IDs for pe and npe"
  type        = map(string)
}
