variable "region" {
  description = "AWS region where to deploy the infrastructure"
  default     = "us-east-1"
}

variable "namespace" {
  description = "Abbreviation of org name"
  type        = string
  default     = "cl"
}

variable "stage" {
  description = "Environment role"
  type        = string
  default     = "prod"
}

variable "log_group_name" {
  description = "Name of the log group"
  default     = "phoenix"
}

variable "prefix" {
  description = "Prefix to use for Phoenix application in production"
  type        = string
  default     = "cl-phoenix-prd"
}

variable "nat_enabled" {
  description = "Create NAT GW or not - created on public subnets but used for private subnets"
  type        = bool
  default     = false
}

variable "vpc_name" {
  description = "Name of AWS VPC where Phoenix app is hosted"
  type        = string
  default     = "vpc"
}

variable "vpc_cidr_block" {
  description = "CIDR block of VPC - this will be divided into subnet CIDR blocks"
  type        = string
  default     = "10.0.0.0/16"
}

variable "name" {
  description = "Name of the application"
  default     = "phoenix"
}

variable "flow_log_enabled" {
  description = "Enable or disable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "availability_zones" {
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "subnet_type_public" {
  description = "Public subnet"
  type        = string
  default     = "public"
}

variable "subnet_type_private" {
  description = "Private subnet"
  type        = string
  default     = "private"
}

variable "image_repo_name" {
  description = "ECR repository name to store the Docker image built by this module. Used as CodeBuild ENV variable when building Docker images. [For more info](http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html)"
  type        = string
  default     = "phoenix"
}



###############
# ALB
##############
variable "internal" {
  type        = bool
  description = "A boolean flag to determine whether the ALB should be internal"
}

variable "http_enabled" {
  type        = bool
  description = "A boolean flag to enable/disable HTTP listener"
}

variable "http_redirect" {
  type        = bool
  description = "A boolean flag to enable/disable HTTP redirect to HTTPS"
}

variable "access_logs_enabled" {
  type        = bool
  description = "A boolean flag to enable/disable access_logs"
}

variable "cross_zone_load_balancing_enabled" {
  type        = bool
  description = "A boolean flag to enable/disable cross zone load balancing"
}

variable "http2_enabled" {
  type        = bool
  description = "A boolean flag to enable/disable HTTP/2"
}

variable "idle_timeout" {
  type        = number
  description = "The time in seconds that the connection is allowed to be idle"
}

variable "ip_address_type" {
  type        = string
  description = "The type of IP addresses used by the subnets for your load balancer. The possible values are `ipv4` and `dualstack`."
}

variable "deletion_protection_enabled" {
  type        = bool
  description = "A boolean flag to enable/disable deletion protection for ALB"
}

variable "deregistration_delay" {
  type        = number
  description = "The amount of time to wait in seconds before changing the state of a deregistering target to unused"
}

variable "health_check_path" {
  type        = string
  description = "The destination for the health check request"
}

variable "health_check_timeout" {
  type        = number
  description = "The amount of time to wait in seconds before failing a health check request"
}

variable "health_check_healthy_threshold" {
  type        = number
  description = "The number of consecutive health checks successes required before considering an unhealthy target healthy"
}

variable "health_check_unhealthy_threshold" {
  type        = number
  description = "The number of consecutive health check failures required before considering the target unhealthy"
}

variable "health_check_interval" {
  type        = number
  description = "The duration in seconds in between health checks"
}

variable "health_check_matcher" {
  type        = string
  description = "The HTTP response codes to indicate a healthy check"
}

variable "alb_access_logs_s3_bucket_force_destroy" {
  type        = bool
  description = "A boolean that indicates all objects should be deleted from the ALB access logs S3 bucket so that the bucket can be destroyed without error"
}

variable "alb_access_logs_s3_bucket_force_destroy_enabled" {
  type        = bool
  description = "Force destroy s3 bucket"
    default = true
}

variable "target_group_port" {
  type        = number
  description = "The port for the default target group"
}

variable "target_group_target_type" {
  type        = string
  description = "The type (`instance`, `ip` or `lambda`) of targets that can be registered with the target group"
}

variable "stickiness" {
  type = object({
    cookie_duration = number
    enabled         = bool
  })
  description = "Target group sticky configuration"
}
