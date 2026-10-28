variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "luminor-eks"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.36" 
}

variable "my_ip_cidr" {
  description = "Current public IP, as a /32 CIDR, for EKS API access"
  type        = string
}

variable "state_bucket_name" {
  description = "S3 bucket used for Terraform state, from 0-bootstrap"
  type        = string
}