terraform {
  backend "s3" {
    bucket       = "tfstate-460734939645-eu-north-1"
    key          = "demo/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}