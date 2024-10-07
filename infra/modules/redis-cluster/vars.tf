# VARIABLES
variable "env" {
  description = "Environment"
  type        = string
  default     = "sandbox"
}

variable "name" {
  description = "goliiive-core-v3"
  default     = "goliiive"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Resource Tags"
  type        = map(string)
  default = {
    "Name" = "goliiive"
  }
}


variable "cidr" {
  default = "10.12.0.0/16"
}


variable "private_subnets" {
  default = []
  type    = list(string)
  # default = ["subnet-05df761cd6705d29a","subnet-00b311eba0a099705"]
}

variable "public_subnets" {
  default = []
  type    = list(string)
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "domain_name" {
  type    = string
  default = "v3.goliiive.com"
}

variable "subdomain" {
  type    = string
  default = "sandbox"
}

variable "azs" {
  type    = any
  default = 2
}

variable "kms_key_id" {
  type        = string
  sensitive   = true
  description = "KMS key for Encrypt & Decrypt"
  default     = ""
}

variable "security_groups_id" {
  type        = string
  description = "Nodes Access to Redis"
  default     = ""
}


variable "node_type" {
  default = "cache.t4g.small"
  #"cache.t2.micro"
}


variable "vpc_cidr" {
  type    = string
  default = "10.12.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
}