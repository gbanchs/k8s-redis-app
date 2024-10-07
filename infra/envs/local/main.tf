locals {
  env         = var.env
  bucket_name = "tf-bluecore-state-${var.env}"

}

# https://github.com/terraform-aws-modules/terraform-aws-s3-bucket/blob/v3.2.0/examples/complete/main.tf
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  bucket = local.bucket_name
  acl    = "private" # "acl" conflicts with "grant" and "owner"

  versioning = {
    enabled    = true
    status     = true
    mfa_delete = false
  }

  force_destroy = true
  #acceleration_status = "Suspended"
  #request_payer       = "BucketOwner"

  tags = var.tags



  # Bucket policies
  attach_policy = true
  # policy                                = aws_s3_bucket_policy.bucket_policy
  #data.aws_iam_policy_document.bucket_policy.json
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # S3 Bucket Ownership Controls
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"
  expected_bucket_owner    = data.aws_caller_identity.current.account_id
}


resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks" # The name of your DynamoDB table
  billing_mode = "PAY_PER_REQUEST" # On-demand billing; you can also use PROVISIONED
  hash_key     = "LockID"          # Primary key (hash key)

  attribute {
    name = "LockID" # Name of the primary key attribute
    type = "S"      # Attribute type (S = String)
  }

  tags = {
    Name        = "Terraform Lock Table"
    Environment = "production" # Optional: Adjust based on your environment
  }
}


# module "sso_permissions" {
#   source = "../../modules/sso_permissions"
#   name   = "gbanchs"
#   env    = var.env
#   tags   = var.tags
#   #region = "us-east-1"
# }
