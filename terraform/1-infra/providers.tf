provider "aws" {
  region = "eu-north-1"

  default_tags {
    tags = {
      project   = "luminor-eks-atlantis"
      owner     = "maria"
      managedBy = "terraform"
    }
  }
}