variable "region" {
  description = "AWS region for the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name (pe or npe)"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
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

variable "cloudwan_core_arn" {
  description = "CloudWAN Core Network ARN"
  type        = string
}

variable "use_cloudwan" {
  description = "Migration switch: false = route to TGW (default), true = route to Cloud WAN"
  type        = bool
  default     = false
}

variable "routed_cidrs" {
  description = "CIDRs to route to backbone (TGW or Cloud WAN based on use_cloudwan)"
  type        = set(string)
}

variable "my_ip" {
  description = "Your public IP for SSH access"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "SSH key pair name for EC2 instances"
  type        = string
  default     = ""
}
