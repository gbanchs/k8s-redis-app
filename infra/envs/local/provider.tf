provider "aws" {
  region                      = var.region
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  default_tags {
    tags = {
      Name        = var.name
      Environment = var.env
      Provisioner = "Terraform"
      Application = "demo"
      owners      = "devops-team"

    }
  }
}
