variable "aws_region" {
  description = "AWS region used by the proof of concept"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used to identify the AWS resources"
  type        = string
  default     = "secure-terraform-poc"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the VPC"
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "admin_cidr" {
  description = "Trusted administrator public IPv4 address in /32 format"
  type        = string
  sensitive   = true

  validation {
    condition = (
      can(cidrhost(var.admin_cidr, 0)) &&
      can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}/32$", var.admin_cidr))
    )

    error_message = "admin_cidr must be a valid single-host IPv4 /32 CIDR, such as 203.0.113.10/32."
  }
}