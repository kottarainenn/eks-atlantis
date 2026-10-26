provider "aws" {
  region = "eu-north-1"
  default_tags {
    tags = {
      project   = "luminor-eks-atlantis"
      managedBy = "terraform"
    }
  }
}

provider "helm" {
  kubernetes = {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = base64decode(local.cluster_ca)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    }
  }
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = base64decode(local.cluster_ca)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
  }
}

provider "github" {
  owner = var.github_owner
  token = var.github_token
}