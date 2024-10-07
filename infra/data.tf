data "aws_caller_identity" "current" {
  provider = aws
}
data "aws_availability_zones" "available" {}
data "aws_canonical_user_id" "current" {}


# data "aws_route53_zone" "selected" {
#   name         = var.domain_name
#   private_zone = false
# }

