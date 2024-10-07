variable "env" {
  description = "AWS Environment"
  type        = string
}

variable "cluster_name" {
  type = string
}

variable "vpc_config" {
  type = any
}

variable "cluster_version" {
  type = string
}

variable "eks_managed_node_groups" {
  type    = any
  default = []
}

# variable "node_sg" {
#   type        = string
#   description = "This is the default node SG assigned"
# }

variable "region" {}

################################################################################
# Self Managed Node Group
################################################################################

variable "self_managed_node_groups" {
  description = "Map of self-managed node group definitions to create"
  type        = any
  default     = {}
}

variable "self_managed_node_group_defaults" {
  description = "Map of self-managed node group default configurations"
  type        = any
  default     = {}
}

variable "aws_auth_roles" {
  type    = list(any)
  default = []
}

variable "aws_auth_users" {
  type    = list(any)
  default = []
}

variable "aws_auth_accounts" {
  type    = list(any)
  default = []
}



variable "tags" {
  type    = any
  default = null
}

variable "load_balancer_controller" {
  type = any
  default = {
    enabled = false
  }
}

# variable "additional_sg" {
#   type = string
# }

variable "domain_name" {
  type = string
}

variable "kms_key" {
  type = string
}


# variable "public_subnets" {
#   type = list(any)
# }

# variable "private_subnets" {
#   type = list(any)
# }

variable "intra_subnets" {
  type = list(any)
}

variable "service_account_name" {
  type    = string
  default = "aws-load-balancer-controller"
}

variable "name" {
  description = "Resource name"
  type        = string
}

variable "azs" {
  type = any
}

variable "hosted_zone" {
  type    = string
  default = null
}

variable "managed_nodes_types" {
  type    = list(string)
  default = ["t2.small", "t3.medium"]
}


variable "max_size_default" {
  type        = number
  default     = 3
  description = "Set this for the default Node Group Max Nodes size"
}

variable "min_size_default" {
  type        = number
  default     = 1
  description = "Set this for the default Node Group Min Nodes size"
}

variable "desired_size_default" {
  type        = number
  default     = 1
  description = "Set this for the default Node Group Desired Nodes size"
}


variable "config_path" {
  type    = string
  default = "~/.kube/config"
}

variable "enable_kube_prometheus_stack" {
  type    = bool
  default = false
}

variable "helm_releases" {
  default = {}
  type    = any
}

variable "db_write_host" {
  type        = string
  description = "RDS endpoint to use in helm"
  default     = ""
}

variable "enable_karpenter" {
  default     = false
  type        = bool
  description = "This Enable the karpenter Autoscaling (configurations are required)"
}

variable "nodes_sg_id" {
  default = ""
  type    = string
}
