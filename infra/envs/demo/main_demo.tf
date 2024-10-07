data "aws_caller_identity" "current" {
  provider = aws
}

provider "aws" {
  region = var.region
}

module "base" {
  source      = "../../"
  name        = "bluecore"
  env         = "demo"
  region      = var.region
  az_count    = 3
  domain_name = "bluecore.gbanchs.com"
  providers = {
    kubectl    = kubectl
    kubernetes = kubernetes
    aws        = aws
    # aws.virginia = aws.virginia
  }

  vpc_id   = ""
  vpc_cidr = "10.1.0.0/16"
  ecr_repositories = {
    python = {
      name = "python"
      lifecycle_policy = {
        rules = [{
          rulePriority = 1
          description  = "Keep last 10 images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["v1"]
            countType     = "imageCountMoreThan"
            countNumber   = 10
          }
          action = {
            type = "expire"
          }
        }]
      }
      repository_read_write_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/pipeline-role-${var.env}"]
    }
    redis-demo = {
      name = "bluecore"
      lifecycle_policy = {
        rules = [{
          rulePriority = 1
          description  = "Keep last 20 images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["v1"]
            countType     = "imageCountMoreThan"
            countNumber   = 20
          }
          action = {
            type = "expire"
          }
        }]
      }
      repository_read_write_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/pipeline-role-${var.env}",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/sa-${var.name}-${var.env}"]
    }
  }

  creation_config = {
    create_vpc           = true
    create_vpc_endpoints = true
    create_eks_cluster   = true
    create_bastion       = true
    create_redis         = true

  }

  cluster_version = "1.31"

  managed_nodes_types = ["t2.small", "t2.medium", "m5n.large", "m5zn.large"]
  #["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  max_size_default     = 3
  min_size_default     = 1
  desired_size_default = 1

  helm_releases = {
    #https://artifacthub.io/packages/helm/prometheus-community/prometheus-adapter
    #https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/#autoscaling-on-multiple-metrics-and-custom-metrics
    # prometheus-adapter = {
    #   description      = "A Helm chart for k8s prometheus adapter"
    #   namespace        = "prometheus-adapter"
    #   create_namespace = true
    #   chart            = "prometheus-adapter"
    #   chart_version    = "4.2.0"
    #   repository       = "https://prometheus-community.github.io/helm-charts"
    #   values = [
    #     <<-EOT
    #       replicas: 2
    #       podDisruptionBudget:
    #         enabled: true
    #     EOT
    #   ]
    # }
    # gpu-operator = {
    #   description      = "A Helm chart for NVIDIA GPU operator"
    #   namespace        = "gpu-operator"
    #   create_namespace = true
    #   chart            = "gpu-operator"
    #   chart_version    = "v23.9.1"
    #   repository       = "https://nvidia.github.io/gpu-operator"
    #   values = [
    #     <<-EOT
    #       operator:
    #         defaultRuntime: containerd
    #     EOT
    #   ]
    # }
  }
  config_path = "~/.kube/config"
}
