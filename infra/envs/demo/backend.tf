terraform {
  required_version = ">=1.7.5"
  backend "s3" {
    bucket = "tf-bluecore-state-demo"
    key    = "state/demo"
    # NOTE: This is the region the state s3 bucket is in,
    # not the region the aws provider will deploy into
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
    # assume_role = {
    #   role_arn = "arn:aws:iam::461315342688:role/bitbucket-pipeline"
    # }
  }


  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.53.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0"
      # configuration_aliases = [kubectl.main, ]
    }
  }

}

