provider "aws" {
  region = "eu-north-1"

  default_tags {
    tags = {
      project   = "luminor-eks-atlantis"
      managedBy = "terraform"
    }
  }
}