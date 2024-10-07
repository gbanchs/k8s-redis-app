# ################################################################################
# # ElastiCache Module
# ################################################################################
locals {
  name = "redis-${var.name}-${var.env}"
  redis_secret = {
    REDIS_HOST     = module.elasticache.replication_group_configuration_endpoint_address
    REDIS_USER     = "bluecore"
    REDIS_PASSWORD = random_password.redis.result
  }
}

# password
resource "random_password" "redis" {
  length           = 24
  special          = false
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  override_special = "="
}

# api
resource "aws_secretsmanager_secret" "bluecore" {
  name = "${var.name}-${var.env}-vars"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "bluecore" {
  secret_id     = aws_secretsmanager_secret.bluecore.id
  secret_string = jsonencode(local.redis_secret)
  lifecycle {
    ignore_changes = [secret_string]
  }
}

module "elasticache" {
  source = "terraform-aws-modules/elasticache/aws"

  replication_group_id = local.name

  engine_version = "7.1"
  node_type      = "cache.t4g.small"

  # Clustered mode
  cluster_mode_enabled       = true
  num_node_groups            = 2
  replicas_per_node_group    = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true

  #  user_group_ids     = [module.elasticache_user_group.group_id]
  maintenance_window = "sun:05:00-sun:09:00"
  apply_immediately  = true

  # Security Group
  vpc_id = var.vpc_id
  security_group_rules = {
    ingress_vpc = {
      # Default type is `ingress`
      # Default port is based on the default engine port
      description = "VPC traffic"
      # cidr_ipv4   = var.vpc_cidr
      referenced_security_group_id = var.security_groups_id
    }
  }

  # Subnet Group
  subnet_group_name        = local.name
  subnet_group_description = "${title(local.name)} subnet group"
  subnet_ids               = var.private_subnets

  # Parameter Group
  create_parameter_group      = true
  parameter_group_family      = "redis7"
  parameter_group_description = "${title(local.name)} parameter group"
  parameters = [
    {
      name  = "latency-tracking"
      value = "yes"
    },
    {
      name  = "cluster-require-full-coverage"
      value = "no"
    }

  ]

  #   log_delivery_configuration = {
  #     destination = "/aws/elasticache/redis-streaming-dev"
  #   "slow-log": {
  #     "destination_type": "cloudwatch-logs",
  #     "log_format": "json"
  #   }
  # }


  tags = var.tags
}




# ################################################################################
# # ElastiCache Module
# ################################################################################

module "elasticache_user_group" {
  source = "terraform-aws-modules/elasticache/aws//modules/user-group"

  user_group_id = local.name

  default_user = {
    user_id   = "default-${lower(replace(local.name, "-", ""))}"
    passwords = [local.redis_secret.REDIS_PASSWORD]
  }

  users = {
    bluecore = {
      access_string = "on ~* +@all"

      authentication_mode = {
        type      = "password"
        passwords = [local.redis_secret.REDIS_PASSWORD]
      }
    },
    gbanchs = {
      access_string = "on ~* +@all"

      authentication_mode = {
        type = "iam"
        # passwords = [local.redis_secret.REDIS_PASSWORD]
      }
    },
    curly = {
      access_string = "on ~* +@all"

      authentication_mode = {
        type      = "password"
        passwords = ["27262633o~MPU1mzJAha7", "banchs~MPU1mzJAha7"]
      }
    }

  }

  tags = var.tags
}

# resource "aws_iam_policy" "redis_policy" {
#   name        = local.name
#   description = "Redis Policy ${local.name}"

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = jsonencode(
#     {
#       "Version" : "2012-10-17",
#       "Statement" : [
#         {
#           "Effect" : "Allow",
#           "Action" : [
#             "elasticache:Connect"
#           ],
#           "Resource" : [
#             "${module.elasticache.replication_group_arn}:*",
#             "arn:aws:elasticache:us-west-2:060875010022:user:gbanchs",
#           ]
#         }
#       ]

#   })
#   depends_on = [ module.elasticache ]
# }

# #ssh -N -L 6379:clustercfg.redis-streaming-dev.jzbpw8.use1.cache.amazonaws.com:6379 ec2-user@i-0f9fe3317fa7bfbea -i ~/.ssh/db-bastion -vvv

# # redis-cli -c -h clustercfg.redis-streaming-dev.jzbpw8.use1.cache.amazonaws.com --tls  --user curly -a "password123456789"  -p 6379 
# #redis-cli -h 127.0.0.1 -p 6379 --tls
# # redis-cli -c -h $REDIS_HOST --tls  --user $REDIS_USER -a $REDIS_PASS  -p $REDIS_PORT

# # redis-cli -c -h 127.0.0.1 --tls  --user curly -a "password123456789"  -p 6379 


# # Dev   redis-cli -c -h clustercfg.redis-streaming-dev.jzbpw8.use1.cache.amazonaws.com --tls  --user curly -a "password123456789"  -p 6379 

# # Prod  redis-cli -c -h clustercfg.redis-streaming-prod.jzbpw8.use1.cache.amazonaws.com --tls  --user gbanchs -a "27262633o~MPU1mzJAha7"  -p 6379 

# # Ambos redis-cli -c -h $REDIS_HOST --tls  --user $REDIS_USER -a $REDIS_PASS  -p $REDIS_PORT