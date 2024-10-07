# VARIABLES
variable "env" {
  description = "AWS Environment"
  type        = string
  default     = "demo"
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "name" {
  description = "Resource name"
  type        = string
  default     = "demo"
}

variable "tags" {
  default = {
    Environment = "demo"
    Provisioner = "Terraform"
    Application = "demo"
  }
}
