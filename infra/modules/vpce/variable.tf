
# VARIABLES
variable "env" {
  description = "AWS Environment"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Resource name"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "private_subnets" {
  type = list(any)

}

variable "instance_sg" {
  type        = string
  default     = ""
  description = "Bastion Host SG"
}


