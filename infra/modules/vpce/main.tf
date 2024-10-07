resource "aws_security_group" "endpoint-sg" {
  name        = "endpoint_access-${var.env}"
  description = "allow inbound traffic"
  vpc_id      = var.vpc_id

  # ingress {
  #   from_port       = 0
  #   to_port         = 0
  #   protocol        = "-1"
  #   security_groups = [aws_security_group.bastion[0].id]
  #   description     = "Enable access for the endpoints."
  # }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Enable access for the endpoints."
  }

  # ingress {
  #   from_port   = 3306
  #   to_port     = 3306
  #   protocol    = "tcp"
  #  # cidr_blocks = ["0.0.0.0/0"]
  #  security_groups = [aws_security_group.rds.id]
  #   description = "Enable access for the endpoints."
  # }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Enable access for the endpoints."
  }

  # egress {
  #   from_port   = 3306
  #   to_port     = 3306
  #   protocol    = "tcp"
  #  # cidr_blocks = ["0.0.0.0/0"]
  #  security_groups = [aws_security_group.rds.id]
  #   description = "Enable access for the endpoints."
  # }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Enable access for the endpoints."
  }
  tags = {
    "Name" = var.name
    "env"  = var.env
    "App"  = "endpoint-sg"
  }
}


module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = var.vpc_id
  security_group_ids = [aws_security_group.endpoint-sg.id]

  endpoints = {
    s3 = {
      # interface endpoint
      service = "s3"
      tags    = { Name = "s3-vpc-endpoint-${var.env}" }
    },
    ssmmessages = {
      service            = "ssmmessages"
      vpc_endpoint_type  = "Interface"
      subnet_ids         = var.private_subnets
      security_group_ids = [aws_security_group.endpoint-sg.id]
      # private_dns_enabled = true
      tags = merge(var.tags, {
        "Name" = "ssmmessages-${var.env}"
        "env"  = var.env
        "App"  = "ssmmessages-${var.env}"
      })
    },
    ec2messages = {
      service            = "ec2messages"
      vpc_endpoint_type  = "Interface"
      subnet_ids         = var.private_subnets
      security_group_ids = [aws_security_group.endpoint-sg.id]
      # private_dns_enabled = true


      tags = merge(var.tags, {
        "Name" = "ec2messages-${var.env}"
        "env"  = var.env
        "App"  = "ec2messages-${var.env}"
      })
    },
    ssm = {
      service            = "ssm"
      vpc_endpoint_type  = "Interface"
      subnet_ids         = var.private_subnets
      security_group_ids = [aws_security_group.endpoint-sg.id]
      # private_dns_enabled = true


      tags = merge(var.tags, {
        "Name" = "endpoint-sg-${var.env}"
        "env"  = var.env
        "App"  = "endpoint-sg-${var.env}"
      })
    }

    # dynamodb = {
    #   # gateway endpoint
    #   service         = "dynamodb"
    #   route_table_ids = ["rt-12322456", "rt-43433343", "rt-11223344"]
    #   tags            = { Name = "dynamodb-vpc-endpoint-${var.env}" }
    # },
    # sns = {
    #   service    = "sns"
    #   subnet_ids = ["subnet-12345678", "subnet-87654321"]
    #   tags       = { Name = "sns-vpc-endpoint-${var.env}" }
    # },
    # sqs = {
    #   service             = "sqs"
    #   # private_dns_enabled = true
    #   security_group_ids  = ["sg-987654321"]
    #   subnet_ids          = ["subnet-12345678", "subnet-87654321"]
    #   tags                = { Name = "sqs-vpc-endpoint-${var.env}" }
    # },
  }




  #tags = var.tags
}