## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.69 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.9.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.20.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.69 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecr"></a> [ecr](#module\_ecr) | terraform-aws-modules/ecr/aws | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | ./modules/eks/ | n/a |
| <a name="module_kms"></a> [kms](#module\_kms) | terraform-aws-modules/kms/aws | n/a |
| <a name="module_redis"></a> [redis](#module\_redis) | /Users/gbanchs/projects/bluecore/infra/modules/redis-cluster | n/a |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.8.1 |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | ./modules/vpce | n/a |
| <a name="module_vpce-ec2-ssm"></a> [vpce-ec2-ssm](#module\_vpce-ec2-ssm) | ./modules/vpce-ec2-ssm | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket_policy.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_security_group.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.redis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [random_password.master](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_canonical_user_id.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/canonical_user_id) | data source |
| [aws_security_group.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_subnets.backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_AWS_ROLE_EXTERNAL_ID"></a> [AWS\_ROLE\_EXTERNAL\_ID](#input\_AWS\_ROLE\_EXTERNAL\_ID) | External ID for assuming AWS role | `string` | `""` | no |
| <a name="input_AWS_ROLE_TO_ASSUME"></a> [AWS\_ROLE\_TO\_ASSUME](#input\_AWS\_ROLE\_TO\_ASSUME) | AWS role to assume for resource provisioning | `string` | `""` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of availability zones to use | `list(string)` | `[]` | no |
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | Number of availability zones to use | `number` | `2` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Version of the EKS cluster | `string` | `"1.31"` | no |
| <a name="input_config_path"></a> [config\_path](#input\_config\_path) | Path to the kubeconfig file | `string` | `"~/.kube/config"` | no |
| <a name="input_creation_config"></a> [creation\_config](#input\_creation\_config) | Map of creation configurations | `any` | `{}` | no |
| <a name="input_db_config"></a> [db\_config](#input\_db\_config) | Map of RDS instance configurations | `any` | `{}` | no |
| <a name="input_desired_size_default"></a> [desired\_size\_default](#input\_desired\_size\_default) | Desired number of nodes for the default Node Group | `number` | `2` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for the cluster | `string` | `""` | no |
| <a name="input_ecr_repositories"></a> [ecr\_repositories](#input\_ecr\_repositories) | Map of configurations for each ECR repository | <pre>map(object({<br/>    name                       = string<br/>    lifecycle_policy           = map(any)<br/>    repository_read_write_arns = list(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_enable_karpenter"></a> [enable\_karpenter](#input\_enable\_karpenter) | Whether to enable karpenter Autoscaling (configurations are required) | `bool` | `false` | no |
| <a name="input_enable_kube_prometheus_stack"></a> [enable\_kube\_prometheus\_stack](#input\_enable\_kube\_prometheus\_stack) | Whether to enable the kube-prometheus-stack | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | AWS Environment | `string` | n/a | yes |
| <a name="input_helm_releases"></a> [helm\_releases](#input\_helm\_releases) | Map of configurations for each Helm release | `map` | `{}` | no |
| <a name="input_manage_aws_auth_configmap"></a> [manage\_aws\_auth\_configmap](#input\_manage\_aws\_auth\_configmap) | Whether to manage the AWS auth ConfigMap | `bool` | `true` | no |
| <a name="input_managed_nodes_types"></a> [managed\_nodes\_types](#input\_managed\_nodes\_types) | List of EC2 instance types for managed nodes | `list(string)` | <pre>[<br/>  "t2.small",<br/>  "t3.medium"<br/>]</pre> | no |
| <a name="input_max_size_default"></a> [max\_size\_default](#input\_max\_size\_default) | Maximum number of nodes for the default Node Group | `number` | `3` | no |
| <a name="input_min_size_default"></a> [min\_size\_default](#input\_min\_size\_default) | Minimum number of nodes for the default Node Group | `number` | `1` | no |
| <a name="input_name"></a> [name](#input\_name) | Resource name | `string` | `"bluecore"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | `"us-west-2"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for the resources | `map` | <pre>{<br/>  "Application": "bluecore",<br/>  "Environment": "demo",<br/>  "Provisioner": "Terraform"<br/>}</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | n/a |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | n/a |
| <a name="output_eks"></a> [eks](#output\_eks) | n/a |
| <a name="output_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#output\_eks\_managed\_node\_groups) | n/a |
| <a name="output_region"></a> [region](#output\_region) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
