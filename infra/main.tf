

# Define the data source to get information about the VPC
data "aws_vpc" "selected" {
  #  count = 0
  id = module.vpc.vpc_id
}
################################################################################
# Local Vars and Parameters
# ##############################################################################
locals {
  name        = var.name
  env         = var.env
  bucket_name = "ctx-version-${var.env}"

  azs             = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  user_data       = <<-EOT
    #!/bin/bash
    echo "Hello Terraform!"
  EOT
  tags            = var.tags
  repository_name = "ctx-images-${var.env}"
  vpc_cidr_eks    = "10.100.0.0/16"

}


################################################################################
# Policies
# ##############################################################################
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = local.bucket_name
  policy = jsonencode(
    {
      Statement = [
        {
          Action = "s3:*"
          Condition = {
            NumericLessThan = {
              "s3:TlsVersion" = "1.2"
            }
          }
          Effect    = "Deny"
          Principal = "*"
          Resource = [
            "arn:aws:s3:::${local.bucket_name}/*",
            "arn:aws:s3:::${local.bucket_name}",
          ]
          Sid = "denyOutdatedTLS"
        },
        {
          Action = "s3:*"
          Condition = {
            Bool = {
              "aws:SecureTransport" = "false"
            }
          }
          Effect    = "Deny"
          Principal = "*"
          Resource = [
            "arn:aws:s3:::${local.bucket_name}/*",
            "arn:aws:s3:::${local.bucket_name}",
          ]
          Sid = "denyInsecureTransport"
        },
      ]
      Version = "2012-10-17"
    }
  )
}

################################################################################
# S3 Module
# ##############################################################################
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  bucket = local.bucket_name
  acl    = "private" # "acl" conflicts with "grant" and "owner"

  versioning = {
    enabled    = true
    status     = true
    mfa_delete = false
  }

  force_destroy = false
  #acceleration_status = "Suspended"
  #request_payer       = "BucketOwner"

  tags = var.tags
  # Bucket policies
  attach_policy                         = true
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



data "aws_subnets" "backend" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "random_password" "master" {
  length  = 20
  special = false
}



module "kms" {
  source = "terraform-aws-modules/kms/aws"

  deletion_window_in_days = 7
  description             = "Primary key of replica key example"
  enable_key_rotation     = false
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  multi_region            = false

  aliases = ["primary-standard-rds-${var.env}"]
  # Policy
  enable_default_policy = true
  key_owners            = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  # key_administrators                     = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/info@gbanchs.com"]
  # key_users                              = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/info@gbanchs.com"]
  # key_service_users                      = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/info@gbanchs.com"]
  # key_symmetric_encryption_users         = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/info@gbanchs.com"]
  # key_hmac_users                         = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/info@gbanchs.com"]
  # key_asymmetric_public_encryption_users = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/info@gbanchs.com"]
  #key_asymmetric_sign_verify_users       = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/info@gbanchs.comsign-verify-user"]
  tags = local.tags
}

resource "aws_security_group" "nodes" {
  name        = "nodes-custom-${var.env}"
  description = "Allow Nodes inbound traffic"
  vpc_id      = var.vpc_id != "" ? var.vpc_id : module.vpc.vpc_id
  ingress {
    description      = ""
    from_port        = 443
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 443
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "nodes-${var.name}-${var.env}",
    Environment = var.env
  }
}


################################################################################
# EKS Cluster
# ##############################################################################
module "eks" {
  source = "./modules/eks/"
  providers = {
    kubectl    = kubectl.main
    helm       = helm.main
    kubernetes = kubernetes.main
    aws        = aws
  }

  name                 = var.name
  env                  = var.env
  region               = var.region
  cluster_name         = "eks-${var.name}-${var.env}"
  cluster_version      = var.cluster_version
  domain_name          = var.domain_name
  kms_key              = module.kms.key_arn
  max_size_default     = var.max_size_default
  min_size_default     = var.min_size_default
  desired_size_default = var.desired_size_default
  azs                  = local.azs
  nodes_sg_id          = aws_security_group.nodes.id
  managed_nodes_types  = var.managed_nodes_types
  vpc_config = {
    vpc_id     = module.vpc.vpc_id
    subnet_ids = module.vpc.private_subnets
  }

  intra_subnets                = module.vpc.intra_subnets
  helm_releases                = var.helm_releases
  enable_karpenter             = var.enable_karpenter
  enable_kube_prometheus_stack = var.enable_kube_prometheus_stack
  config_path                  = var.config_path
  # db_write_host                = var.db_config.db_host_write != "" ? var.db_config.db_host_write : module.rds-aurora[0].db_write_host

}

################################################################################
# Redis Cluster Cache
################################################################################
module "redis" {
  #count              = var.creation_config.create_redis ? 1 : 0
  source             = "/Users/gbanchs/projects/bluecore/infra/modules/redis-cluster"
  name               = var.name
  env                = var.env
  tags               = var.tags
  vpc_id             = module.vpc.vpc_id
  private_subnets    = module.vpc.private_subnets
  vpc_cidr           = var.vpc_cidr
  kms_key_id         = module.kms.key_arn
  security_groups_id = aws_security_group.redis[0].id
  #azs                  = local.azs
}

################################################################################
# VPC Module
################################################################################
module "vpc" {
  source           = "terraform-aws-modules/vpc/aws"
  version          = "5.8.1"
  create_vpc       = var.creation_config.create_vpc
  name             = "vpc-${var.name}-${var.env}"
  cidr             = var.vpc_cidr
  azs              = local.azs
  private_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  public_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 4)]
  database_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 8)]
  #elasticache_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 12)]
  #redshift_subnets    = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 16)]
  intra_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 20)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  create_database_subnet_group  = false
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  public_subnet_tags = {
    "Name"                   = "public-subnet-${var.name}-${var.env}",
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "Name"                            = "private-subnet-${var.name}-${var.env}",
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = "eks-${var.name}-${var.env}"
  }

  intra_subnet_tags = {
    "Name"                            = "intra-subnet-${var.name}-${var.env}",
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = "eks-${var.name}-${var.env}"
  }

  enable_network_address_usage_metrics = false
}


resource "aws_security_group" "redis" {
  count       = var.creation_config.create_redis ? 1 : 0
  name        = "Redis-${var.name}-${var.env}"
  description = "Allow Redis inbound access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Redis from Nodes & RDS"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.nodes.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "redis-${var.name}-${var.env}",
    Environment = var.env
  }
}

################################################################################
module "ecr" {
  for_each = var.ecr_repositories
  source   = "terraform-aws-modules/ecr/aws"

  repository_name = each.value.name

  repository_read_write_access_arns = each.value.repository_read_write_arns

  repository_lifecycle_policy = jsonencode({
    rules = each.value.lifecycle_policy.rules
  })
  tags = merge({
    Terraform   = "true"
    Environment = var.env
  }, var.tags)
}


resource "aws_security_group" "bastion" {
  count       = var.vpc_id != "" ? 0 : 1
  name        = "bastion-${var.name}-${var.env}"
  description = "Allow Bastion Access"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Enable access to bastion SSM."
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Enable access to bastion SSM."
  }

  #  ingress {
  #     from_port       = 443
  #     to_port         = 443
  #     protocol        = "tcp"
  #     #cidr_blocks      = [var.vpc_cidr]
  #     security_groups = [module.vpc_endpoints[0].security_group_id]
  #     description     = "Enable access to bastion SSM."
  #   }


  # egress {
  #   from_port = 80
  #   to_port   = 80
  #   protocol  = "tcp"
  #   # security_groups = [aws_security_group..id]
  #   cidr_blocks = ["0.0.0.0/0"]
  #   description = "Enable access to the internet."
  # }

  # egress {
  #   from_port       = 5432
  #   to_port         = 5432
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.postgresql.id]
  #   description     = "RDS PostgreSQL access ${var.env}"
  # }

  # egress {
  #   from_port       = 3306
  #   to_port         = 3306
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.rds.id]
  #   description     = "RDS MySql access ${var.env}"
  # }

  tags = {
    Name        = "bastion-${var.name}-${var.env}",
    Environment = var.env
  }
  #depends_on = [ module.vpc_endpoints, module.vpc] 
}


# data "aws_security_group" "nodes_sq" {
#   #count  = var.vpc_id != "" ? 1 : 0
#   vpc_id = var.vpc_id != "" ? var.vpc_id : module.vpc.vpc_id
#   tags = {
#     Name = "nodes-${var.main_project.parent_name}-${var.main_project.parent_env}"
#   }
# }

# data "aws_security_group" "vpce_sq" {
#   #ount = var.vpc_id != "" ? 1 : 0
#   vpc_id = var.vpc_id != "" ? var.vpc_id : module.vpc.vpc_id
#   tags = {
#     Name = "${var.main_project.parent_name}"
#     App  = "endpoint-sg"
#   }
# }

data "aws_security_group" "bastion" {
  count  = var.vpc_id != "" && var.creation_config.create_bastion ? 1 : 0
  vpc_id = var.vpc_id != "" ? var.vpc_id : module.vpc.vpc_id
  tags = {
    Name = "bastion-${var.name}-${var.env}"
  }
}


################################################################################
# EC2 Module
# ################################################################################
module "vpc_endpoints" {
  count           = var.creation_config.create_vpc_endpoints ? 1 : 0
  source          = "./modules/vpce"
  name            = var.name
  vpc_id          = var.vpc_id != "" ? var.vpc_id : module.vpc.vpc_id
  vpc_cidr        = var.vpc_cidr
  env             = var.env
  private_subnets = [module.vpc.private_subnets[0]]
  tags            = var.tags
  # region =        = var.region
  #security_groups_id = aws_security_group.nodes.id   
}
################################################################################
# EC2 Module
# ################################################################################
module "vpce-ec2-ssm" {
  count           = var.creation_config.create_bastion ? 1 : 0
  source          = "./modules/vpce-ec2-ssm"
  name            = "${var.name}-${var.env}"
  env             = var.env
  tags            = var.tags
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = var.vpc_cidr
  private_subnets = module.vpc.private_subnets
  instance_sg     = aws_security_group.bastion[0].id
  vpce_sg         = "" #module.vpc_endpoints[0].security_group_id
  user_data       = file("${path.root}/user_data.sh")
  aws_image_id    = data.aws_ami.ubuntu.id #ami-0bbc0801b3da5b7ae"
  # depends_on = [module.vpc,module.vpc_endpoints]
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical's AWS account ID
}


