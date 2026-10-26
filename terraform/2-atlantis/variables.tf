variable "github_owner" {
  type        = string
  description = "github username"
}

variable "github_token" {
  type        = string
  sensitive   = true
}

variable "github_webhook_secret" {
  type        = string
  sensitive   = true
}

variable "atlantis_chart_version" {
  type    = string
  default = "6.16.2" 
}

variable "basic_auth_username" {
  type    = string
  default = "admin"
}

variable "basic_auth_password" {
  type      = string
  sensitive = true
}