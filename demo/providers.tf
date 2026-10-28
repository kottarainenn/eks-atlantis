provider "aws" {
  region = "eu-north-1"
  default_tags {
    tags = {
      Project   = "luminor-eks-atlantis"
      ManagedBy = "atlantis"
    }
  }
}