# VARIABLES
variable "env" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "name" {
  description = "Resource name"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Resource Tags"
  type        = map(string)
}

variable "domain_name" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "subject_alternative_names" {
  type = list(any)
}
