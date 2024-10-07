#https://github.com/aws-ia/terraform-aws-eks-ack-addons/blob/main/examples/complete/main.tf
#https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/blob/main/main.tf
#https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/blob/main/tests/complete/main.tf#L173
data "aws_region" "current" {}
data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

data "aws_eks_cluster" "cluster" {
  depends_on = [module.eks]
  name       = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  depends_on = [module.eks]
  name       = module.eks.cluster_name
}

# provider "kubectl" {
#   apply_retry_count      = 10
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#   load_config_file       = false
#   token                  = data.aws_eks_cluster_auth.cluster.token
# }

data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

resource "null_resource" "update_kubeconfig" {
  #provider = helm.my_cluster
  provisioner "local-exec" {
    command = "aws eks --region ${data.aws_region.current.name} update-kubeconfig --name ${data.aws_eks_cluster.cluster.name}"
  }
  # depends_on = [module.eks]
}

locals {
  bucket_name_velero = "velero-${var.cluster_name}"
  partition          = data.aws_partition.current.partition
  account_id         = data.aws_caller_identity.current.account_id
  domain_list = [
    "${var.env}.${var.domain_name}",
    "${var.domain_name}"
  ]
  #  node_id = split(":", module.eks_managed_node_group.node_group_id)
}



################################################################################
# Module S3 Bucket for Velero
################################################################################


resource "aws_iam_role" "velero_bucket" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.velero_bucket.arn]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name_velero}",
    ]
  }
}

module "velero_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"
  bucket  = local.bucket_name_velero

  force_destroy = true
  # Bucket policies
  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.bucket_policy.json
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
}


################################################################################
# Sub-Module Usage on Existing/Separate Cluster
################################################################################
resource "aws_security_group" "web" {
  name        = "web-${var.name}-${var.env}"
  description = "Allow Web inbound traffic"
  vpc_id      = var.vpc_config.vpc_id

  ingress {
    description      = "Web from Internet"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "web-${var.name}-${var.env}",
    Environment = var.env
  }
}


module "eks_managed_node_group" {
  source                            = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  name                              = "separate-eks-mng"
  cluster_name                      = module.eks.cluster_name
  cluster_ip_family                 = module.eks.cluster_ip_family
  cluster_service_cidr              = module.eks.cluster_service_cidr
  create                            = false
  subnet_ids                        = var.vpc_config.subnet_ids
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids = [
    module.eks.node_security_group_id,
  ]

  ami_type = "BOTTLEROCKET_x86_64"
  platform = "bottlerocket"

  # this will get added to what AWS provides
  bootstrap_extra_args = <<-EOT
    # extra args added
    [settings.kernel]
    lockdown = "integrity"

    [settings.kubernetes.node-labels]
    "label1" = "foo"
    "label2" = "bar"
  EOT

  tags = merge(var.tags, { Separate = "eks-managed-node-group" })
  # depends_on = [module.eks]
}

module "disabled_eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  create = false
}

# ################################################################################
# # Supporting Resources
# ################################################################################
resource "aws_iam_service_linked_role" "autoscaling" {
  custom_suffix    = var.cluster_name
  aws_service_name = "autoscaling.amazonaws.com"
}

module "ebs_kms_key" {

  source  = "terraform-aws-modules/kms/aws"
  version = "~> 2.1"

  description = "Customer managed key to encrypt EKS managed node group volumes"

  # Policy
  key_administrators = [
    data.aws_caller_identity.current.arn
  ]

  key_service_roles_for_autoscaling = [
    # required for the ASG to manage encrypted volumes for nodes
    aws_iam_service_linked_role.autoscaling.arn,
    # required for the cluster / persistentvolume-controller to create encrypted PVCs
    module.eks.cluster_iam_role_arn,
  ]

  # Aliases
  aliases = ["eks/${var.cluster_name}/ebs"]

  tags = var.tags
}



resource "aws_iam_policy" "node_additional" {
  name        = "${var.cluster_name}-additional-${var.env}"
  description = "Node additional policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = var.tags
}

resource "time_sleep" "wait_20_seconds_after_eks_blueprints" {
  # depends_on = [
  #   module.eks.managed_node_groups
  # ]
  create_duration = "20s"
}

## https://github.com/aws-ia/terraform-aws-eks-blueprints-addons?tab=readme-ov-file#modules
## Helm configs for Helm addons
## https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/blob/main/main.tf
## https://medium.com/@fayas_akram/scale-eks-like-a-boss-heres-how-to-save-70-with-karpenter-8ab5318543d8
module "eks_blueprints_addons" {
  #count   = var.eks_blueprints_addons ? 1 : 0
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.2"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  #create_delay_dependencies = [for prof in module.eks_managed_node_group.node_group_arn : prof.node_group_arn] #[module.eks_managed_node_group.node_group_arn] #

  enable_aws_load_balancer_controller = true

  aws_load_balancer_controller = {
    wait_for_jobs    = true
    wait             = true
    cleanup_on_fail  = true
    replace          = true
    disable_webhooks = false
    set = [{
      name  = "enableServiceMutatorWebhook"
      value = "false"
    }]
  }

  enable_metrics_server = true
  metrics_server = {
    wait_for_jobs   = true
    wait            = true
    replace         = true
    cleanup_on_fail = true
  }
  enable_ingress_nginx = true
  ingress_nginx = {
    wait_for_jobs   = true
    wait            = true
    replace         = true
    cleanup_on_fail = true
  }

  enable_velero = true
  velero = {
    name        = "velero-${var.env}"
    role_name   = "velero-role-${var.env}"
    create_role = true

    s3_backup_location = "${module.velero_bucket.s3_bucket_arn}/backups"
    values = [
      # https://github.com/vmware-tanzu/helm-charts/issues/550#issuecomment-1959933230
      <<-EOT
        kubectl:
          image:
            tag: 1.29.2-debian-11-r5
      EOT
    ]

    service_account_name = "sa-${var.env}-velero"
    #chart_version    = "6.0.0" 
    wait_for_jobs    = true
    wait             = true
    force_update     = true
    pass_credentials = true
    recreate_pods    = true
    # repository_username = data.aws_ecrpublic_authorization_token.token.user_name
    # repository_password = data.aws_ecrpublic_authorization_token.token.password

    set = [
      {
        name  = "credentials.useSecret"
        value = true
      },
      {
        name  = "configuration.backupStorageLocation.config.region"
        value = var.region

      },
      {
        name  = "configuration.volumeSnapshotLocation.config.region"
        value = var.region

      }
    ]
  }
  enable_cluster_autoscaler           = true
  enable_aws_node_termination_handler = false ### Only activate if you are going to use self managed Nodes

  # https://github.com/external-secrets/kubernetes-external-secrets
  enable_external_secrets = true
  # https://aws-quickstart.github.io/cdk-eks-blueprints/addons/aws-node-termination-handler/#aws-node-termination-handler
  aws_node_termination_handler = {
    create_role          = true
    wait_for_jobs        = true
    wait                 = true
    role_name_use_prefix = false
  }

  enable_cluster_proportional_autoscaler = false
  # https://github.com/kubernetes-sigs/cluster-proportional-autoscaler/blob/master/charts/cluster-proportional-autoscaler/values.yaml
  cluster_proportional_autoscaler = {
    values = [
      <<-EOT
          replicas: 2
          options:
            target: deployment/*
          config: 
          #  ladder:
          #    coresToReplicas:
          #      - [ 1, 1 ]
          #      - [ 64, 3 ]
          #      - [ 512, 5 ]
          #      - [ 1024, 7 ]
          #      - [ 2048, 10 ]
          #      - [ 4096, 15 ]
          #    nodesToReplicas:
          #      - [ 1, 1 ]
          #      - [ 2, 2 ]
            linear:
              coresPerReplica: 2
              nodesPerReplica: 1
              min: 1
              max: 100
              preventSinglePointFailure: true
              includeUnschedulableNodes: true            
        EOT
    ]
  }
  #   <<-EOT
  #   options:
  #     target: "deployment"            
  # EOT
  enable_karpenter             = var.enable_karpenter
  enable_kube_prometheus_stack = true #var.enable_kube_prometheus_stack
  # Pass in any number of Helm charts to be created for those that are not natively supported
  helm_releases = var.helm_releases


  enable_vpa          = false
  enable_external_dns = false
  enable_cert_manager = false
  #cert_manager_route53_hosted_zone_arns = [data.aws_route53_zone.selected.zone_id]

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      configuration_values = jsonencode({
        sidecars : {
          snapshotter : {
            forceEnable : false
          }
        }
      })
    }

    # aws-efs-csi-driver = {
    #   create                   = false
    #   most_recent              = true
    #   service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    # }


  }

  enable_aws_for_fluentbit = false

  aws_for_fluentbit = {
    set = [
      {
        name  = "cloudWatchLogs.region"
        value = var.region
      }
    ]
  }


  karpenter = {
    repository_username = data.aws_ecrpublic_authorization_token.token.user_name
    repository_password = data.aws_ecrpublic_authorization_token.token.password
  }

  karpenter_enable_spot_termination          = true
  karpenter_enable_instance_profile_creation = true
  karpenter_node = {
    iam_role_use_name_prefix = false
  }

  tags = var.tags
}

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.37.1"

  role_name_prefix = "${var.env}-ebs-csi-driver-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

resource "aws_iam_role_policy" "pipeline_policy" {
  name = "pipeline-policy-${var.env}"
  role = aws_iam_role.eks_pipeline_role.name # Reference the role name or ID


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow EKS actions for deploying and authenticating
      {
        Action = [
          "eks:DescribeCluster",
          "eks:CreateCluster",
          "eks:UpdateClusterConfig",
          "eks:UpdateNodegroupConfig",
          "eks:UpdateClusterVersion",
          "eks:ListClusters",
          "eks:ListNodegroups",
          "eks:ListUpdates",
          "eks:DescribeNodegroup",
          "eks:DescribeUpdate"
        ]
        Effect   = "Allow"
        Resource = "*"
      },

      # Allow EC2 actions for interacting with EC2 instances, EBS, networking
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:DescribeVpcs",
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces"
        ]
        Effect   = "Allow"
        Resource = "*"
      },

      # Allow S3 actions to upload and retrieve objects (if S3 is used)
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${local.bucket_name_velero}",
          "arn:aws:s3:::${local.bucket_name_velero}/*"
        ]
      },

      # Allow KMS actions for encrypting and decrypting data
      {
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Effect   = "Allow"
        Resource = "*"
      },

      # Allow access to Secrets Manager to get secrets
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Effect   = "Allow"
        Resource = "*"
      },

      # Allow access to Systems Manager Parameter Store (if used for storing parameters)
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory",
          "ssm:DescribeParameters"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}



resource "aws_iam_role" "eks_pipeline_role" {
  name = "pipeline-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = {
    Name = "access-role-${var.env}"
  }
}

# resource "aws_iam_role" "eks_pipeline_role" {
#   name = "pipeline-role-${var.env}"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Sid    = ""
#         Principal = {
#           Service = "ec2.amazonaws.com"
#           AWS     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         }
#       }
#     ]
#   })

#   # Inline policies to allow necessary actions
#   inline_policy {
#     name = "pipeline-policy-${var.env}"

#     policy = jsonencode({
#       Version = "2012-10-17"
#       Statement = [
#         # Allow EKS actions for deploying and authenticating
#         {
#           Action   = [
#             "eks:DescribeCluster",
#             "eks:CreateCluster",
#             "eks:UpdateClusterConfig",
#             "eks:UpdateNodegroupConfig",
#             "eks:UpdateClusterVersion",
#             "eks:ListClusters",
#             "eks:ListNodegroups",
#             "eks:ListUpdates",
#             "eks:DescribeNodegroup",
#             "eks:DescribeUpdate"
#           ]
#           Effect   = "Allow"
#           Resource = "*"
#         },

#         # Allow EC2 actions for interacting with EC2 instances, EBS, networking
#         {
#           Action = [
#             "ec2:DescribeInstances",
#             "ec2:DescribeVolumes",
#             "ec2:AttachVolume",
#             "ec2:DetachVolume",
#             "ec2:CreateVolume",
#             "ec2:DeleteVolume",
#             "ec2:CreateSecurityGroup",
#             "ec2:AuthorizeSecurityGroupIngress",
#             "ec2:DescribeVpcs",
#             "ec2:CreateVpc",
#             "ec2:DeleteVpc",
#             "ec2:ModifyVpcAttribute",
#             "ec2:DescribeSubnets",
#             "ec2:DescribeSecurityGroups",
#             "ec2:DescribeNetworkInterfaces"
#           ]
#           Effect   = "Allow"
#           Resource = "*"
#         },

#         # Allow S3 actions to upload and retrieve objects (if S3 is used)
#         # {
#         #   Action   = [
#         #     "s3:PutObject",
#         #     "s3:GetObject",
#         #     "s3:ListBucket"
#         #   ]
#         #   Effect   = "Allow"
#         #   Resource = [
#         #     "arn:aws:s3:::${var.s3_bucket_name}",
#         #     "arn:aws:s3:::${var.s3_bucket_name}/*"
#         #   ]
#         # },

#         # Allow KMS actions for encrypting and decrypting data
#         {
#           Action   = [
#             "kms:Encrypt",
#             "kms:Decrypt",
#             "kms:GenerateDataKey",
#             "kms:DescribeKey"
#           ]
#           Effect   = "Allow"
#           Resource = "*"
#         },

#         # Allow access to Secrets Manager to get secrets
#         {
#           Action   = [
#             "secretsmanager:GetSecretValue",
#             "secretsmanager:DescribeSecret",
#             "secretsmanager:ListSecrets"
#           ]
#           Effect   = "Allow"
#           Resource = "*"
#         },

#         # Allow access to Systems Manager Parameter Store (if used for storing parameters)
#         {
#           Action   = [
#             "ssm:GetParameter",
#             "ssm:GetParameters",
#             "ssm:GetParameterHistory",
#             "ssm:DescribeParameters"
#           ]
#           Effect   = "Allow"
#           Resource = "*"
#         }
#       ]
#     })
#   }

#   tags = {
#     Name = "access-role-${var.env}"
#   }
# }



################################################################################
# EKS Module
################################################################################
module "eks" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "~> 20.0"
  authentication_mode            = "API" #"API_AND_CONFIG_MAP"
  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true
  vpc_id                         = var.vpc_config.vpc_id
  subnet_ids                     = var.vpc_config.subnet_ids
  control_plane_subnet_ids       = var.intra_subnets
  create_cloudwatch_log_group    = false

  # IPV6
  # cluster_ip_family          = "ipv6"
  # create_cni_ipv6_iam_policy = true
  enable_cluster_creator_admin_permissions = true

  # Enable EFA support by adding necessary security group rules
  # to the shared node security group
  enable_efa_support = true
  enable_irsa        = true
  cluster_addons = {
    coredns = {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
      resolve_conflicts_on_create = "OVERWRITE"
      preserve                    = true #this is the default value
      #addon_version               = local.eks_managed_add_on_versions.coredns

      timeouts = {
        create = "10m"
        delete = "5m"
      }
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  node_security_group_id = var.nodes_sg_id
  eks_managed_node_group_defaults = {
    instance_types = var.managed_nodes_types #["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
    #   # Security group
    vpc_security_group_ids = [var.nodes_sg_id]
    ami_type               = "AL2023_x86_64_STANDARD"
    #     block_device_mappings = {
    #   xvda = {
    #     device_name = "/dev/xvda"
    #     ebs = {
    #       volume_size = 100
    #       volume_type = "gp3"
    #      # iops        = 3000
    #      # throughput            = 150
    #       encrypted             = true
    #       kms_key_id            = module.ebs_kms_key.key_arn
    #       delete_on_termination = true
    #     }
    #   }
    # }
    disk_size               = 50
    pre_bootstrap_user_data = <<-EOT
      echo 'DevOps- Because Developers Need Heroes'
      EOT
    #force_update_version = true

    labels = {
      Environment = var.env
    }
    ebs_optimized           = true
    disable_api_termination = false
    enable_monitoring       = false
    iam_role_additional_policies = {
      AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      AmazonEBSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }
  }

  eks_managed_node_groups = {
    "nodes-${var.name}-${var.env}" = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      min_size     = var.min_size_default
      max_size     = var.max_size_default
      desired_size = var.desired_size_default
      #var.min_size_default
      capacity_type = "ON_DEMAND"
    }
    "nodes-spot-${var.env}" = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups

      # disk_size    = 50
      min_size     = var.min_size_default
      max_size     = var.max_size_default
      desired_size = var.desired_size_default
      #var.min_size_default

      capacity_type        = "SPOT"
      force_update_version = true
      instance_types       = var.managed_nodes_types #["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
      labels = {
        Environment = var.env
      }
      ebs_optimized           = true
      disable_api_termination = false
      enable_monitoring       = false
      # block_device_mappings = {
      #   xvda = {
      #     device_name = "/dev/xvda"
      #     ebs = {
      #       volume_size = 30
      #       volume_type = "gp3"
      #       iops        = 100
      #       # throughput            = 150
      #       encrypted = false
      #       #kms_key_id            = module.ebs_kms_key.key_arn
      #       delete_on_termination = true
      #     }
      #   }
      # }

      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        AmazonEBSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }

      taints = {
        # This Taint aims to keep just EKS Addons and Karpenter running on this MNG
        # The pods that do not tolerate this taint should run on nodes created by Karpenter
        # addons = {
        #   key    = "CriticalAddonsOnly"
        #   value  = "true"
        #   effect = "NO_SCHEDULE"
        # },
      }
    }
  }

  access_entries = {

    # One access entry with a policy associated
    pipeline = {
      kubernetes_groups = []
      principal_arn     = aws_iam_role.eks_pipeline_role.arn

      policy_associations = {
        bitbucket = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            namespaces = [] #"default","monitoring"
            type       = "cluster"
          }
        }
      }
    }
  }

  # access_entries = {
  #   # One access entry with a policy associated
  #   "ex-simple-${var.cluster_name}" = {
  #     kubernetes_groups = []
  #     principal_arn     = aws_iam_role.this["single-${var.cluster_name}"].arn

  #     policy_associations = {
  #       single = {
  #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  #         access_scope = {
  #           namespaces = ["default"]
  #           type       = "namespace"
  #         }
  #       }
  #     }
  #   }

  #   # Example of adding multiple policies to a single access entry
  #   "ex-multiple-${var.cluster_name}" = {
  #     kubernetes_groups = []
  #     principal_arn     = aws_iam_role.this["multiple-${var.cluster_name}"].arn

  #     policy_associations = {
  #       "ex-one-${var.cluster_name}" = {
  #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
  #         access_scope = {
  #           namespaces = ["default"]
  #           type       = "namespace"
  #         }
  #       }
  #       "ex-two-${var.cluster_name}" = {
  #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  #         access_scope = {
  #           type = "cluster"
  #         }
  #       }
  #     }
  #   }
  # }

  tags = merge(var.tags, {
    "karpenter.sh/discovery"                        = var.cluster_name
    "k8s.io/cluster-autoscaler/enabled"             = true
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = true
    "kubernetes.io/cluster/${var.cluster_name}"     = "owned"
  })
}



resource "kubectl_manifest" "karpenter_node_class" {
  count     = var.enable_karpenter ? 1 : 0
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2
      role: ${module.eks_blueprints_addons[0].karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      tags:
        karpenter.sh/discovery: ${var.cluster_name}
  YAML

  depends_on = [
    module.eks, module.eks_blueprints_addons
  ]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  count     = 0
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["c", "m", "r"]
            - key: "karpenter.k8s.aws/instance-cpu"
              operator: In
              values: ["4", "8", "16", "32"]
            - key: "karpenter.k8s.aws/instance-hypervisor"
              operator: In
              values: ["nitro"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["2"]
      limits:
        cpu: 1000
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
  YAML

  # depends_on = [
  #   kubectl_manifest.karpenter_node_class
  # ]
}

module "disabled_self_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/self-managed-node-group"

  create = false

  # Hard requirement
  cluster_service_cidr = ""
}

module "disabled_eks" {
  source = "terraform-aws-modules/eks/aws"
  create = false
}


# resource "kubernetes_ingress_v1" "nodesource_ingress" {
#   count = 0
#   #provider = kubernetes.aws
#   # depends_on = [
#   #   module.eks
#   # ]
#   metadata {
#     name      = "ingress-${var.name}-${var.env}"
#     namespace = "default"
#     annotations = {
#       #"alb.ingress.kubernetes.io/healthcheck-path"     = "/login"
#       "alb.ingress.kubernetes.io/load-balancer-name"       = "ingress-${var.name}-${var.env}"
#       "alb.ingress.kubernetes.io/name"                     = "ingress-${var.name}-${var.env}"
#       "alb.ingress.kubernetes.io/scheme"                   = "internet-facing"
#       "alb.ingress.kubernetes.io/target-type"              = "instance"
#       "alb.ingress.kubernetes.io/certificate-arn"          = module.acm[0].arn
#       "alb.ingress.kubernetes.io/listen-ports"             = "[{\"HTTPS\": 443}]"
#       "alb.ingress.kubernetes.io/actions.ssl-redirect"     = "{\"Type\":\"redirect\",\"RedirectConfig\": {\"Protocol\":\"HTTPS\",\"Port\":443,\"StatusCode\":\"HTTP_301\"}}"
#       "alb.ingress.kubernetes.io/ssl-redirect"             = "443"
#       "alb.ingress.kubernetes.io/load-balancer-attributes" = "routing.http.drop_invalid_header_fields.enabled=true"
#       # "alb.ingress.kubernetes.io/subnets"              = tostring(var.vpc_config.vpc_subnets_ids)
#       # "service.beta.kubernetes.io/aws-load-balancer-type" = 
#       "alb.ingress.kubernetes.io/security-groups" = aws_security_group.web.id
#     }
#   }

#   spec {
#     ingress_class_name = "alb"
#     rule {
#       host = "${var.env}.${var.domain_name}"
#       http {

#         path {
#           backend {
#             service {
#               name = "app-test"
#               port {
#                 number = 80
#               }

#             }
#           }
#           path      = "/"
#           path_type = "Prefix"
#         }
#       }
#     }

#   }
# }

module "acm" {
  source                    = "../acm"
  name                      = var.env
  env                       = var.env
  tags                      = var.tags
  zone_id                   = data.aws_route53_zone.selected.zone_id
  domain_name               = var.domain_name
  subject_alternative_names = local.domain_list
}

module "acm_virginia" {
  providers = {
    aws = aws.virginia
  }

  source                    = "../acm"
  name                      = var.env
  env                       = var.env
  tags                      = var.tags
  zone_id                   = data.aws_route53_zone.selected.zone_id
  domain_name               = var.domain_name
  subject_alternative_names = local.domain_list
}



resource "kubernetes_service_account" "backend" {
  metadata {
    name = "sa-${var.name}-${var.env}"

    annotations = {
      "eks.amazonaws.com/role-arn" = "${aws_iam_role.app_role.arn}"
    }
  }
  automount_service_account_token = true
}

resource "aws_iam_policy" "sa_policy" {
  name        = "apps-service-accout-policy-${var.env}"
  description = "Service Account Policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListObjectsV2",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "s3:PutBucketTagging",
          "s3:GetBucketTagging",
          "s3:PutObjectTagging",
          "s3:GetObjectTagging",
          "s3:DeleteObjectTagging"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
      {
        "Sid" : "sesMail",
        "Action" : [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        Effect   = "Allow"
        Resource = ["*"]
      },
    ]



  })

}


resource "aws_iam_role" "app_role" {
  name = "sa-${var.name}-${var.env}"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = "appSA${var.env}"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.eks.oidc_provider}"
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:aud" : "sts.amazonaws.com",
            "${module.eks.oidc_provider}:sub" : "system:serviceaccount:default:sa-${var.name}-${var.env}"
          }
        }

      },
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "attach_sa_policy" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.sa_policy.arn
}


