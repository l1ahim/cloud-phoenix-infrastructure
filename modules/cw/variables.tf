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

variable "name" {
  description = "Name of the log group"
  default     = "phoenix"
}
