variable "source_credential_auth_type" {
    description = "The type of authentication used to connect to GitHub"
    type        = string
    default     = "PERSONAL_ACCESS_TOKEN"
}

variable "source_credential_server_type" {
    description = "The source provider used for this project"
    type        = string
    default     = "GITHUB"
}

variable "source_credential_token" {
    description = "For GitHub, this is the personal access token"
    type        = string
    default     = "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"
}

variable "app_name" {
    description = "Name of the application"
    type        = string
    default     = "phoenix"
}

variable "github_repo" {
  description = "URL of GitHUB repository"
  type        = string
}

variable "github_repo_name" {
  description = "GitHUB repository name"
  type        = string
}

variable "github_owner" {
  description = "GitHUB repo owner"
  type        = string
}

variable "github_oauth_token" {
  description = "GitHUB token"
  type        = string
}

variable "security_group_ids" {
    description = "list of security groups"
    type        = list
}

variable "private_subnets" {
      description = "list of privat subnets id"
  type        = list
}

variable "vpc_id" {
    description = "VPC ID"
  type = string
}

variable "tags" {
    description = "Tags applied to policies"
    type = map
}

variable "buildspec" {
      description = "Buildspec to use for building the project"
  type        = string
  default     = ""
}

variable "db_connection_string" {
  description = "DB connection string"
  type        = string
  default = ""
}

variable "repo_source_version" {
  description = "Repository branch to use for build"
  type        = string
  default = ""
}

variable "iam_policy_path" {
  type        = string
  default     = "/service-role/"
  description = "Path to the policy."
}
