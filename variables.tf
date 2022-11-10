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

variable "github_repo" {
  description = "URL of GitHUB repository"
  type        = string
  default     = "https://github.com/l1ahim/cloud-phoenix-app"
}

variable "github_repo_name" {
  description = "GitHUB repository name"
  type        = string
  default     = "cloud-phoenix-app"
}

variable "github_owner" {
  description = "GitHUB repo owner"
  type        = string
  default     = "l1ahim"
}

variable "github_oauth_token" {
  description = "GitHUB token"
  type        = string
  default     = "token"
}

variable "db_connection_string" {
  description = "DB connection string"
  type        = string
  default     = "test"
}

variable "repo_branch" {
  description = "Repository branch to use for build"
  type        = string
  default     = "main"
}
