
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
  default = {
    Environment = "development"
    Provisioner = "Terraform"
    Application = "mvp"
  }
}

variable "private_subnets" {
  type = list(any)

}


variable "instance_sg" {
  type        = string
  default     = ""
  description = "Bastion Host SG"
}

variable "vpce_sg" {
  type        = string
  default     = ""
  description = "VPCE SG"
}


variable "user_data" {
  default = ""
  type    = string

}

variable "aws_image_id" {
  default = ""
  type    = string
}