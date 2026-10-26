data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = trimspace(file("${path.module}/../1-infra/backend.hcl")) != "" ? regex("bucket\\s*=\\s*\"([^\"]+)\"", file("${path.module}/../1-infra/backend.hcl"))[0] : ""
    key    = "infra/terraform.tfstate"
    region = "eu-north-1"
  }
}

locals {
  cluster_name     = data.terraform_remote_state.infra.outputs.cluster_name
  cluster_endpoint = data.terraform_remote_state.infra.outputs.cluster_endpoint
  cluster_ca       = data.terraform_remote_state.infra.outputs.cluster_certificate_authority_data
}