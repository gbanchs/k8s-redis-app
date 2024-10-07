terraform {
  required_version = ">= 1.7.5"

  required_providers {

    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = ">= 2.20.0"
      configuration_aliases = [kubernetes]
    }
    helm = {
      source                = "hashicorp/helm"
      version               = ">= 2.9.0"
      configuration_aliases = [helm]
    }

    aws = {
      source = "hashicorp/aws"
      # version = ">= 5.40"
      # configuration_aliases = [aws.virginia]
    }

    kubectl = {
      source                = "alekc/kubectl"
      configuration_aliases = [kubectl]
      # version = ">= 2.0"
    }

  }
}



# provider "kubectl" {
#   alias = "main"
# }

# provider "helm" {
#   alias = "main"
# }

# provider "kubernetes" {
#   alias = "main"
# }