output "region" {
  value = var.region
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}


output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_managed_node_groups" {
  value = module.eks.eks_managed_node_groups
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "eks" {
  value = module.eks
}


# output "vpce-sg-ssm" {
#   value = module.vpce-ec2-ssm.vpce-sg-ssm
# }

# output "security_group_id" {
#   value = module.vpc_endpoints[0].security_group_id
# }

# output "vpce-ec2-sg" {
#   value = module.vpce-ec2-ssm[0].vpce-sg-ec2
# }