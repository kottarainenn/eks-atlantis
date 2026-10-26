terraform {
  backend "s3" {
    key          = "atlantis/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}