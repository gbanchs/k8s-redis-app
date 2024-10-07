## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_elasticache"></a> [elasticache](#module\_elasticache) | terraform-aws-modules/elasticache/aws | n/a |
| <a name="module_elasticache_user_group"></a> [elasticache\_user\_group](#module\_elasticache\_user\_group) | terraform-aws-modules/elasticache/aws//modules/user-group | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.bluecore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.bluecore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [random_password.redis](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region | `string` | `"us-east-1"` | no |
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | n/a | `number` | `2` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | n/a | `any` | `2` | no |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | n/a | `string` | `"10.12.0.0/16"` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | n/a | `string` | `"v3.goliiive.com"` | no |
| <a name="input_env"></a> [env](#input\_env) | Environment | `string` | `"sandbox"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key for Encrypt & Decrypt | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | goliiive-core-v3 | `string` | `"goliiive"` | no |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | n/a | `string` | `"cache.t4g.small"` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | n/a | `list(string)` | `[]` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | n/a | `list(string)` | `[]` | no |
| <a name="input_security_groups_id"></a> [security\_groups\_id](#input\_security\_groups\_id) | Nodes Access to Redis | `string` | `""` | no |
| <a name="input_subdomain"></a> [subdomain](#input\_subdomain) | n/a | `string` | `"sandbox"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Resource Tags | `map(string)` | <pre>{<br/>  "Name": "goliiive"<br/>}</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | n/a | `string` | `"10.12.0.0/16"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | `""` | no |

## Outputs

No outputs.
