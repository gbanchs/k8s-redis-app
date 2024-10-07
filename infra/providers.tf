terraform {
  required_version = ">= 1.3.2"

  required_providers {

    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = ">= 2.20.0"
      configuration_aliases = [kubernetes, ]
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"
    }


    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.69"
    }

    kubectl = {
      source                = "alekc/kubectl"
      version               = ">= 2.0"
      configuration_aliases = [kubectl, ]
    }

  }
}

provider "helm" {
  alias = "main"
  kubernetes {
    config_path = var.config_path
  }
}

provider "kubectl" {
  alias                  = "main"
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false
  config_path            = var.config_path
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "kubernetes" {
  alias                  = "main"
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}