# VARIABLES
variable "env" {
  description = "AWS Environment"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "name" {
  description = "Resource name"
  type        = string
  default     = "bluecore"
}

variable "tags" {
  description = "Tags for the resources"
  default = {
    Environment = "demo"
    Provisioner = "Terraform"
    Application = "bluecore"
  }
}

variable "AWS_ROLE_TO_ASSUME" {
  description = "AWS role to assume for resource provisioning"
  sensitive   = true
  type        = string
  default     = ""
}

variable "AWS_ROLE_EXTERNAL_ID" {
  description = "External ID for assuming AWS role"
  sensitive   = true
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
  default     = ""
}


variable "cluster_version" {
  description = "Version of the EKS cluster"
  type        = string
  default     = "1.31" # Latest version at 07/17/2024
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "manage_aws_auth_configmap" {
  description = "Whether to manage the AWS auth ConfigMap"
  default     = true
}

variable "managed_nodes_types" {
  description = "List of EC2 instance types for managed nodes"
  type        = list(string)
  default     = ["t2.small", "t3.medium"]
}

variable "max_size_default" {
  description = "Maximum number of nodes for the default Node Group"
  type        = number
  default     = 3
}

variable "min_size_default" {
  description = "Minimum number of nodes for the default Node Group"
  type        = number
  default     = 1
}

variable "desired_size_default" {
  description = "Desired number of nodes for the default Node Group"
  type        = number
  default     = 2
}

variable "config_path" {
  description = "Path to the kubeconfig file"
  default     = "~/.kube/config"
}

variable "enable_kube_prometheus_stack" {
  description = "Whether to enable the kube-prometheus-stack"
  default     = false
  type        = bool
}



variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = []
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for the cluster"
  type        = string
  default     = ""
}

variable "helm_releases" {
  description = "Map of configurations for each Helm release"
  default     = {}
}

variable "db_config" {
  description = "Map of RDS instance configurations"
  type        = any
  default     = {}
}

variable "enable_karpenter" {
  description = "Whether to enable karpenter Autoscaling (configurations are required)"
  default     = false
  type        = bool
}

variable "creation_config" {
  description = "Map of creation configurations"
  type        = any
  default     = {}
}


variable "ecr_repositories" {
  description = "Map of configurations for each ECR repository"
  type = map(object({
    name                       = string
    lifecycle_policy           = map(any)
    repository_read_write_arns = list(string)
  }))
}