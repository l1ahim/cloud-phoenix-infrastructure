variable "prefix" {
  description = "Prefix to use for Phoenix application in production"
  type        = string
  default     = "cl-phoenix-prd"
}

variable nat_enabled {
  description = "Create NAT GW or not - created on public subnets but used for private subnets"
  type = bool
  default = false
}

variable "vpc_name" {
  description = "Name of AWS VPC where Phoenix app is hosted"
  type        = string
  default     = "vpc"
}

variable vpc_cidr_block {
  description = "CIDR block of VPC"
  type = string
  default = "10.0.0.0/16"
}

variable "namespace" {
  description = "Abbreviation of org name"
  type        = string
  default     = "cl"
}

variable "stage" {
  description = "Environment role"
  type        = string
  default     = "dev"
}

variable "name" {
  description = "Name of the application"
  default     = "phoenix"
}

variable "cidr_block" {
  description = "Base CIDR block which will be divided into subnet CIDR blocks"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable subnet_type_public {
  description = "Public subnet"
  type = string
  default = "public"
}

variable subnet_type_private {
  description = "Private subnet"
  type = string
  default = "private"
}
